import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:id_ocr_kit/id_ocr_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:signature/signature.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/pdf_field_inspector.dart';
import 'form_fill_page.dart';

class IdOcrFullFeaturePage extends StatefulWidget {
  const IdOcrFullFeaturePage({super.key});

  @override
  State<IdOcrFullFeaturePage> createState() => _IdOcrFullFeaturePageState();
}

class _IdOcrFullFeaturePageState extends State<IdOcrFullFeaturePage> {
  static final _log = Logger('IdOcrFullFeaturePage');
  
  IdRecognitionResult? _result;
  bool _isProcessing = false;
  String? _digitalSignature;
  SignatureResult? _signatureData; // Store actual signature data from id_ocr_kit
  File? _generatedPdf;
  File? _signedPdf;
  File? _capturedImage; // Store the captured image for display
  bool _showRawText = false; // Toggle for raw text visibility
  String _selectedPdfToInspect = 'MINA (3).pdf'; // Selected PDF for field inspection
  
  // Store form data from FormFillPage
  Map<String, String>? _savedFormData;

  // Services from id_ocr_kit
  late final IdRecognitionService _idService;
  late final PdfFormService _pdfFormService;

  @override
  void initState() {
    super.initState();
    // Initialize id_ocr_kit services
    _idService = IdRecognitionService(
      ocrProvider: MlKitOcrAdapter(),
    );
    _pdfFormService = PdfFormService(
      pdfProvider: SyncfusionPdfAdapter(),
    );
  }

  @override
  void dispose() {
    _idService.dispose();
    super.dispose();
  }

  // Capture Document from Camera
  Future<void> _captureDocument() async {
    await _scanDocument(ImageSource.camera);
  }

  // Choose from Gallery
  Future<void> _chooseFromGallery() async {
    await _scanDocument(ImageSource.gallery);
  }

  // Request storage permission for saving to Downloads
  Future<bool> _requestStoragePermission() async {
    if (!Platform.isAndroid) {
      return true; // No permission needed for other platforms
    }

    // For Android 13+ (API 33+), we don't need WRITE_EXTERNAL_STORAGE for Downloads
    if (Platform.isAndroid) {
      final androidVersion = await _getAndroidVersion();
      if (androidVersion >= 33) {
        // Android 13+ doesn't need storage permission for Downloads
        return true;
      }
    }

    // For Android 11-12, check if we already have permission
    var status = await Permission.storage.status;
    if (status.isGranted) {
      return true;
    }

    // Request permission
    status = await Permission.storage.request();
    if (status.isGranted) {
      return true;
    }

    // Show error if permission denied
    if (status.isPermanentlyDenied) {
      _showErrorSnackBar(
        'Storage permission is required to save PDFs.\n'
        'Please enable it in app settings.',
      );
      await openAppSettings();
    } else {
      _showWarningSnackBar('Storage permission denied. PDF will be saved to app folder.');
    }

    return false;
  }

  // Get Android SDK version
  Future<int> _getAndroidVersion() async {
    if (!Platform.isAndroid) return 0;
    // For simplicity, we'll assume Android 10+ which is common for emulators
    // In production, you'd use device_info_plus package to get exact version
    return 33; // Assume Android 13+ for modern emulators
  }

  // Main scan function using id_ocr_kit
  Future<void> _scanDocument(ImageSource source) async {
    try {
      setState(() => _isProcessing = true);

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 100,
      );

      if (image == null) {
        setState(() => _isProcessing = false);
        return;
      }

      final imageFile = File(image.path);

      // Use id_ocr_kit to recognize ID
      final result = await _idService.recognizeId(imageFile);

      setState(() {
        _result = result;
        _capturedImage = imageFile; // Store the captured image
        _isProcessing = false;
        // Auto-expand raw text when document is successfully recognized
        _showRawText = (result.isSuccess && result.hasIds);
        // Reset PDF states when new scan
        _digitalSignature = null;
        _generatedPdf = null;
        _signedPdf = null;
      });

      if (result.isSuccess && result.hasIds) {
        _showSuccessSnackBar('Document recognized successfully! Check scan results below.');
      } else {
        _showWarningSnackBar('No ID found in the image');
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showErrorSnackBar('Error: $e');
    }
  }

