import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:tesseract_ocr/tesseract_ocr.dart';
import 'package:flutter/services.dart';

class OCRApp extends StatefulWidget {
  const OCRApp({super.key});

  @override
  State<OCRApp> createState() => _OCRAppState();
}

class _OCRAppState extends State<OCRApp> {
  File? _image;
  String extractedText = "";
  bool _isProcessing = false;

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        extractedText = "";
      });
    }
  }

  Future<void> _extractTextMLKit() async {
    if (_image == null) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      final inputImage = InputImage.fromFile(_image!);
      final textRecognizer = TextRecognizer();
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);
      
      if (!mounted) return;
      setState(() {
        extractedText = recognizedText.text;
      });
      
      textRecognizer.close();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ML Kit error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _extractTextTesseract() async {
    if (_image == null) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      final text = await TesseractOcr.extractText(_image!.path);
      if (!mounted) return;
      setState(() {
        extractedText = text;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tesseract error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Widget _displayExtractedText() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: SelectableText(
              extractedText.isNotEmpty 
                  ? extractedText 
                  : "Select an image and extract text...",
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
                        content: Text('Text copied to clipboard!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text("Copy"),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Flutter OCR App"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Image preview
          if (_image != null)
            Container(
              height: 200,
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              child: Image.file(_image!, fit: BoxFit.contain),
            )
          else
            Container(
              height: 200,
              alignment: Alignment.center,
              child: const Text(
                'No image selected',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          
          const SizedBox(height: 16),

          // Image picker buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Capture Image"),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text("Select from Gallery"),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // OCR method buttons
          if (_image != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _extractTextMLKit,
                    icon: const Icon(Icons.text_fields),
                    label: const Text("Extract with ML Kit"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _extractTextTesseract,
                    icon: const Icon(Icons.offline_bolt),
                    label: const Text("Extract with Tesseract"),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Text display area
          Expanded(
            child: _isProcessing
                ? const Center(child: CircularProgressIndicator())
                : _displayExtractedText(),
          ),
        ],
      ),
    );
  }
}

