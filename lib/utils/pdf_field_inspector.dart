import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Utility class to inspect PDF form fields for debugging
class PdfFieldInspector {
  /// Get all form field names from a PDF asset with detailed position information
  static Future<List<String>> getFormFieldNames(String assetPath) async {
    try {
      // Load PDF from assets
      final ByteData data = await rootBundle.load(assetPath);
      final List<int> bytes = data.buffer.asUint8List();
      
      // Load PDF document
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      
      // Get form fields
      final PdfForm? form = document.form;
      final List<String> fieldNames = [];
      
      if (form != null && form.fields.count > 0) {
        print('\n📋 PDF Form Fields Analysis');
        print('=' * 80);
        
        for (int i = 0; i < form.fields.count; i++) {
          final field = form.fields[i];
          if (field.name != null) {
            fieldNames.add(field.name!);
            
            // Get field position and page info
            final page = field.page;
            if (page == null) {
              print('⚠️ Field has no page information, skipping position details');
              continue;
            }
            
            final pageIndex = document.pages.indexOf(page) + 1;
            final bounds = field.bounds;
            
            // Enhanced console output with position details
            print('\n📍 Field ${i + 1}: ${field.name}');
            print('   Type: ${field.runtimeType}');
            print('   Page: $pageIndex of ${document.pages.count}');
            print('   Position:');
            print('     • Top: ${bounds.top.toInt()}px (from top of page)');
            print('     • Left: ${bounds.left.toInt()}px (from left edge)');
            print('     • Bottom: ${bounds.bottom.toInt()}px');
            print('     • Right: ${bounds.right.toInt()}px');
            print('   Size: ${bounds.width.toInt()}px × ${bounds.height.toInt()}px');
            
            // Add value info if available
            if (field is PdfTextBoxField) {
              print('   Current Value: "${field.text ?? "(empty)"}"');
              print('   Max Length: ${field.maxLength}');
            } else if (field is PdfCheckBoxField) {
              print('   Checked: ${field.isChecked}');
            }
          }
        }
        
        print('\n' + '=' * 80);
        print('✅ Total fields found: ${fieldNames.length}\n');
      } else {
        print('⚠️ No form fields found in PDF');
      }
      
      // Dispose document
      document.dispose();
      
      return fieldNames;
    } catch (e) {
      print('❌ Error inspecting PDF fields: $e');
      rethrow;
    }
  }
  
  /// Get detailed field information as structured data
  static Future<List<Map<String, dynamic>>> getFormFieldDetails(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final List<int> bytes = data.buffer.asUint8List();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      
      final List<Map<String, dynamic>> fieldDetails = [];
      final PdfForm? form = document.form;
      
      if (form != null && form.fields.count > 0) {
        for (int i = 0; i < form.fields.count; i++) {
          final field = form.fields[i];
          
          if (field.name != null) {
            final page = field.page;
            if (page == null) continue; // Skip fields without page info
            
            final pageIndex = document.pages.indexOf(page) + 1;
            final bounds = field.bounds;
            
            fieldDetails.add({
              'index': i + 1,
              'name': field.name!,
              'type': field.runtimeType.toString(),
              'page': pageIndex,
              'totalPages': document.pages.count,
              'top': bounds.top.toInt(),
              'left': bounds.left.toInt(),
              'bottom': bounds.bottom.toInt(),
              'right': bounds.right.toInt(),
              'width': bounds.width.toInt(),
              'height': bounds.height.toInt(),
            });
          }
        }
      }
      
      document.dispose();
      return fieldDetails;
    } catch (e) {
      print('Error getting field details: $e');
      rethrow;
    }
  }
}