  // Digital Signature - Real implementation using id_ocr_kit
  Future<void> _applyDigitalSignature() async {
    try {
      setState(() => _isProcessing = true);

      // 1. Create signature controller
      final signatureController = SignatureController(
        penStrokeWidth: 3,
        penColor: Colors.black,
        exportBackgroundColor: Colors.white,
      );

      // 2. Show signature capture dialog
      final signed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.draw, color: Colors.purple),
              const SizedBox(width: 8),
              const Text('Draw Your Signature'),
            ],
          ),
          content: Container(
            width: 400,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Signature(
                    controller: signatureController,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign here with your finger or stylus',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                signatureController.clear();
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear'),
            ),
            TextButton(
              onPressed: () {
                signatureController.dispose();
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (signatureController.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Please draw your signature first')),
                  );
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.check),
              label: const Text('Apply'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );

      if (signed != true) {
        signatureController.dispose();
        setState(() => _isProcessing = false);
        return;
      }

      // 3. Convert signature to PNG bytes
      final signatureBytes = await signatureController.toPngBytes();
      signatureController.dispose();
      
      if (signatureBytes == null) {
        throw Exception('Failed to capture signature image');
      }

      // 4. Create SignatureResult using id_ocr_kit model
      final timestamp = DateTime.now();
      final signatureResult = SignatureResult(
        previewPng: signatureBytes,
        transparentPng: signatureBytes, // For MVP, same as preview
        timestamp: timestamp,
        role: 'Client', // Could be made selectable (Client/Adviser)
      );

      setState(() {
        _signatureData = signatureResult;
        _digitalSignature = signatureResult.defaultFilename;
        _isProcessing = false;
      });

      _showSuccessSnackBar(
        'Digital signature captured!\n'
        'Role: ${signatureResult.role}\n'
        'Time: ${signatureResult.timestamp.toString().substring(0, 19)}'
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      _showErrorSnackBar('Signature failed: $e');
    }
  }

  // Preview Signed PDF - Real implementation
  Future<void> _previewSignedPdf() async {
    if (_generatedPdf == null) {
      _showInfoDialog(
        'No PDF Available',
        'Please generate a PDF first by:\n\n1. Capture or choose a document\n2. Click "Generate Signed PDF"',
      );
      return;
    }

    try {
      setState(() => _isProcessing = true);

      // Open the generated PDF
      await OpenFile.open(_generatedPdf!.path);

      setState(() => _isProcessing = false);
      _showSuccessSnackBar('Opening PDF...');
    } catch (e) {
      setState(() => _isProcessing = false);
      _showErrorSnackBar('Preview failed: $e');
    }
  }

  // Download Signed PDF - Real implementation
  Future<void> _downloadSignedPdf() async {
    if (_signedPdf == null && _generatedPdf == null) {
      _showInfoDialog(
        'No PDF to Download',
        'Please follow these steps:\n\n1. Capture a document\n2. Apply digital signature (optional)\n3. Generate signed PDF\n\nThen try downloading again.',
      );
      return;
    }

    try {
      setState(() => _isProcessing = true);

      // PDF is already saved, just show the path
      await Future.delayed(const Duration(milliseconds: 500));
      
      final pdfPath = _signedPdf?.path ?? _generatedPdf?.path ?? '';

      setState(() => _isProcessing = false);
      _showSuccessSnackBar('PDF saved to:\n$pdfPath');
    } catch (e) {
      setState(() => _isProcessing = false);
      _showErrorSnackBar('Download failed: $e');
    }
  }

  // Generate Signed PDF - Insert signature and form data into MINA PDF template
  Future<void> _generateSignedPdf() async {
    try {
      setState(() => _isProcessing = true);

      // Step 0: Request storage permission for saving to Downloads
      final hasPermission = await _requestStoragePermission();
      
      // Step 1: Load MINA PDF template from assets (with ClientSign field)
      final ByteData data = await rootBundle.load('assets/pdfs/MINA (3).pdf');
      final pdfBytes = data.buffer.asUint8List();
      
      // Step 2: Create Syncfusion PDF adapter
      final pdfAdapter = SyncfusionPdfAdapter();
      
      // Step 3: Load PDF document
      final pdfDoc = await pdfAdapter.loadPdf(pdfBytes);
      
      // Step 4: Fill form fields if form data exists
      if (_savedFormData != null && _savedFormData!.isNotEmpty) {
        _log.info('Filling PDF with saved form data...');
        int filledCount = 0;
        
        for (final entry in _savedFormData!.entries) {
          if (entry.value.isNotEmpty) {
            try {
              await pdfAdapter.fillTextField(
                document: pdfDoc,
                fieldName: entry.key,
                value: entry.value,
              );
              filledCount++;
              _log.fine('Filled field: ${entry.key} = ${entry.value}');
            } catch (e) {
              _log.warning('Field "${entry.key}" not found or failed: $e');
            }
          }
        }
        
        _log.info('Successfully filled $filledCount fields');
      }
      
      // Step 5: Insert signature at ClientSign field
      if (_signatureData != null) {
        try {
          // MINA (3).pdf has ClientSign form field placeholder
          await pdfAdapter.insertSignatureAtFormField(
            document: pdfDoc,
            fieldName: 'ClientSign',
            signatureBytes: _signatureData!.transparentPng,
          );
          
          _log.info('Signature successfully inserted at ClientSign field');
          
        } catch (e) {
          _log.severe('Failed to insert signature at ClientSign field', e);
          _showWarningSnackBar('簽名插入失敗，但表單數據已填充');
        }
      }
      
      // Step 6: Save PDF
      final finalPdfBytes = await pdfAdapter.savePdf(pdfDoc);
      
      // Step 7: Dispose PDF document
      await pdfAdapter.dispose(pdfDoc);
      
      // Step 8: Save to device Downloads folder (easier to access from Windows)
      Directory? saveDir;
      String locationMsg = '';
      
      if (Platform.isAndroid && hasPermission) {
        // Try to save to Downloads folder
        saveDir = Directory('/storage/emulated/0/Download');
        if (!await saveDir.exists()) {
          // Create the directory if it doesn't exist
          try {
            await saveDir.create(recursive: true);
            locationMsg = '📂 Saved to Downloads folder';
          } catch (e) {
            // Fallback to external storage directory
            saveDir = await getExternalStorageDirectory();
            locationMsg = '📂 Saved to app storage';
          }
        } else {
          locationMsg = '📂 Saved to Downloads folder';
        }
      } else {
        // For iOS or if no permission, use app's directory
        saveDir = await getTemporaryDirectory();
        locationMsg = '📂 Saved to app storage';
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final pdfFile = File('${saveDir!.path}/complete_mina_$timestamp.pdf');
      await pdfFile.writeAsBytes(finalPdfBytes);

      setState(() {
        _generatedPdf = pdfFile;
        _signedPdf = pdfFile; // Mark as signed if either form data or signature exists
        _isProcessing = false;
      });

      // Build success message
      String message = 'MINA PDF 生成成功！\n';
      if (_savedFormData != null) {
        message += '✅ 表單信息已填充\n';
      }
      if (_signatureData != null) {
        message += '✅ 客戶簽名已插入\n';
      }
      message += '\n$locationMsg\n';
      message += 'Filename: complete_mina_$timestamp.pdf';
      
      _showSuccessSnackBar(message);

    } catch (e) {
      setState(() => _isProcessing = false);
      _showErrorSnackBar('PDF generation failed: $e');
    }
  }

  // Navigate to Form Fill Page and receive form data
  Future<void> _openFormFillPage() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (context) => FormFillPage(
          existingFormData: _savedFormData,
          existingSignature: _signatureData,
        ),
      ),
    );
    
    // If form was submitted, save the data
    if (result != null) {
      setState(() {
        _savedFormData = result;
      });
      _showSuccessSnackBar('表單信息已保存！\n點擊 "Generate Signed PDF" 生成完整的PDF');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        title: const Text('ID OCR Demo'),
        elevation: 0,
        actions: [
          if (_generatedPdf != null)
            IconButton(
              icon: const Icon(Icons.folder),
              onPressed: () {
                _showInfoDialog(
                  'Generated Files',
                  'PDF: ${_generatedPdf?.path ?? 'None'}\n\n'
                  'Signed PDF: ${_signedPdf?.path ?? 'None'}',
                );
              },
              tooltip: 'View saved files',
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Icon and Title
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.document_scanner,
                    size: 60,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'ID OCR Recognition',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Scan Hong Kong ID, China ID, or Passport',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // Instruction hint
                if (_result == null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange, width: 1),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '👆 Please scan a document first to enable other features',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),

                // Capture Document Button (Blue)
                _buildFeatureButton(
                  label: 'Capture Document',
                  icon: Icons.camera_alt,
                  color: Colors.blue,
                  onPressed: _captureDocument,
                ),
                const SizedBox(height: 12),

                // Choose from Gallery Button (Green)
                _buildFeatureButton(
                  label: 'Choose from Gallery',
                  icon: Icons.photo_library,
                  color: Colors.green,
                  onPressed: _chooseFromGallery,
                ),
                const SizedBox(height: 12),

                // DEBUG: PDF Selector and Inspect Button
                Card(
                  color: Colors.grey[850],
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.bug_report, color: Colors.grey, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'PDF Inspector (Debug)',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedPdfToInspect,
                          decoration: InputDecoration(
                            labelText: 'Select PDF to Inspect',
                            labelStyle: const TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.blue),
                            ),
                            filled: true,
                            fillColor: Colors.grey[800],
                          ),
                          dropdownColor: Colors.grey[800],
                          style: const TextStyle(color: Colors.white),
                          items: const [
                            DropdownMenuItem(
                              value: 'MINA (3).pdf',
                              child: Text('MINA PDF'),
                            ),
                            DropdownMenuItem(
                              value: 'CA 3.pdf',
                              child: Text('CA3 PDF'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedPdfToInspect = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              // Get detailed field information
                              final details = await PdfFieldInspector.getFormFieldDetails(
                                'assets/pdfs/$_selectedPdfToInspect',
                              );
                              
                              // Build formatted output with position info
                              final buffer = StringBuffer();
                              buffer.writeln('Found ${details.length} fields:\n');
                              
                              // Group by page
                              final pageGroups = <int, List<Map<String, dynamic>>>{};
                              for (final field in details) {
                                final page = field['page'] as int;
                                pageGroups.putIfAbsent(page, () => []).add(field);
                              }
                              
                              // Sort by page and position
                              for (final page in pageGroups.keys.toList()..sort()) {
                                buffer.writeln('📄 PAGE $page:');
                                
                                // Sort by top position (top to bottom)
                                final pageFields = pageGroups[page]!;
                                pageFields.sort((a, b) => (a['top'] as int).compareTo(b['top'] as int));
                                
                                for (final field in pageFields) {
                                  buffer.writeln('  ${field['index']}. ${field['name']}');
                                  buffer.writeln('     Position: (${field['left']}, ${field['top']})');
                                }
                                buffer.writeln();
                              }
                              
                              buffer.writeln('💡 Check console for complete details with coordinates!');
                              
                              _showInfoDialog(
                                'PDF Form Fields - $_selectedPdfToInspect',
                                buffer.toString(),
                              );
                            },
                            icon: const Icon(Icons.search),
                            label: const Text('Inspect Form Fields'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Digital Signature Button (Purple)
                _buildFeatureButton(
                  label: _digitalSignature != null
                      ? 'Digital Signature ✓'
                      : 'Digital Signature',
                  icon: _digitalSignature != null ? Icons.verified : Icons.edit,
                  color: _digitalSignature != null ? Colors.deepPurple : Colors.purple,
                  onPressed: _applyDigitalSignature,
                  enabled: true,
                ),
                const SizedBox(height: 12),

                // Preview Signed PDF Button (Orange)
                _buildFeatureButton(
                  label: 'Preview Signed PDF',
                  icon: Icons.picture_as_pdf,
                  color: Colors.orange,
                  onPressed: _previewSignedPdf,
                  enabled: true,
                ),
                const SizedBox(height: 12),

                // Download Signed PDF Button (Teal)
                _buildFeatureButton(
                  label: 'Download Signed PDF',
                  icon: Icons.download,
                  color: Colors.teal,
                  onPressed: _downloadSignedPdf,
                  enabled: true,
                ),
                const SizedBox(height: 12),

                // Generate Signed PDF Button (Indigo)
                _buildFeatureButton(
                  label: _generatedPdf != null
                      ? 'Generate Signed PDF ✓'
                      : 'Generate Signed PDF',
                  icon: _generatedPdf != null
                      ? Icons.check_circle
                      : Icons.picture_as_pdf_outlined,
                  color: Colors.indigo,
                  onPressed: _generateSignedPdf,
                  enabled: true,
                ),
                const SizedBox(height: 12),

                // Fill Personal Information Form Button (Green)
                _buildFeatureButton(
                  label: _savedFormData != null
                      ? 'Fill Personal Information Form ✓'
                      : 'Fill Personal Information Form',
                  icon: _savedFormData != null ? Icons.assignment_turned_in : Icons.assignment,
                  color: _savedFormData != null ? Colors.green[700]! : Colors.green,
                  onPressed: _openFormFillPage,
                  enabled: true,
                ),
                const SizedBox(height: 20),

                // Captured Image Preview
                if (_capturedImage != null) ...[
                  Card(
                    color: Colors.grey[850],
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          color: Colors.grey[800],
                          child: const Row(
                            children: [
                              Icon(Icons.image, color: Colors.blue, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Captured Image',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Image.file(
                          _capturedImage!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Raw Scanned Text (Expandable)
                if (_result != null && _result!.rawText != null) ...[
                  Card(
                    color: Colors.grey[850],
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              _showRawText = !_showRawText;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.orange.withOpacity(0.2),
                                  Colors.grey[850]!,
                                ],
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.document_scanner,
                                  color: Colors.orange,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Scanned Text from ID Card',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_result!.lines?.length ?? 0} lines detected',
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  _showRawText
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: Colors.orange,
                                  size: 28,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_showRawText)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              border: Border(
                                top: BorderSide(color: Colors.orange.withOpacity(0.3), width: 2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: Colors.grey[500],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Raw OCR Output (Latin script only):',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.green.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: SelectableText(
                                    _result!.rawText!.isEmpty
                                        ? '(No text detected)'
                                        : _result!.rawText!,
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 14,
                                      fontFamily: 'Courier New',
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.copy,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Tip: Long press text to copy',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Parsed Results Card
                if (_result != null)
                  Card(
                    color: Colors.grey[850],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Row(
                              children: [
                                Icon(
                                  _result!.hasIds
                                      ? Icons.check_circle
                                      : Icons.warning,
                                  color: _result!.hasIds
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _result!.hasIds
                                      ? 'Document Recognized (${_result!.idCount} found)'
                                      : 'No Document Found',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          if (_result!.hasIds) ...[
                            const Divider(color: Colors.grey, height: 24),
                            for (var id in _result!.parsedIds!)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    id.type,
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  for (var entry in id.fields.entries)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              entry.key,
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                              entry.value.toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                          ],
                          
                          // Digital Signature Status
                          if (_digitalSignature != null) ...[
                            const Divider(color: Colors.grey, height: 24),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.verified, color: Colors.purple, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Digital Signature Applied',
                                            style: TextStyle(
                                              color: Colors.purple,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (_signatureData != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              'Role: ${_signatureData!.role} • ${_signatureData!.timestamp.toString().substring(0, 16)}',
                                              style: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                // Signature Preview
                                if (_signatureData != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.purple.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        // Signature Image Preview
                                        Container(
                                          width: 120,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey[300]!),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Image.memory(
                                            _signatureData!.previewPng,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Signature Preview',
                                                style: TextStyle(
                                                  color: Colors.grey[800],
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Ready for PDF insertion',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                          
                          // PDF Generation Status
                          if (_generatedPdf != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.picture_as_pdf, color: Colors.indigo, size: 20),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'PDF Generated',
                                    style: TextStyle(
                                      color: Colors.indigo,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          
                          // Processing Time
                          if (_result!.processingTime != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.timer, color: Colors.grey[400], size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Processing Time: ${_result!.processingTime!.inMilliseconds}ms',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                
                // Form Data Status Card
                if (_savedFormData != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    color: Colors.grey[850],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.assignment_turned_in, color: Colors.green, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Form Data Saved',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow('Name', _savedFormData!['FullName'] ?? '-'),
                                if (_savedFormData!['FullNameLoc']?.isNotEmpty == true)
                                  _buildInfoRow('中文名稱', _savedFormData!['FullNameLoc']!),
                                _buildInfoRow('Gender', _savedFormData!['Gender'] ?? '-'),
                                _buildInfoRow('Nationality', _savedFormData!['Nationality'] ?? '-'),
                                if (_savedFormData!['CompanyName']?.isNotEmpty == true)
                                  _buildInfoRow('Company', _savedFormData!['CompanyName']!),
                                const SizedBox(height: 8),
                                Text(
                                  '✓ ${_savedFormData!.length} fields ready for PDF',
                                  style: TextStyle(
                                    color: Colors.green[300],
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Loading Overlay
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.white,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Processing...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    bool enabled = true,
  }) {
    final isEnabled = enabled && onPressed != null && !_isProcessing;

    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: isEnabled ? onPressed : null,
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? color : Colors.grey[700],
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[800],
          disabledForegroundColor: Colors.grey[600],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: isEnabled ? 4 : 0,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: SelectableText(content),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
