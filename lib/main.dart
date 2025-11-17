import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'utils/logger.dart';
import 'utils/ui_helpers.dart';
import 'screens/display_picture_screen.dart';
import 'screens/pdf_viewer_screen.dart';
import 'digital_signature_page.dart';

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
    try {
      _log.info('Starting PDF download');
      
      // Load PDF from assets
      final ByteData data = await rootBundle.load('assets/pdfs/MINA 1 (1).pdf');
      
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
      
      // Create file with sanitized name
      final String fileName = 'MINA_1.pdf';
      final File file = File('${downloadsDir.path}/$fileName');
      
      // Write PDF to file
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
      
      _log.info('PDF downloaded to: ${file.path}');
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF downloaded to:\n${file.path}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e, st) {
      _log.severe('Failed to download PDF', e, st);
      
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
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const DigitalSignaturePage(),
                    ),
                  );
                },
                icon: Icons.edit,
                label: 'Digital Signature',
                backgroundColor: Colors.purple,
              ),
              const SizedBox(height: standardSpacing),
              
              // Preview PDF button
              createIconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const PdfViewerScreen(
                        assetPath: 'assets/pdfs/MINA 1 (1).pdf',
                        title: 'PDF Preview',
                      ),
                    ),
                  );
                },
                icon: Icons.picture_as_pdf,
                label: 'Preview PDF',
                backgroundColor: Colors.orange,
              ),
              const SizedBox(height: standardSpacing),
              
              // Download PDF button
              createIconButton(
                onPressed: _downloadPdf,
                icon: Icons.download,
                label: 'Download PDF',
                backgroundColor: Colors.teal,
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
