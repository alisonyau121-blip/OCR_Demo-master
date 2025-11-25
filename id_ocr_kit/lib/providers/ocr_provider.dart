import 'dart:io';

/// Abstract interface for OCR (Optical Character Recognition) implementations
/// 
/// Consumers must provide their own implementation
/// (Google ML Kit, Tesseract, AWS Textract, Azure Computer Vision, etc.)
/// 
/// This abstraction allows the package to remain plugin-agnostic and
/// gives consumers freedom to choose their preferred OCR technology.
abstract class OcrProvider {
  /// Recognizes text from an image file
  /// 
  /// Returns [OcrResult] containing recognized text and metadata.
  /// Throws [OcrException] on failure.
  /// 
  /// Example:
  /// ```dart
  /// final result = await ocrProvider.recognizeText(
  ///   OcrRequest(
  ///     imageFile: File('id_card.jpg'),
  ///     scripts: [OcrScript.latin, OcrScript.chinese],
  ///   ),
  /// );
  /// ```
  Future<OcrResult> recognizeText(OcrRequest request);
  
  /// Release resources (if applicable)
  /// 
  /// Call this when the provider is no longer needed to clean up
  /// any allocated resources (recognizer models, network connections, etc.)
  Future<void> dispose();
}

/// Request object for OCR operations
class OcrRequest {
  /// Image file to process
  final File imageFile;
  
  /// Scripts/languages to recognize
  /// 
  /// For ID documents, typically use [OcrScript.latin] for MRZ/English
  /// and [OcrScript.chinese] for Chinese text on HKID/CN ID cards.
  final List<OcrScript> scripts;
  
  const OcrRequest({
    required this.imageFile,
    this.scripts = const [OcrScript.latin, OcrScript.chinese],
  });
}

/// OCR scripts/languages supported
enum OcrScript {
  /// Latin alphabet (English, numbers, passport MRZ)
  latin,
  
  /// Chinese characters (Simplified and Traditional)
  chinese,
  
  /// Japanese characters (Hiragana, Katakana, Kanji)
  japanese,
  
  /// Korean characters (Hangul)
  korean,
}

/// Result object from OCR operation
class OcrResult {
  /// Combined recognized text from all scripts
  final String text;
  
  /// Individual lines of text (deduplicated)
  final List<String> lines;
  
  /// Character counts per script (optional metadata)
  final Map<OcrScript, int> scriptCharCounts;
  
  /// Time taken to process the image
  final Duration processingTime;
  
  const OcrResult({
    required this.text,
    required this.lines,
    this.scriptCharCounts = const {},
    required this.processingTime,
  });
  
  /// Returns true if no text was detected
  bool get isEmpty => text.trim().isEmpty;
  
  /// Returns true if text was detected
  bool get isNotEmpty => !isEmpty;
}

/// OCR-specific exceptions
class OcrException implements Exception {
  final String message;
  final OcrErrorType type;
  final Object? originalError;
  
  const OcrException(this.message, this.type, [this.originalError]);
  
  @override
  String toString() => 'OcrException($type): $message';
}

/// Types of OCR errors
enum OcrErrorType {
  /// Image file not found or inaccessible
  fileNotFound,
  
  /// Image format not supported or corrupted
  invalidFormat,
  
  /// OCR processing failed (engine error, timeout, etc.)
  processingFailed,
  
  /// Requested script/language not supported by implementation
  unsupportedScript,
  
  /// OCR provider not initialized properly
  notInitialized,
}

