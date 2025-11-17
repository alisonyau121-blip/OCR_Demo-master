import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// On-device PDF service for inserting signatures into form fields
class PdfApiService {
  static final _log = Logger('PdfApiService');
  
  /// Load PDF template from assets
  Future<Uint8List> loadPdfFromAssets() async {
    try {
      _log.info('Loading PDF template from assets');
      final ByteData data = await rootBundle.load('assets/pdfs/MINA 1 (1).pdf');
      final Uint8List bytes = data.buffer.asUint8List();
      _log.info('PDF template loaded: ${bytes.length} bytes');
      return bytes;
    } catch (e, st) {
      _log.severe('Failed to load PDF template', e, st);
      rethrow;
    }
  }
  
  /// Insert signatures into PDF form fields
  Future<Uint8List> insertSignaturesToPdf({
    required Uint8List clientSignaturePng,
    required Uint8List adviserSignaturePng,
  }) async {
    try {
      _log.info('Starting PDF signature insertion');
      
      // Load PDF from assets
      final pdfBytes = await loadPdfFromAssets();
      
      // Load PDF document
      final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
      _log.info('PDF document loaded, pages: ${document.pages.count}');
      
      // Get form fields
      final PdfForm form = document.form;
      _log.info('Form fields count: ${form.fields.count}');
      
      // Find and insert signatures
      bool clientFound = false;
      bool adviserFound = false;
      
      for (int i = 0; i < form.fields.count; i++) {
        final PdfField field = form.fields[i];
        _log.fine('Field $i: ${field.name} (${field.runtimeType})');
        
        if (field.name == 'ClientSign') {
          _log.info('Found ClientSign field at index $i');
          _insertSignatureAtField(document, field, clientSignaturePng);
          clientFound = true;
        } else if (field.name == 'AdviserSign') {
          _log.info('Found AdviserSign field at index $i');
          _insertSignatureAtField(document, field, adviserSignaturePng);
          adviserFound = true;
        }
      }
      
      if (!clientFound) {
        _log.warning('ClientSign field not found in PDF');
      }
      if (!adviserFound) {
        _log.warning('AdviserSign field not found in PDF');
      }
      
      // Save and return PDF bytes
      final List<int> savedBytes = await document.save();
      document.dispose();
      
      _log.info('PDF generated successfully: ${savedBytes.length} bytes');
      return Uint8List.fromList(savedBytes);
    } catch (e, st) {
      _log.severe('Failed to insert signatures into PDF', e, st);
      rethrow;
    }
  }
  
  /// Insert signature image at form field location
  void _insertSignatureAtField(
    PdfDocument document,
    PdfField field,
    Uint8List signaturePng,
  ) {
    try {
      // Get field bounds (position and size)
      final Rect bounds = field.bounds;
      _log.info('Field bounds: ${bounds.left}, ${bounds.top}, ${bounds.width}, ${bounds.height}');
      
      // Get the page where the field is located
      final PdfPage page = field.page!;
      
      // Create bitmap from PNG bytes
      final PdfBitmap image = PdfBitmap(signaturePng);
      
      // Calculate aspect ratio to maintain proportions
      final double imageAspect = image.width / image.height;
      final double fieldAspect = bounds.width / bounds.height;
      
      double drawWidth = bounds.width;
      double drawHeight = bounds.height;
      double offsetX = 0;
      double offsetY = 0;
      
      // Fit image within bounds while maintaining aspect ratio
      if (imageAspect > fieldAspect) {
        // Image is wider than field
        drawHeight = bounds.width / imageAspect;
        offsetY = (bounds.height - drawHeight) / 2;
      } else {
        // Image is taller than field
        drawWidth = bounds.height * imageAspect;
        offsetX = (bounds.width - drawWidth) / 2;
      }
      
      // Draw signature image on page
      page.graphics.drawImage(
        image,
        Rect.fromLTWH(
          bounds.left + offsetX,
          bounds.top + offsetY,
          drawWidth,
          drawHeight,
        ),
      );
      
      _log.info('Signature inserted at (${bounds.left + offsetX}, ${bounds.top + offsetY}) with size ${drawWidth}x${drawHeight}');
    } catch (e, st) {
      _log.severe('Failed to insert signature at field', e, st);
      rethrow;
    }
  }
  
  /// Save PDF to device Downloads folder
  Future<String> savePdfToDevice(Uint8List pdfBytes) async {
    try {
      _log.info('Saving PDF to device');
      
      // Get downloads directory
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          downloadsDir = await getExternalStorageDirectory();
        }
      } else {
        downloadsDir = await getApplicationDocumentsDirectory();
      }
      
      if (downloadsDir == null) {
        throw Exception('Could not access downloads directory');
      }
      
      // Generate filename with timestamp
      final String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final String fileName = 'signed_form_$timestamp.pdf';
      final String filePath = '${downloadsDir.path}/$fileName';
      
      // Write file
      final File file = File(filePath);
      await file.writeAsBytes(pdfBytes);
      
      _log.info('PDF saved to: $filePath');
      return filePath;
    } catch (e, st) {
      _log.severe('Failed to save PDF', e, st);
      rethrow;
    }
  }
}

