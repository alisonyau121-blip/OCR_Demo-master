// INTERNAL IMPLEMENTATION - NOT PART OF PUBLIC API
// This file is in src/ and should not be exported in the main library file.
// 
// This is a reference implementation using Syncfusion Flutter PDF.
// Consumer apps can use this as an example or create their own implementation.

import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:logging/logging.dart';
import '../../providers/pdf_provider.dart';

/// Internal adapter: Syncfusion PDF implementation
/// 
/// This is a reference implementation that wraps Syncfusion Flutter PDF
/// library to conform to the [PdfProvider] interface.
/// 
/// **Not part of public API** - consumers should implement their own
/// [PdfProvider] or copy this implementation to their app.
/// 
/// Features:
/// - Load/save PDF documents
/// - Fill text form fields
/// - Insert images with automatic aspect ratio fitting
/// - Resource management
/// 
/// **Note:** Syncfusion requires a license for commercial use.
class SyncfusionPdfAdapter implements PdfProvider {
  static final _log = Logger('SyncfusionPdfAdapter');
  
  final Map<String, sf.PdfDocument> _documents = {};
  
  @override
  Future<PdfDocument> loadPdf(Uint8List bytes) async {
    try {
      _log.info('Loading PDF document: ${bytes.length} bytes');
      final doc = sf.PdfDocument(inputBytes: bytes);
      final handle = _SyncfusionPdfDocument(doc);
      _documents[handle.id] = doc;
      
      _log.info('PDF loaded: ${doc.pages.count} pages, ID: ${handle.id}');
      return handle;
    } catch (e, st) {
      _log.severe('Failed to load PDF', e, st);
      throw PdfException(
        'Failed to load PDF: $e',
        PdfErrorType.loadFailed,
        e,
      );
    }
  }
  
  @override
  Future<void> insertImageAtPosition({
    required PdfDocument document,
    required int pageIndex,
    required Uint8List imageBytes,
    required PdfRect rect,
    PdfImageFit fit = PdfImageFit.contain,
  }) async {
    final doc = _getDocument(document);
    
    try {
      // Validate page index
      if (pageIndex < 0 || pageIndex >= doc.pages.count) {
        throw PdfException(
          'Page index $pageIndex out of range (0-${doc.pages.count - 1})',
          PdfErrorType.invalidPageIndex,
        );
      }
      
      _log.info('Inserting image at page $pageIndex, rect: $rect');
      
      final page = doc.pages[pageIndex];
      final image = sf.PdfBitmap(imageBytes);
      
      // Calculate fitted rectangle with aspect ratio preservation
      final fittedRect = _calculateFittedRect(
        imageWidth: image.width.toDouble(),
        imageHeight: image.height.toDouble(),
        targetRect: rect,
        fit: fit,
      );
      
      // Draw image on page
      page.graphics.drawImage(
        image,
        sf.Rect.fromLTWH(
          fittedRect.left,
          fittedRect.top,
          fittedRect.width,
          fittedRect.height,
        ),
      );
      
      _log.info('Image inserted at $fittedRect');
    } catch (e, st) {
      if (e is PdfException) rethrow;
      
      _log.severe('Failed to insert image', e, st);
      throw PdfException(
        'Failed to insert image: $e',
        PdfErrorType.insertFailed,
        e,
      );
    }
  }
  
  @override
  Future<void> fillTextField({
    required PdfDocument document,
    required String fieldName,
    required String value,
  }) async {
    final doc = _getDocument(document);
    
    try {
      _log.info('Filling text field "$fieldName" with value: $value');
      
      final form = doc.form;
      bool found = false;
      
      for (int i = 0; i < form.fields.count; i++) {
        final field = form.fields[i];
        
        if (field.name == fieldName) {
          if (field is sf.PdfTextBoxField) {
            field.text = value;
            found = true;
            _log.info('Field "$fieldName" filled successfully');
            break;
          } else {
            throw PdfException(
              'Field "$fieldName" is not a text field (type: ${field.runtimeType})',
              PdfErrorType.fieldNotFound,
            );
          }
        }
      }
      
      if (!found) {
        throw PdfException(
          'Text field "$fieldName" not found in PDF',
          PdfErrorType.fieldNotFound,
        );
      }
    } catch (e, st) {
      if (e is PdfException) rethrow;
      
      _log.severe('Failed to fill text field', e, st);
      throw PdfException(
        'Failed to fill text field: $e',
        PdfErrorType.fieldNotFound,
        e,
      );
    }
  }
  
