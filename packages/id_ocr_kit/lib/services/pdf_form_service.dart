import 'dart:typed_data';
import '../providers/pdf_provider.dart';

/// Service for filling PDF forms with data and signatures
/// 
/// This service provides high-level operations for working with PDF forms:
/// - Filling text fields
/// - Inserting signature images
/// - Combining multiple operations
/// 
/// **Usage:**
/// ```dart
/// final service = PdfFormService(pdfProvider: myPdfProvider);
/// 
/// // Fill form fields
/// final result = await service.fillForm(
///   templatePdf: templateBytes,
///   fieldValues: {
///     'CustomerName': 'John Doe',
///     'CustomerEmail': 'john@example.com',
///   },
/// );
/// 
/// if (result.isSuccess) {
///   await File('filled_form.pdf').writeAsBytes(result.pdfBytes!);
/// }
/// ```
class PdfFormService {
  final PdfProvider _pdfProvider;
  
  /// Creates a new PDF form service
  /// 
  /// [pdfProvider] must be provided by the consumer app to handle
  /// the actual PDF operations (using Syncfusion, pdf package, etc.)
  PdfFormService({required PdfProvider pdfProvider})
      : _pdfProvider = pdfProvider;
  
  /// Fills form fields with provided data
  /// 
  /// [templatePdf] is the source PDF with form fields
  /// [fieldValues] is a map of field names to values
  /// 
  /// Returns [PdfFormResult] containing either:
  /// - Success: filled PDF bytes
  /// - Failure: error message and type
  /// 
  /// This method never throws exceptions - all errors are captured
  /// in the result object.
  /// 
  /// Example:
  /// ```dart
  /// final result = await service.fillForm(
  ///   templatePdf: pdfBytes,
  ///   fieldValues: {
  ///     'Designation': 'Manager',
  ///     'CompanyName': 'ACME Corp',
  ///     'AdviserName': 'Jane Smith',
  ///   },
  /// );
  /// ```
  Future<PdfFormResult> fillForm({
    required Uint8List templatePdf,
    required Map<String, String> fieldValues,
  }) async {
    PdfDocument? document;
    
    try {
      // Load PDF
      document = await _pdfProvider.loadPdf(templatePdf);
      
      // Fill each field
      for (final entry in fieldValues.entries) {
        try {
          await _pdfProvider.fillTextField(
            document: document,
            fieldName: entry.key,
            value: entry.value,
          );
        } on PdfException catch (e) {
          // If field not found, continue with other fields
          // but collect the error for reporting
          if (e.type == PdfErrorType.fieldNotFound) {
            // Could optionally collect missing fields and report them
            continue;
          }
          rethrow;
        }
      }
      
      // Save and return
      final outputBytes = await _pdfProvider.savePdf(document);
      
      return PdfFormResult.success(pdfBytes: outputBytes);
    } on PdfException catch (e) {
      return PdfFormResult.error(
        error: e.message,
        errorType: _mapPdfErrorType(e.type),
      );
    } catch (e) {
      return PdfFormResult.error(
        error: 'Unexpected error: $e',
        errorType: PdfFormErrorType.unexpectedError,
      );
    } finally {
      if (document != null) {
        try {
          await _pdfProvider.dispose(document);
        } catch (_) {
          // Ignore disposal errors
        }
      }
    }
  }
  
  /// Inserts signature images at specified positions
  /// 
  /// [templatePdf] is the source PDF
  /// [signatures] maps field names/identifiers to signature configurations
  /// 
  /// Returns [PdfFormResult] containing either:
  /// - Success: PDF with inserted signatures
  /// - Failure: error message and type
  /// 
  /// Example:
  /// ```dart
  /// final result = await service.insertSignatures(
  ///   templatePdf: pdfBytes,
  ///   signatures: {
  ///     'clientSignature': SignatureInsertConfig(
  ///       pageIndex: 0,
  ///       signatureBytes: clientSignPng,
  ///       rect: PdfRect(left: 100, top: 500, width: 150, height: 50),
  ///     ),
  ///     'adviserSignature': SignatureInsertConfig(
  ///       pageIndex: 0,
  ///       signatureBytes: adviserSignPng,
  ///       rect: PdfRect(left: 300, top: 500, width: 150, height: 50),
  ///     ),
  ///   },
  /// );
  /// ```
  Future<PdfFormResult> insertSignatures({
    required Uint8List templatePdf,
    required Map<String, SignatureInsertConfig> signatures,
  }) async {
    PdfDocument? document;
    
    try {
      // Load PDF
      document = await _pdfProvider.loadPdf(templatePdf);
      
      // Insert each signature
      for (final entry in signatures.entries) {
        final config = entry.value;
        
        // Validate page index
        if (config.pageIndex < 0 || config.pageIndex >= document.pageCount) {
          return PdfFormResult.error(
            error: 'Invalid page index ${config.pageIndex} for signature "${entry.key}"',
            errorType: PdfFormErrorType.invalidPageIndex,
          );
        }
        
        await _pdfProvider.insertImageAtPosition(
          document: document,
          pageIndex: config.pageIndex,
          imageBytes: config.signatureBytes,
          rect: config.rect,
          fit: config.fit,
        );
      }
      
      // Save and return
      final outputBytes = await _pdfProvider.savePdf(document);
      
      return PdfFormResult.success(pdfBytes: outputBytes);
    } on PdfException catch (e) {
      return PdfFormResult.error(
        error: e.message,
        errorType: _mapPdfErrorType(e.type),
      );
    } catch (e) {
      return PdfFormResult.error(
        error: 'Unexpected error: $e',
        errorType: PdfFormErrorType.unexpectedError,
      );
    } finally {
      if (document != null) {
        try {
          await _pdfProvider.dispose(document);
        } catch (_) {
          // Ignore disposal errors
        }
      }
    }
  }
  
