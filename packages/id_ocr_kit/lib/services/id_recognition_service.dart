import 'dart:io';
import '../providers/ocr_provider.dart';
import 'id_parser.dart';

/// High-level service for ID recognition and parsing
/// 
/// This service combines OCR with ID parsing to recognize and extract
/// structured data from identity documents (HKID, China ID, Passports).
/// 
/// **Usage:**
/// ```dart
/// final service = IdRecognitionService(ocrProvider: myOcrProvider);
/// final result = await service.recognizeId(imageFile);
/// 
/// if (result.isSuccess) {
///   print('Found ${result.parsedIds!.length} IDs');
///   for (final id in result.parsedIds!) {
///     print('${id.type}: ${id.fields}');
///   }
/// } else {
///   print('Error: ${result.error}');
/// }
/// 
/// await service.dispose();
/// ```
class IdRecognitionService {
  final OcrProvider _ocrProvider;
  
  /// Creates a new ID recognition service
  /// 
  /// [ocrProvider] must be provided by the consumer app to handle
  /// the actual OCR processing (using ML Kit, Tesseract, etc.)
  IdRecognitionService({required OcrProvider ocrProvider})
      : _ocrProvider = ocrProvider;
  
  /// Recognizes and parses ID documents from an image
  /// 
  /// This method performs two steps:
  /// 1. OCR: Extract text from the image using the provided [OcrProvider]
  /// 2. Parse: Analyze the text to identify ID documents (HKID, China ID, Passport)
  /// 
  /// Returns [IdRecognitionResult] which contains:
  /// - Raw OCR text
  /// - Individual text lines
  /// - Parsed ID documents (if any found)
  /// - Processing time
  /// - Error information (if failed)
  /// 
  /// This method never throws exceptions - all errors are captured
  /// in the result object.
  Future<IdRecognitionResult> recognizeId(File imageFile) async {
    final startTime = DateTime.now();
    
    try {
      // Step 1: Perform OCR (returns merged Latin + Chinese text)
      final ocrText = await _ocrProvider.recognizeText(imageFile.path);
      
      // Check if OCR found any text
      if (ocrText.trim().isEmpty) {
        return IdRecognitionResult.error(
          error: 'No text detected in image',
          errorType: IdRecognitionErrorType.noTextDetected,
        );
      }
      
      // Split into lines
      final lines = ocrText.split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      
      // Step 2: Parse IDs from OCR text (pure domain logic)
      final parsedIds = IdParser.parseAll(ocrText);
      
      final processingTime = DateTime.now().difference(startTime);
      
      return IdRecognitionResult(
        rawText: ocrText,
        lines: lines,
        parsedIds: parsedIds,
        processingTime: processingTime,
      );
    } catch (e) {
      return IdRecognitionResult.error(
        error: 'OCR failed: $e',
        errorType: IdRecognitionErrorType.ocrFailed,
      );
    }
  }
  
  /// Release resources used by the OCR provider
  /// 
  /// Call this when the service is no longer needed.
  void dispose() => _ocrProvider.dispose();
}

/// Result from ID recognition operation
/// 
/// This class uses a nullable pattern to represent success/failure states:
/// - Success: [error] is null, data fields are populated
/// - Failure: [error] is not null, [errorType] indicates the cause
class IdRecognitionResult {
  /// Raw text extracted by OCR (null if error occurred)
  final String? rawText;
  
  /// Individual lines of text (null if error occurred)
  final List<String>? lines;
  
  /// Parsed ID documents found in the text (empty list if none found)
  final List<IdParseResult>? parsedIds;
  
  /// Time taken to process the image (null if error occurred)
  final Duration? processingTime;
  
  /// Error message (null if success)
  final String? error;
  
  /// Error type (null if success)
  final IdRecognitionErrorType? errorType;
  
  const IdRecognitionResult({
    this.rawText,
    this.lines,
    this.parsedIds,
    this.processingTime,
    this.error,
    this.errorType,
  });
  
  /// Creates an error result
  factory IdRecognitionResult.error({
    required String error,
    required IdRecognitionErrorType errorType,
  }) {
    return IdRecognitionResult(
      error: error,
      errorType: errorType,
    );
  }
  
  /// Returns true if recognition succeeded
  bool get isSuccess => error == null;
  
  /// Returns true if recognition failed
  bool get isError => error != null;
  
  /// Returns true if at least one ID was successfully parsed
  bool get hasIds => parsedIds?.isNotEmpty ?? false;
  
  /// Returns the number of IDs found (0 if none or error)
  int get idCount => parsedIds?.length ?? 0;
}

/// Types of errors that can occur during ID recognition
enum IdRecognitionErrorType {
  /// OCR processing failed
  ocrFailed,
  
  /// Image file not found or inaccessible
  fileNotFound,
  
  /// Image format is invalid or not supported
  invalidImageFormat,
  
  /// OCR succeeded but no text was detected in the image
  noTextDetected,
  
  /// Unexpected error occurred
  unexpectedError,
}