  @override
  Future<Uint8List> savePdf(PdfDocument document) async {
    final doc = _getDocument(document);
    
    try {
      _log.info('Saving PDF document: ${document.id}');
      final bytes = await doc.save();
      final output = Uint8List.fromList(bytes);
      
      _log.info('PDF saved: ${output.length} bytes');
      return output;
    } catch (e, st) {
      _log.severe('Failed to save PDF', e, st);
      throw PdfException(
        'Failed to save PDF: $e',
        PdfErrorType.saveFailed,
        e,
      );
    }
  }
  
  @override
  Future<void> dispose(PdfDocument document) async {
    try {
      _log.info('Disposing PDF document: ${document.id}');
      final doc = _documents.remove(document.id);
      doc?.dispose();
      _log.info('PDF document disposed');
    } catch (e, st) {
      _log.severe('Error disposing PDF document', e, st);
      // Don't throw - disposal errors are not critical
    }
  }
  
  /// Get the underlying Syncfusion document
  sf.PdfDocument _getDocument(PdfDocument handle) {
    final doc = _documents[handle.id];
    if (doc == null) {
      throw const PdfException(
        'Document not found or already disposed',
        PdfErrorType.invalidDocument,
      );
    }
    return doc;
  }
  
  /// Calculate fitted rectangle with aspect ratio preservation
  /// 
  /// This is pure domain logic extracted for testability.
  PdfRect _calculateFittedRect({
    required double imageWidth,
    required double imageHeight,
    required PdfRect targetRect,
    required PdfImageFit fit,
  }) {
    final imageAspect = imageWidth / imageHeight;
    final targetAspect = targetRect.width / targetRect.height;
    
    switch (fit) {
      case PdfImageFit.fill:
        // Stretch to fill - no aspect ratio preservation
        return targetRect;
        
      case PdfImageFit.contain:
        // Fit inside while maintaining aspect ratio
        if (imageAspect > targetAspect) {
          // Image is wider - fit to width
          final height = targetRect.width / imageAspect;
          final offsetY = (targetRect.height - height) / 2;
          return PdfRect(
            left: targetRect.left,
            top: targetRect.top + offsetY,
            width: targetRect.width,
            height: height,
          );
        } else {
          // Image is taller - fit to height
          final width = targetRect.height * imageAspect;
          final offsetX = (targetRect.width - width) / 2;
          return PdfRect(
            left: targetRect.left + offsetX,
            top: targetRect.top,
            width: width,
            height: targetRect.height,
          );
        }
        
      case PdfImageFit.cover:
        // Cover entire area while maintaining aspect ratio (may crop)
        if (imageAspect > targetAspect) {
          // Image is wider - fit to height, crop width
          final width = targetRect.height * imageAspect;
          final offsetX = (targetRect.width - width) / 2;
          return PdfRect(
            left: targetRect.left + offsetX,
            top: targetRect.top,
            width: width,
            height: targetRect.height,
          );
        } else {
          // Image is taller - fit to width, crop height
          final height = targetRect.width / imageAspect;
          final offsetY = (targetRect.height - height) / 2;
          return PdfRect(
            left: targetRect.left,
            top: targetRect.top + offsetY,
            width: targetRect.width,
            height: height,
          );
        }
    }
  }
}

/// Internal PDF document handle for Syncfusion
class _SyncfusionPdfDocument implements PdfDocument {
  final sf.PdfDocument _doc;
  
  @override
  final String id;
  
  _SyncfusionPdfDocument(this._doc) 
      : id = DateTime.now().millisecondsSinceEpoch.toString();
  
  @override
  int get pageCount => _doc.pages.count;
}