  /// Combines filling form fields and inserting signatures in one operation
  /// 
  /// This is a convenience method that performs both operations atomically.
  /// If either operation fails, the entire operation is rolled back.
  /// 
  /// Example:
  /// ```dart
  /// final result = await service.fillFormWithSignatures(
  ///   templatePdf: pdfBytes,
  ///   fieldValues: {'CustomerName': 'John Doe'},
  ///   signatures: {
  ///     'clientSign': SignatureInsertConfig(...),
  ///   },
  /// );
  /// ```
  Future<PdfFormResult> fillFormWithSignatures({
    required Uint8List templatePdf,
    required Map<String, String> fieldValues,
    required Map<String, SignatureInsertConfig> signatures,
  }) async {
    PdfDocument? document;
    
    try {
      // Load PDF
      document = await _pdfProvider.loadPdf(templatePdf);
      
      // Fill text fields
      for (final entry in fieldValues.entries) {
        try {
          await _pdfProvider.fillTextField(
            document: document,
            fieldName: entry.key,
            value: entry.value,
          );
        } on PdfException catch (e) {
          if (e.type == PdfErrorType.fieldNotFound) {
            continue; // Skip missing fields
          }
          rethrow;
        }
      }
      
      // Insert signatures
      for (final entry in signatures.entries) {
        final config = entry.value;
        
        if (config.pageIndex < 0 || config.pageIndex >= document.pageCount) {
          return PdfFormResult.error(
            error: 'Invalid page index ${config.pageIndex}',
            errorType: PdfFormErrorType.invalidPageIndex,
          );
        }
        
        await _pdfProvider.insertImageAtPosition(
          document: document,
          pageIndex: config.pageIndex,
          imageBytes: config.signatureBytes,
          rect: config.rect,
          fit: config.fit,
        );
      }
      
      // Save and return
      final outputBytes = await _pdfProvider.savePdf(document);
      
      return PdfFormResult.success(pdfBytes: outputBytes);
    } on PdfException catch (e) {
      return PdfFormResult.error(
        error: e.message,
        errorType: _mapPdfErrorType(e.type),
      );
    } catch (e) {
      return PdfFormResult.error(
        error: 'Unexpected error: $e',
        errorType: PdfFormErrorType.unexpectedError,
      );
    } finally {
      if (document != null) {
        try {
          await _pdfProvider.dispose(document);
        } catch (_) {
          // Ignore disposal errors
        }
      }
    }
  }
  
  /// Maps PDF provider error types to service error types
  PdfFormErrorType _mapPdfErrorType(PdfErrorType pdfError) {
    switch (pdfError) {
      case PdfErrorType.loadFailed:
        return PdfFormErrorType.loadFailed;
      case PdfErrorType.fieldNotFound:
        return PdfFormErrorType.fieldNotFound;
      case PdfErrorType.saveFailed:
        return PdfFormErrorType.saveFailed;
      case PdfErrorType.invalidDocument:
        return PdfFormErrorType.invalidDocument;
      case PdfErrorType.invalidPageIndex:
        return PdfFormErrorType.invalidPageIndex;
      case PdfErrorType.insertFailed:
        return PdfFormErrorType.insertFailed;
    }
  }
}

/// Configuration for inserting a signature image
class SignatureInsertConfig {
  /// Page index (0-based) where to insert the signature
  final int pageIndex;
  
  /// Signature image as PNG bytes
  final Uint8List signatureBytes;
  
  /// Rectangle defining position and size
  final PdfRect rect;
  
  /// How to fit the image within the rectangle
  final PdfImageFit fit;
  
  const SignatureInsertConfig({
    required this.pageIndex,
    required this.signatureBytes,
    required this.rect,
    this.fit = PdfImageFit.contain,
  });
}

/// Result from PDF form operation
/// 
/// This class uses a nullable pattern to represent success/failure states:
/// - Success: [error] is null, [pdfBytes] contains the output PDF
/// - Failure: [error] is not null, [errorType] indicates the cause
class PdfFormResult {
  /// Output PDF bytes (null if error occurred)
  final Uint8List? pdfBytes;
  
  /// Error message (null if success)
  final String? error;
  
  /// Error type (null if success)
  final PdfFormErrorType? errorType;
  
  const PdfFormResult({
    this.pdfBytes,
    this.error,
    this.errorType,
  });
  
  /// Creates a success result
  factory PdfFormResult.success({required Uint8List pdfBytes}) {
    return PdfFormResult(pdfBytes: pdfBytes);
  }
  
  /// Creates an error result
  factory PdfFormResult.error({
    required String error,
    required PdfFormErrorType errorType,
  }) {
    return PdfFormResult(error: error, errorType: errorType);
  }
  
  /// Returns true if operation succeeded
  bool get isSuccess => error == null;
  
  /// Returns true if operation failed
  bool get isError => error != null;
}

/// Types of errors that can occur during PDF form operations
enum PdfFormErrorType {
  /// Failed to load PDF template
  loadFailed,
  
  /// Form field not found in PDF
  fieldNotFound,
  
  /// Failed to save PDF
  saveFailed,
  
  /// Failed to insert signature image
  insertFailed,
  
  /// Document reference is invalid
  invalidDocument,
  
  /// Page index out of range
  invalidPageIndex,
  
  /// Unexpected error occurred
  unexpectedError,
}
