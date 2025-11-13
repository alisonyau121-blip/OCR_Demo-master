import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'id_parsers.dart';

Future<void> main() async {
  // Global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    print('Flutter error: ${details.exception}');
    print('Stack trace: ${details.stack}');
  };
  
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    MaterialApp(
      title: 'ID OCR Demo',
      theme: ThemeData.dark(),
      home: const SelectImageScreen(),
    ),
  );
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
      print('Image selection failed: $e');
      print('Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image selection failed: $e'),
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
                'ID Document Recognition System',
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
                          'Capture ID',
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
                        _isWeb() ? 'Select Image' : 'From Gallery',
                        style: const TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(60),
                        backgroundColor: Colors.green,
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
                    _buildFeature('🇨🇳', 'China 18-digit ID Card'),
                    const SizedBox(height: 12),
                    _buildFeature('🛂', 'Passport MRZ (TD3)'),
                    const SizedBox(height: 12),
                    _buildFeature('✅', 'Automatic Check Digit Validation'),
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
    try {
      return identical(0, 0.0); // Returns true on Web platform
    } catch (e) {
      return false;
    }
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
    // Automatically start recognition
    _processImage();
  }
  
  Future<void> _processImage() async {
    setState(() {
      _isProcessing = true;
      _rawOcrText = '';
      _parseResults = [];
    });
    
    try {
      print('Starting OCR recognition...');
      
      // OCR recognition
      final ocrService = OcrService();
      final text = await ocrService.processImage(File(widget.imagePath));
      await ocrService.dispose();
      
      print('OCR completed, text length: ${text.length}');
      if (text.isNotEmpty) {
        print('OCR text preview: ${text.substring(0, text.length > 100 ? 100 : text.length)}...');
      }
      
      // Parse all possible ID types
      print('Starting ID parsing...');
      final results = IdParser.parseAll(text);
      print('Found ${results.length} document(s)');
      
      if (!mounted) return;
      setState(() {
        _rawOcrText = text;
        _parseResults = results;
        _isProcessing = false;
      });
    } catch (e, stackTrace) {
      print('OCR recognition failed: $e');
      print('Stack trace: $stackTrace');
      
      if (!mounted) return;
      setState(() {
        _rawOcrText = 'Recognition failed: $e\n\nStack trace:\n$stackTrace';
        _isProcessing = false;
      });
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OCR recognition failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
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
                        'No valid ID document recognized\nPlease ensure the image is clear and contains a complete ID',
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
                  _rawOcrText.isEmpty ? '(Empty)' : _rawOcrText,
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
            
            // Field list
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
  late final TextRecognizer _recognizer = 
      TextRecognizer(script: TextRecognitionScript.chinese);
  bool _closed = false;

  Future<String> processImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final recognizedText = await _recognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      return 'Unable to recognize text in image: ${e.toString()}';
    }
  }

  Future<void> dispose() async {
    if (!_closed) {
      await _recognizer.close();
      _closed = true;
    }
  }
}

