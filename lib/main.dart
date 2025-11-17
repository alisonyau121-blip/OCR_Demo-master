import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'utils/logger.dart';
import 'utils/ui_helpers.dart';
import 'screens/display_picture_screen.dart';
import 'screens/pdf_viewer_screen.dart';
import 'screens/user_input_form_screen.dart';
import 'screens/form_confirmation_screen.dart';
import 'digital_signature_page.dart';
import 'models/signature_result.dart';
import 'services/pdf_api_service.dart';

Future<void> main() async {
  // Setup logging infrastructure
  setupLogging();
  
  final log = getLogger('Main');
  
  // Global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    log.severe('Flutter error', details.exception, details.stack);
  };
  
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    log.info('Application starting...');
    
    runApp(
      MaterialApp(
        title: 'ID OCR Demo',
        theme: ThemeData.dark(),
        debugShowCheckedModeBanner: false,
        home: const SelectImageScreen(),
      ),
    );
  } catch (e, stackTrace) {
    log.severe('Startup failed', e, stackTrace);
    
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Failed to start application'),
                const SizedBox(height: 8),
                Text(e.toString()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Home screen for selecting image source (camera, gallery, or digital signature)
class SelectImageScreen extends StatefulWidget {
  const SelectImageScreen({super.key});

  @override
  State<SelectImageScreen> createState() => _SelectImageScreenState();
}

class _SelectImageScreenState extends State<SelectImageScreen> {
  static final _log = Logger('SelectImageScreen');
  final ImagePicker _picker = ImagePicker();
  final PdfApiService _pdfService = PdfApiService();
  
  // Signature tracking
  SignatureResult? clientSignature;
  SignatureResult? adviserSignature;
  
  // PDF generation state
  bool _generatingPdf = false;
  Uint8List? signedPdfBytes;
  
  // Form data tracking
  Map<String, String>? userFormData;

  Future<void> _pickImage(ImageSource source) async {
    try {
      _log.info('Selecting image source: $source');
      
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      
      if (image == null) {
        _log.fine('User cancelled image selection');
        return;
      }
      
      _log.info('Image selected: ${image.path}');
      
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => DisplayPictureScreen(imagePath: image.path),
        ),
      );
    } catch (e, st) {
      _log.severe('Failed to select image', e, st);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select image: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _downloadPdf() async {
    // Only download signed PDF (button is disabled if no signed version exists)
    if (signedPdfBytes == null) {
      _log.warning('Download attempted without signed PDF');
      return;
    }
    
    try {
      _log.info('Starting signed PDF download');
      
      // Use signed PDF from memory
      final pdfBytes = signedPdfBytes!;
      const fileName = 'MINA_1_signed.pdf';
      
      // Get downloads directory
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          downloadsDir = await getExternalStorageDirectory();
        }
      } else {
        downloadsDir = await getApplicationDocumentsDirectory();
      }
      
      if (downloadsDir == null) {
        throw Exception('Could not access downloads directory');
      }
      
      // Create file
      final File file = File('${downloadsDir.path}/$fileName');
      
      // Write PDF to file
      await file.writeAsBytes(pdfBytes, flush: true);
      
      _log.info('Signed PDF downloaded to: ${file.path}');
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Signed PDF downloaded to:\n${file.path}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e, st) {
      _log.severe('Failed to download signed PDF', e, st);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download PDF: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _showRoleSelectionDialog() async {
    final role = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Signer Role'),
        content: const Text('Who is signing this document?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'Client'),
            child: const Text(
              'Client',
              style: TextStyle(fontSize: 18),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'Adviser'),
            child: const Text(
              'Adviser',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );

    if (role != null && mounted) {
      _log.info('Role selected: $role');
      final result = await Navigator.of(context).push<SignatureResult>(
        MaterialPageRoute(
          builder: (context) => DigitalSignaturePage(role: role),
        ),
      );
      
      // Handle the returned signature result
      if (result != null && mounted) {
        _handleSignatureResult(result);
      }
    }
  }
  
  void _handleSignatureResult(SignatureResult result) {
    _log.info('Received signature for role: ${result.role}');
    
    setState(() {
      if (result.role == 'Client') {
        clientSignature = result;
      } else if (result.role == 'Adviser') {
        adviserSignature = result;
      }
    });
    
    // Check completion status
    _checkSignatureCompletion(result.role);
  }
  
  void _checkSignatureCompletion(String justSignedRole) {
    if (justSignedRole == 'Client') {
      if (adviserSignature != null) {
        // Both have signed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Both Client and Adviser have signed!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        // Only client signed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Client signature saved. Adviser has not signed yet.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else if (justSignedRole == 'Adviser') {
      if (clientSignature != null) {
        // Both have signed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Both Client and Adviser have signed!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        // Only adviser signed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Adviser signature saved. Client has not signed yet.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  bool _canGeneratePdf() {
    return clientSignature != null && 
           adviserSignature != null && 
           !_generatingPdf;
  }

  void _handleGeneratePdf() {
    _generateSignedPdf();
  }

  void _handlePreviewPdf() {
    if (signedPdfBytes == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PdfViewerScreen(
          pdfBytes: signedPdfBytes,
          title: 'Signed PDF Preview',
        ),
      ),
    );
  }

  void _handleDownloadPdf() {
    if (signedPdfBytes == null) return;
    _downloadPdf();
  }

  Future<void> _handleUserInputForm() async {
    _log.info('Opening user input form');
    
    final formData = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(
        builder: (context) => const UserInputFormScreen(),
      ),
    );
    
    if (formData != null && mounted) {
      _log.info('Form data received: $formData');
      
      setState(() {
        userFormData = formData;
      });
      
      // Navigate to confirmation screen
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FormConfirmationScreen(formData: formData),
          ),
        );
      }
    }
  }

  Future<void> _generateSignedPdf() async {
    if (clientSignature == null || adviserSignature == null) {
      _log.warning('Attempted to generate PDF without both signatures');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Both signatures are required to generate PDF'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _log.info('Starting PDF generation with both signatures');
    setState(() => _generatingPdf = true);

    try {
      // Insert signatures into PDF
      var pdfBytes = await _pdfService.insertSignaturesToPdf(
        clientSignaturePng: clientSignature!.transparentPng,
        adviserSignaturePng: adviserSignature!.transparentPng,
      );

      // Insert form data if available
      if (userFormData != null) {
        _log.info('Inserting user form data into PDF');
        pdfBytes = await _pdfService.insertFormDataToPdf(
          pdfBytes: pdfBytes,
          designation: userFormData!['Designation'] ?? '',
          companyName: userFormData!['CompanyName'] ?? '',
          adviserName: userFormData!['AdviserName'] ?? '',
        );
      }

      // Store signed PDF in memory
      setState(() {
        signedPdfBytes = pdfBytes;
      });

      // Save PDF to device
      final filePath = await _pdfService.savePdfToDevice(pdfBytes);

      if (!mounted) return;

      // Show success message
      final hasFormData = userFormData != null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hasFormData
                ? '✓ Signed PDF with form data saved to:\n$filePath\n\nPreview & Download now use signed version'
                : '✓ Signed PDF saved to:\n$filePath\n\nPreview & Download now use signed version'
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } catch (e, st) {
      _log.severe('Failed to generate signed PDF', e, st);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate PDF: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _generatingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ID OCR Demo'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: standardScreenPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              
              // App title and description
              const Icon(
                Icons.document_scanner,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              const Text(
                'ID OCR Recognition',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Scan Hong Kong ID, China ID, or Passport',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              // Camera button
              createIconButton(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: Icons.camera_alt,
                label: 'Capture Document',
                backgroundColor: Colors.blue,
              ),
              const SizedBox(height: standardSpacing),
              
              // Gallery button
              createIconButton(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: Icons.photo_library,
                label: 'Choose from Gallery',
                backgroundColor: Colors.green,
              ),
              const SizedBox(height: standardSpacing),
              
              // Digital signature button
              createIconButton(
                onPressed: _showRoleSelectionDialog,
                icon: Icons.edit,
                label: 'Digital Signature',
                backgroundColor: Colors.purple,
              ),
              const SizedBox(height: standardSpacing),
              
              // Preview PDF button (only works with signed version)
              ElevatedButton.icon(
                onPressed: signedPdfBytes != null ? _handlePreviewPdf : null,
                icon: Icon(
                  Icons.picture_as_pdf,
                  size: 32,
                ),
                label: Text(
                  signedPdfBytes != null ? 'Preview Signed PDF' : 'Preview PDF (Need Signed)',
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: signedPdfBytes != null ? Colors.orange : Colors.grey,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
              const SizedBox(height: standardSpacing),
              
              // Download PDF button (only works with signed version)
              ElevatedButton.icon(
                onPressed: signedPdfBytes != null ? _handleDownloadPdf : null,
                icon: Icon(
                  Icons.download,
                  size: 32,
                ),
                label: Text(
                  signedPdfBytes != null ? 'Download Signed PDF' : 'Download PDF (Need Signed)',
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: signedPdfBytes != null ? Colors.teal : Colors.grey,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
              const SizedBox(height: standardSpacing),
              
              // Generate Signed PDF button
              ElevatedButton.icon(
                onPressed: _canGeneratePdf() ? _handleGeneratePdf : null,
                icon: Icon(
                  _generatingPdf
                      ? Icons.hourglass_empty
                      : Icons.picture_as_pdf,
                  size: 32,
                ),
                label: Text(
                  _generatingPdf
                      ? 'Generating...'
                      : (clientSignature != null && adviserSignature != null)
                          ? 'Generate Signed PDF'
                          : 'Need both signatures',
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: (clientSignature != null && adviserSignature != null)
                      ? Colors.indigo
                      : Colors.grey,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
              const SizedBox(height: standardSpacing),
              
              // User Input Form button
              ElevatedButton.icon(
                onPressed: _handleUserInputForm,
                icon: Icon(
                  userFormData != null ? Icons.check_circle : Icons.assignment,
                  size: 32,
                ),
                label: Text(
                  userFormData != null ? 'User Form Submitted ✓' : 'User Input Form',
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: userFormData != null ? Colors.green : Colors.amber,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
              const SizedBox(height: 24), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }
  
  // Web platform detection helper (returns false on Android/iOS)
  bool _isWeb() => false;
}
