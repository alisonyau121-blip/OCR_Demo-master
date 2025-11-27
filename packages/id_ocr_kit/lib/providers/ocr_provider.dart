import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Abstract OCR provider interface
abstract class OcrProvider {
  Future<String> recognizeText(String imagePath);
  void dispose();
}

/// ML Kit implementation with both Latin and Chinese support
/// 
/// This adapter uses two recognizers:
/// - Latin: For English text, numbers, and passport MRZ (bundled, works offline)
/// - Chinese: For 中文 characters (requires model download on first use, ~10MB)
/// 
/// The Chinese model will be automatically downloaded when first used if you have internet.
/// After download, it works offline.
class MlKitOcrAdapter implements OcrProvider {
  late final TextRecognizer _latinRecognizer;
  TextRecognizer? _chineseRecognizer;
  bool _chineseInitialized = false;
  bool _chineseAvailable = true;

  MlKitOcrAdapter() {
    // Latin recognizer is always available (bundled by default)
    _latinRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    print('✅ ML Kit OCR initialized (Latin support ready)');
    print('📦 Chinese model will be downloaded on first OCR if available');
  }

  /// Initialize Chinese recognizer lazily (model downloads on first use)
  Future<void> _ensureChineseInitialized() async {
    if (_chineseInitialized || !_chineseAvailable) return;
    
    try {
      print('🔄 Initializing Chinese text recognizer...');
      print('📥 First-time use may download Chinese model (~10MB, requires internet)');
      
      _chineseRecognizer = TextRecognizer(script: TextRecognitionScript.chinese);
      _chineseInitialized = true;
      
      print('✅ Chinese text recognizer initialized successfully!');
    } catch (e) {
      print('❌ Chinese text recognition unavailable: $e');
      print('💡 This may happen if:');
      print('   - No internet connection for model download');
      print('   - Insufficient storage space');
      print('   - Model download service unavailable');
      print('   App will continue with Latin-only OCR.');
      _chineseAvailable = false;
      _chineseInitialized = true;
    }
  }

  @override
  Future<String> recognizeText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final uniqueLines = <String>{};
    
    // Ensure Chinese recognizer is initialized
    await _ensureChineseInitialized();
    
    try {
      // Latin OCR (for English, numbers, passport MRZ)
      final latinText = await _latinRecognizer.processImage(inputImage);
      if (latinText.text.isNotEmpty) {
        for (final line in latinText.text.split('\n')) {
          final trimmed = line.trim();
          if (trimmed.isNotEmpty) {
            uniqueLines.add(trimmed);
          }
        }
      }
      print('✅ Latin OCR: ${latinText.text.length} characters');
    } catch (e) {
      print('⚠️ Latin OCR failed: $e');
    }
    
    // Chinese OCR (if available)
    if (_chineseAvailable && _chineseRecognizer != null) {
      try {
        final chineseText = await _chineseRecognizer!.processImage(inputImage);
        if (chineseText.text.isNotEmpty) {
          for (final line in chineseText.text.split('\n')) {
            final trimmed = line.trim();
            if (trimmed.isNotEmpty) {
              uniqueLines.add(trimmed);
            }
          }
        }
        print('✅ Chinese OCR: ${chineseText.text.length} characters');
      } catch (e) {
        print('⚠️ Chinese OCR failed: $e');
        // Don't disable permanently - model might still be downloading
      }
    } else if (!_chineseAvailable) {
      print('ℹ️ Chinese OCR skipped (not available)');
    }
    
    final result = uniqueLines.join('\n');
    print('📝 Total OCR: ${result.length} characters, ${uniqueLines.length} unique lines');
    
    return result;
  }

  @override
  void dispose() {
    _latinRecognizer.close();
    _chineseRecognizer?.close();
  }
}


