// INTERNAL IMPLEMENTATION - NOT PART OF PUBLIC API
// This file is in src/ and should not be exported in the main library file.
// 
// This is a reference implementation using Google ML Kit.
// Consumer apps can use this as an example or create their own implementation.

import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:logging/logging.dart';
import '../../providers/ocr_provider.dart';

/// Internal adapter: Google ML Kit OCR implementation
/// 
/// This is a reference implementation that wraps Google ML Kit's
/// text recognition API to conform to the [OcrProvider] interface.
/// 
/// **Not part of public API** - consumers should implement their own
/// [OcrProvider] or copy this implementation to their app.
/// 
/// Features:
/// - Dual-script recognition (Latin + Chinese)
/// - Automatic deduplication of recognized lines
/// - Graceful error handling
/// - Resource management
class MlKitOcrAdapter implements OcrProvider {
  static final _log = Logger('MlKitOcrAdapter');
  
  final Map<TextRecognitionScript, TextRecognizer> _recognizers = {};
  final Set<TextRecognitionScript> _failedScripts = {};
  bool _disposed = false;
  
  @override
  Future<OcrResult> recognizeText(OcrRequest request) async {
    if (_disposed) {
      throw const OcrException(
        'OCR provider has been disposed',
        OcrErrorType.notInitialized,
      );
    }
    
    final startTime = DateTime.now();
    
    try {
      // Validate input file
      if (!await request.imageFile.exists()) {
        throw const OcrException(
          'Image file does not exist',
          OcrErrorType.fileNotFound,
        );
      }
      
      _log.info('Creating InputImage from: ${request.imageFile.path}');
      final inputImage = InputImage.fromFilePath(request.imageFile.path);
      
      // Process with each requested script
      final uniqueLines = <String>{};
      final scriptCounts = <OcrScript, int>{};
      
      for (final script in request.scripts) {
        // Skip scripts that previously failed to initialize
        if (_failedScripts.contains(_convertToMlKitScript(script))) {
          _log.fine('Skipping script $script (previously failed)');
          continue;
        }
        
        try {
          final mlkitScript = _convertToMlKitScript(script);
          final recognizer = _recognizers.putIfAbsent(
            mlkitScript,
            () => _initializeRecognizer(mlkitScript),
          );
          
          _log.info('Processing with script: $script');
          final recognized = await recognizer.processImage(inputImage);
          
          int charCount = 0;
          for (final block in recognized.blocks) {
            for (final line in block.lines) {
              final trimmed = line.text.trim();
              if (trimmed.isNotEmpty && uniqueLines.add(trimmed)) {
                charCount += trimmed.length;
              }
            }
          }
          
          scriptCounts[script] = charCount;
          _log.info('OCR ($script) completed: $charCount characters');
          
        } catch (e, st) {
          _log.severe('Error processing with script $script', e, st);
          _failedScripts.add(_convertToMlKitScript(script));
          
          // If this is the only script and it failed, throw exception
          if (request.scripts.length == 1) {
            throw OcrException(
              'OCR processing failed: $e',
              OcrErrorType.processingFailed,
              e,
            );
          }
          // Otherwise continue with other scripts
        }
      }
      
      final processingTime = DateTime.now().difference(startTime);
      final combinedText = uniqueLines.join('\n');
      
      _log.info('OCR completed: ${uniqueLines.length} unique lines, '
          '${combinedText.length} total characters');
      
      return OcrResult(
        text: combinedText,
        lines: uniqueLines.toList(),
        scriptCharCounts: scriptCounts,
        processingTime: processingTime,
      );
      
    } catch (e) {
      if (e is OcrException) rethrow;
      
      throw OcrException(
        'Unexpected OCR error: $e',
        OcrErrorType.processingFailed,
        e,
      );
    }
  }
  
  @override
  Future<void> dispose() async {
    if (_disposed) return;
    
    try {
      _log.info('Disposing ML Kit recognizers');
      for (final recognizer in _recognizers.values) {
        await recognizer.close();
      }
      _recognizers.clear();
      _failedScripts.clear();
      _disposed = true;
      _log.info('ML Kit OCR adapter disposed');
    } catch (e, st) {
      _log.severe('Error disposing ML Kit recognizers', e, st);
    }
  }
  
  /// Initialize a text recognizer for a specific script
  TextRecognizer _initializeRecognizer(TextRecognitionScript script) {
    try {
      _log.info('Initializing ML Kit recognizer for script: $script');
      return TextRecognizer(script: script);
    } catch (e, st) {
      _log.severe('Failed to initialize recognizer for $script', e, st);
      _failedScripts.add(script);
      throw OcrException(
        'Failed to initialize recognizer for $script: $e',
        OcrErrorType.notInitialized,
        e,
      );
    }
  }
  
  /// Convert package script enum to ML Kit script enum
  TextRecognitionScript _convertToMlKitScript(OcrScript script) {
    switch (script) {
      case OcrScript.latin:
        return TextRecognitionScript.latin;
      case OcrScript.chinese:
        return TextRecognitionScript.chinese;
      case OcrScript.japanese:
        return TextRecognitionScript.japanese;
      case OcrScript.korean:
        return TextRecognitionScript.korean;
    }
  }
}

