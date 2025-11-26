import 'dart:typed_data';

/// Abstract interface for PDF operations
/// 
/// Consumers provide their own implementation using any PDF library
/// (Syncfusion, pdf package, pdfium, etc.)
/// 
/// This abstraction allows the package to remain library-agnostic and
/// gives consumers freedom to choose their preferred PDF solution.
abstract class PdfProvider {
  /// Loads a PDF document from bytes
  /// 
  /// Returns a [PdfDocument] handle for subsequent operations.
  /// Throws [PdfException] if loading fails.
  /// 
  /// Example:
  /// ```dart
  /// final doc = await pdfProvider.loadPdf(pdfBytes);
  /// ```
  Future<PdfDocument> loadPdf(Uint8List bytes);
  
  /// Inserts an image at specified coordinates on a page
  /// 
  /// The image will be fitted according to [fit] parameter while
  /// maintaining aspect ratio.
  /// 
  /// Example:
  /// ```dart
  /// await pdfProvider.insertImageAtPosition(
  ///   document: doc,
  ///   pageIndex: 0,
  ///   imageBytes: signaturePng,
  ///   rect: PdfRect(left: 100, top: 200, width: 150, height: 50),
  ///   fit: PdfImageFit.contain,
  /// );
  /// ```
  Future<void> insertImageAtPosition({
    required PdfDocument document,
    required int pageIndex,
    required Uint8List imageBytes,
    required PdfRect rect,
    PdfImageFit fit = PdfImageFit.contain,
  });
  
  /// Fills a text form field with the specified value
  /// 
  /// Throws [PdfException] with [PdfErrorType.fieldNotFound] if the
  /// field doesn't exist in the PDF.
  /// 
  /// Example:
  /// ```dart
  /// await pdfProvider.fillTextField(
  ///   document: doc,
  ///   fieldName: 'CustomerName',
  ///   value: 'John Doe',
  /// );
  /// ```
  Future<void> fillTextField({
    required PdfDocument document,
    required String fieldName,
    required String value,
  });
  
  /// Saves the PDF document to bytes
  /// 
  /// Returns the complete PDF file as [Uint8List].
  /// 
  /// Example:
  /// ```dart
  /// final outputBytes = await pdfProvider.savePdf(doc);
  /// await File('output.pdf').writeAsBytes(outputBytes);
  /// ```
  Future<Uint8List> savePdf(PdfDocument document);
  
  /// Closes document and releases resources
  /// 
  /// Always call this when done with a document to prevent memory leaks.
  /// 
  /// Example:
  /// ```dart
  /// try {
  ///   final doc = await pdfProvider.loadPdf(bytes);
  ///   // ... work with document
  /// } finally {
  ///   await pdfProvider.dispose(doc);
  /// }
  /// ```
  Future<void> dispose(PdfDocument document);
}

/// Platform-agnostic PDF document handle
/// 
/// This is an opaque reference to the underlying PDF document.
/// The actual implementation is provided by the [PdfProvider].
abstract class PdfDocument {
  /// Unique identifier for this document instance
  String get id;
  
  /// Number of pages in the document
  int get pageCount;
}

/// Rectangle for positioning elements in PDF
class PdfRect {
  /// Distance from left edge of page
  final double left;
  
  /// Distance from top edge of page
  final double top;
  
  /// Width of the rectangle
  final double width;
  
  /// Height of the rectangle
  final double height;
  
  const PdfRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
  
  @override
  String toString() => 'PdfRect(left: $left, top: $top, width: $width, height: $height)';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfRect &&
          runtimeType == other.runtimeType &&
          left == other.left &&
          top == other.top &&
          width == other.width &&
          height == other.height;
  
  @override
  int get hashCode => Object.hash(left, top, width, height);
}

/// How to fit an image within the target rectangle
enum PdfImageFit {
  /// Stretch image to fill rectangle (may distort aspect ratio)
  fill,
  
  /// Scale image to fit inside rectangle (maintains aspect ratio)
  contain,
  
  /// Scale image to cover rectangle (maintains aspect ratio, may crop)
  cover,
}

/// PDF-specific exceptions
class PdfException implements Exception {
  final String message;
  final PdfErrorType type;
  final Object? originalError;
  
  const PdfException(this.message, this.type, [this.originalError]);
  
  @override
  String toString() => 'PdfException($type): $message';
}

/// Types of PDF errors
enum PdfErrorType {
  /// Failed to load PDF (corrupted file, invalid format, etc.)
  loadFailed,
  
  /// Specified form field not found in document
  fieldNotFound,
  
  /// Failed to save PDF
  saveFailed,
  
  /// Document reference is invalid (may have been disposed)
  invalidDocument,
  
  /// Page index out of range
  invalidPageIndex,
  
  /// Failed to insert image
  insertFailed,
}

