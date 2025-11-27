import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:logging/logging.dart';

/// Service for performing OCR (Optical Character Recognition) on images
/// 
/// Supports dual-script recognition (Latin + Chinese) with graceful fallback
/// if Chinese recognition is unavailable.
class OcrService {
  static final _log = Logger('OcrService');
  
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

  /// Process an image file and extract text using OCR
  /// 
  /// Returns the combined recognized text from all available scripts.
  /// If no text is detected, returns "(no text detected)".
  Future<String> processImage(File imageFile) async {
    try {
      _log.info('Creating InputImage from: ${imageFile.path}');
      final inputImage = InputImage.fromFilePath(imageFile.path);

      final Set<String> uniqueLines = {};
      final buffer = StringBuffer();

      for (final script in _scriptsToRun) {
        // Skip scripts that have previously failed to initialize
        if (_failedScripts.contains(script)) {
          _log.fine('Skipping script $script (previously failed to initialize)');
          continue;
        }

        try {
          // Initialize recognizer with error handling
          final recognizer = _recognizers.putIfAbsent(
            script,
            () => _initializeRecognizer(script),
          );

          _log.info('Processing image with script: $script...');
          final recognizedText = await recognizer.processImage(inputImage);
          _log.info(
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
        } catch (e, st) {
          // If initialization or processing fails for a script, mark it as failed
          // and continue with other scripts
          _log.severe('Error processing with script $script', e, st);
          _failedScripts.add(script);
          // Don't rethrow - continue with other scripts
        }
      }

      final combinedText = buffer.toString().trim();
      if (combinedText.isEmpty) {
        _log.warning('No text detected in image');
        return '(no text detected)';
      }
      
      if (_failedScripts.contains(TextRecognitionScript.chinese)) {
        _log.warning('Chinese recognition unavailable. Some Chinese text may not be detected.');
      }
      
      _log.info('OCR completed successfully, total length: ${combinedText.length}');
      return combinedText;
    } catch (e, st) {
      _log.severe('OCR processing failed', e, st);
      return 'Unable to recognize text in the image: ${e.toString()}';
    }
  }

  /// Initialize a text recognizer for a specific script
  TextRecognizer _initializeRecognizer(TextRecognitionScript script) {
    try {
      _log.info('Initializing recognizer for script: $script');
      return TextRecognizer(script: script);
    } catch (e, st) {
      _log.severe('Failed to initialize recognizer for $script', e, st);
      _failedScripts.add(script);
      rethrow;
    }
  }

  /// Release all resources used by the OCR service
  Future<void> dispose() async {
    if (_closed) return;

    try {
      for (final recognizer in _recognizers.values) {
        await recognizer.close();
      }
      _closed = true;
      _log.info('OCR services closed');
    } catch (e, st) {
      _log.severe('Failed to close OCR services', e, st);
    }
  }
}

