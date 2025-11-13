import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'id_parsers.dart';
import 'package:signature/signature.dart';
import 'digital_signature_page.dart';

Future<void> main() async {
  // Global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    print('Flutter error: ${details.exception}');
    print('Stack trace: ${details.stack}');
  };
  
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    print('Application starting...');
    
    runApp(
      MaterialApp(
        title: 'ID OCR Demo',
        theme: ThemeData.dark(),
        debugShowCheckedModeBanner: false,
        home: const SelectImageScreen(),
      ),
    );
  } catch (e, stackTrace) {
    print('Startup failed: $e');
    print('Stack trace: $stackTrace');
    
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Startup failed:\n$e\n\nPlease check logs',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SelectImageScreen extends StatefulWidget {
  const SelectImageScreen({super.key});

  @override
  State<SelectImageScreen> createState() => _SelectImageScreenState();
}

class _SelectImageScreenState extends State<SelectImageScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      print('Selecting image source: $source');
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      
      if (image == null) {
        print('User cancelled selection');
        return;
      }
      
      print('Image selected: ${image.path}');
      
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => DisplayPictureScreen(imagePath: image.path),
        ),
      );
    } catch (e, stackTrace) {
      print('Failed to select image: $e');
      print('Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select image: $e'),
            backgroundColor: Colors.red,
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Icon
              Icon(
                Icons.credit_card,
                size: 120,
                color: Colors.blue.shade400,
              ),
              const SizedBox(height: 32),
              
              // Title
              const Text(
                'ID Recognition System',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Subtitle
              Text(
                'Supports HKID / China ID / Passport',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 48),
              
              // Buttons
              SizedBox(
                width: 300,
                child: Column(
                  children: [
                    // Camera button (only on mobile)
                    if (!_isWeb())
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt, size: 28),
                        label: const Text(
                          'Capture Document',
                          style: TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(60),
                          backgroundColor: Colors.blue,
                        ),
                      ),
                    
                    if (!_isWeb()) const SizedBox(height: 16),
                    
                    // Gallery button
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library, size: 28),
                      label: Text(
                        _isWeb() ? 'Select Image' : 'Choose from Gallery',
                        style: const TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(60),
                        backgroundColor: Colors.green,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Digital Signature button
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const DigitalSignaturePage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit, size: 28),
                      label: const Text(
                        'Digital Signature',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(60),
                        backgroundColor: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Features list
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFeature('🇭🇰', 'HKID - Hong Kong ID Card'),
                    const SizedBox(height: 12),
                    _buildFeature('🇨🇳', 'China ID - 18 Digits'),
                    const SizedBox(height: 12),
                    _buildFeature('🛂', 'Passport MRZ (TD3)'),
                    const SizedBox(height: 12),
                    _buildFeature('✅', 'Auto Check Digit Validation'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeature(String emoji, String text) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
  
  bool _isWeb() {
    // Returns false on Android/iOS
    return false;
  }
}

class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;
  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  State<DisplayPictureScreen> createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  bool _isProcessing = false;
  String _rawOcrText = '';
  List<IdParseResult> _parseResults = [];
  
  @override
  void initState() {
    super.initState();
    // Delay auto-start recognition to give UI time to initialize
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        print('UI initialized, starting auto-recognition');
        _processImage();
      }
    });
  }
  
  Future<void> _processImage() async {
    if (!mounted) return;
    
    setState(() {
      _isProcessing = true;
      _rawOcrText = '';
      _parseResults = [];
    });
    
    OcrService? ocrService;
    
    try {
      print('========================================');
      print('Starting OCR recognition process...');
      print('Image path: ${widget.imagePath}');
      
      // Check if file exists
      final imageFile = File(widget.imagePath);
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist: ${widget.imagePath}');
      }
      
      print('File size: ${await imageFile.length()} bytes');
      
      // OCR recognition
      print('Initializing OCR service...');
      ocrService = OcrService();
      
      print('Processing image...');
      final text = await ocrService.processImage(imageFile);
      
      print('OCR completed! Text length: ${text.length}');
      if (text.isNotEmpty && text.length > 10) {
        print('OCR text preview: ${text.substring(0, text.length > 100 ? 100 : text.length)}...');
      } else {
        print('OCR text: $text');
      }
      
      // Parse all possible ID types
      print('Starting document parsing...');
      final results = IdParser.parseAll(text);
      print('Found ${results.length} document(s)');
      
      if (!mounted) {
        print('Widget unmounted, cancelling update');
        return;
      }
      
      setState(() {
        _rawOcrText = text;
        _parseResults = results;
        _isProcessing = false;
      });
      
      print('Recognition process completed!');
      print('========================================');
      
    } catch (e, stackTrace) {
      print('========================================');
      print('❌ OCR recognition failed: $e');
      print('Stack trace:');
      print(stackTrace);
      print('========================================');
      
      if (!mounted) return;
      
      setState(() {
        _rawOcrText = 'Recognition failed:\n$e\n\nDetails:\n$stackTrace';
        _isProcessing = false;
      });
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recognition failed: ${e.toString().substring(0, 50)}...'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Details',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Error Details'),
                    content: SingleChildScrollView(
                      child: Text('$e\n\n$stackTrace'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    } finally {
      // Ensure resources are released
      if (ocrService != null) {
        try {
          await ocrService.dispose();
        } catch (e) {
          print('Failed to dispose OCR service: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ID OCR Recognition'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isProcessing ? null : _processImage,
            tooltip: 'Re-recognize',
          ),
        ],
      ),
      body: Column(
        children: [
          // Image preview
          Container(
            height: 200,
            width: double.infinity,
            color: Colors.black,
            child: Image.file(
              File(widget.imagePath),
              fit: BoxFit.contain,
            ),
          ),
          
          // Recognition results
          Expanded(
            child: _isProcessing
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Recognizing...'),
                      ],
                    ),
                  )
                : _buildResultsView(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Parse results
          if (_parseResults.isEmpty)
            Card(
              color: Colors.orange.shade900,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No valid ID document recognized\nPlease ensure the image is clear and contains the complete document',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._parseResults.map((result) => _buildResultCard(result)),
          
          const SizedBox(height: 24),
          
          // Raw OCR text (for debugging)
          ExpansionTile(
            title: const Text(
              'Raw OCR Text (Debug)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            initiallyExpanded: _parseResults.isEmpty,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  _rawOcrText.isEmpty ? '(empty)' : _rawOcrText,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultCard(IdParseResult result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: result.isValid ? Colors.green.shade900 : Colors.red.shade900,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                Icon(
                  result.isValid ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.type,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white54, height: 24),
            
            // Fields list
            ...result.fields.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SelectableText(
                      entry.value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class OcrService {
  final Map<TextRecognitionScript, TextRecognizer> _recognizers = {};
  final Set<TextRecognitionScript> _failedScripts = {};
  bool _closed = false;

  /// We run the recognizer twice – once for Latin text (numbers/English/MRZ)
  /// and once for Chinese so HKID names are captured.
  /// If Chinese recognizer fails to initialize, we gracefully fall back to Latin only.
  static const List<TextRecognitionScript> _scriptsToRun = [
    TextRecognitionScript.latin,
    TextRecognitionScript.chinese,
  ];

  Future<String> processImage(File imageFile) async {
    try {
      print('Creating InputImage...');
      final inputImage = InputImage.fromFilePath(imageFile.path);

      final Set<String> uniqueLines = {};
      final buffer = StringBuffer();

      for (final script in _scriptsToRun) {
        // Skip scripts that have previously failed to initialize
        if (_failedScripts.contains(script)) {
          print('Skipping script $script (previously failed to initialize)');
          continue;
        }

        try {
          // Initialize recognizer with error handling
          final recognizer = _recognizers.putIfAbsent(
            script,
            () {
              try {
                print('Initializing recognizer for script: $script');
                return TextRecognizer(script: script);
              } catch (e) {
                print('Failed to initialize recognizer for $script: $e');
                _failedScripts.add(script);
                rethrow;
              }
            },
          );

          print('Processing image with script: $script...');
          final recognizedText = await recognizer.processImage(inputImage);
          print(
            'OCR (${script.name}) completed, recognized '
            '${recognizedText.text.length} characters',
          );

          for (final block in recognizedText.blocks) {
            for (final line in block.lines) {
              final trimmed = line.text.trim();
              if (trimmed.isNotEmpty && uniqueLines.add(trimmed)) {
                buffer.writeln(trimmed);
              }
            }
          }
        } catch (e) {
          // If initialization or processing fails for a script, mark it as failed
          // and continue with other scripts
          print('Error processing with script $script: $e');
          _failedScripts.add(script);
          // Don't rethrow - continue with other scripts
        }
      }

      final combinedText = buffer.toString().trim();
      if (combinedText.isEmpty) {
        return '(no text detected)';
      }
      
      if (_failedScripts.contains(TextRecognitionScript.chinese)) {
        print('Warning: Chinese recognition unavailable. Some Chinese text may not be detected.');
      }
      
      return combinedText;
    } catch (e, stackTrace) {
      print('OCR processing failed: $e');
      print('Stack trace: $stackTrace');
      return 'Unable to recognize text in the image: ${e.toString()}';
    }
  }

  Future<void> dispose() async {
    if (_closed) return;

    try {
      for (final recognizer in _recognizers.values) {
        await recognizer.close();
      }
      _closed = true;
      print('OCR services closed');
    } catch (e) {
      print('Failed to close OCR services: $e');
    }
  }
}

