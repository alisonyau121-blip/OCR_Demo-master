import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:tesseract_ocr/tesseract_ocr.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;




class ScanPage extends StatefulWidget {
  const ScanPage({super.key});
  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();
  
  bool _isProcessing = false;
  String? _recognizedText;
  String extractedText = ''; // For _extractTextMLKit method

  Future<void> _pickImage(ImageSource source) async {
    // Limit image size to reduce OOM (Out Of Memory) risk
    final XFile? image = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85, // Moderate compression of image quality
    );

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
        _recognizedText = null; // Clear old results after selecting new image
        extractedText = ''; // Clear extracted text
      });
    }
  }

  Future<void> _processImage() async {
    if (_imageFile == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final text = await _ocrService.processImage(_imageFile!);
      if (!mounted) return;

      setState(() {
        _recognizedText = text;
        extractedText = text; // Sync update extractedText
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recognition failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // ML Kit Method - Direct implementation
  Future<void> _extractTextMLKit() async {
    if (_imageFile == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final inputImage = InputImage.fromFile(_imageFile!);
      final textRecognizer = TextRecognizer();
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      if (!mounted) return;
      setState(() {
        extractedText = recognizedText.text;
      });

      textRecognizer.close();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ML Kit recognition failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // Tesseract Method (Offline OCR)
  Future<void> _extractTextTesseract() async {
    if (_imageFile == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final text = await TesseractOcr.extractText(_imageFile!.path);
      if (!mounted) return;
      setState(() {
        extractedText = text;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tesseract recognition failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // Display extracted text with copy and save functionality
  Widget _displayExtractedText() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: SelectableText(
              extractedText.isNotEmpty 
                  ? extractedText 
                  : 'Click button to start text recognition...',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        if (extractedText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: extractedText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Text copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text("Copy"),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _saveTextToFile,
                  icon: const Icon(Icons.save),
                  label: const Text("Save"),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Save extracted text to a file
  Future<void> _saveTextToFile() async {
    if (extractedText.isEmpty) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'extracted_text_$timestamp.txt';
      final filePath = path.join(directory.path, fileName);
      
      final file = File(filePath);
      await file.writeAsString(extractedText);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Text saved to: $fileName'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _ocrService.dispose(); // Release recognizer when page is destroyed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Image')),
      body: Column(
        children: [
          // Image preview section
          Expanded(
            flex: 3,
            child: _imageFile == null
                ? const Center(child: Text('No image selected'))
                : Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Image.file(_imageFile!),
                  ),
          ),
          
          // Image picker buttons
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Capture Photo'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Choose from Gallery'),
                ),
              ],
            ),
          ),
          
          // OCR method buttons
          if (_imageFile != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: !_isProcessing ? _processImage : null,
                    icon: const Icon(Icons.analytics),
                    label: const Text('OcrService'),
                  ),
                  ElevatedButton.icon(
                    onPressed: !_isProcessing ? _extractTextMLKit : null,
                    icon: const Icon(Icons.text_fields),
                    label: const Text('ML Kit'),
                  ),
                  ElevatedButton.icon(
                    onPressed: !_isProcessing ? _extractTextTesseract : null,
                    icon: const Icon(Icons.offline_bolt),
                    label: const Text('Tesseract'),
                  ),
                ],
              ),
            ),
          
          // Extracted text display section
          Expanded(
            flex: 2,
            child: _isProcessing
                ? const Center(child: CircularProgressIndicator())
                : _displayExtractedText(),
          ),
        ],
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
      return 'Unable to recognize text in the image: ${e.toString()}';
    }
  }

  Future<void> dispose() async {
    if (!_closed) {
      await _recognizer.close();
      _closed = true;
    }
  }
}