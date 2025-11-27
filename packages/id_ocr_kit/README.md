# ID OCR Kit

A Flutter package for ID document recognition and PDF form filling. Supports Hong Kong ID (HKID), China Resident ID, and Passport MRZ parsing.

## Features

- **ID Document Recognition**: Extract and parse key fields from:
  - Hong Kong ID Card (HKID) with checksum validation
  - China Resident ID (18-digit) with checksum validation
  - Passport Machine Readable Zone (MRZ TD3)

- **PDF Form Filling**: Fill PDF forms and insert signature images
  - Fill text form fields
  - Insert signature images at specific positions
  - Combine text and signature operations

- **Provider Pattern**: Bring your own OCR and PDF implementations
  - OCR: Google ML Kit, Tesseract, AWS Textract, Azure Computer Vision, etc.
  - PDF: Syncfusion, pdf package, pdfium, etc.
  - Reference implementations included (ML Kit + Syncfusion)

## Installation

### As a Local Package

Add to your `pubspec.yaml`:

```yaml
dependencies:
  id_ocr_kit:
    path: packages/id_ocr_kit  # or path to your local package
```

### Required Dependencies

The package requires you to have these in your app's `pubspec.yaml`:

```yaml
dependencies:
  google_mlkit_text_recognition: ^0.14.0  # For OCR (if using MlKitOcrAdapter)
  syncfusion_flutter_pdf: ^31.2.10        # For PDF (if using SyncfusionPdfAdapter)
  path_provider: ^2.1.4
  image_picker: ^1.1.2                     # If you need image capture
```

## Quick Start

### 1. ID Recognition (OCR + Parsing)

```dart
import 'dart:io';
import 'package:id_ocr_kit/id_ocr_kit.dart';

// Create service with ML Kit OCR adapter
final service = IdRecognitionService(
  ocrProvider: MlKitOcrAdapter(),
);

// Recognize ID from image
final result = await service.recognizeId(File('id_card.jpg'));

if (result.isSuccess && result.hasIds) {
  for (final id in result.parsedIds!) {
    print('Found ${id.type}');
    id.fields.forEach((key, value) {
      print('  $key: $value');
    });
  }
} else {
  print('Error: ${result.error}');
}

// Clean up
await service.dispose();
```

### 2. Standalone ID Parsing (Without OCR)

If you already have the text, you can parse IDs directly:

```dart
import 'package:id_ocr_kit/id_ocr_kit.dart';

final text = '''
A1234567
Name: John Doe
...
''';

final parsedIds = IdParser.parseAll(text);

for (final id in parsedIds) {
  print('${id.type}: ${id.isValid ? "Valid" : "Invalid"}');
  id.fields.forEach((key, value) => print('  $key: $value'));
}
```

### 3. PDF Form Filling

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:id_ocr_kit/id_ocr_kit.dart';

// Create service with Syncfusion PDF adapter
final pdfService = PdfFormService(
  pdfProvider: SyncfusionPdfAdapter(),
);

// Load template PDF
final templateBytes = await File('template.pdf').readAsBytes();

// Fill form fields
final result = await pdfService.fillForm(
  templatePdf: templateBytes,
  fieldValues: {
    'CustomerName': 'John Doe',
    'CustomerEmail': 'john@example.com',
    'Date': '2025-11-26',
  },
);

if (result.isSuccess) {
  // Save filled PDF
  await File('filled_form.pdf').writeAsBytes(result.pdfBytes!);
  print('PDF filled successfully!');
} else {
  print('Error: ${result.error}');
}
```

### 4. Insert Signatures into PDF

```dart
// Load signature image
final signatureBytes = await File('signature.png').readAsBytes();

// Insert signature
final result = await pdfService.insertSignatures(
  templatePdf: templateBytes,
  signatures: {
    'clientSignature': SignatureInsertConfig(
      pageIndex: 0,
      signatureBytes: signatureBytes,
      rect: PdfRect(left: 100, top: 500, width: 150, height: 50),
      fit: PdfImageFit.contain,
    ),
  },
);

if (result.isSuccess) {
  await File('signed_form.pdf').writeAsBytes(result.pdfBytes!);
}
```

## Architecture

### Provider Pattern

This package uses the **Provider Pattern** to remain library-agnostic:

```
Your App
    ↓
id_ocr_kit (interfaces + business logic)
    ↓
Your Implementation or Reference Adapters
    ↓
Third-party Libraries (ML Kit, Syncfusion, etc.)
```

### Reference Implementations

The package includes ready-to-use adapters:

- **MlKitOcrAdapter**: Uses Google ML Kit for OCR
- **SyncfusionPdfAdapter**: Uses Syncfusion Flutter PDF for PDF operations

You can use these directly or create your own implementations.

### Custom Implementations

To use your own OCR or PDF library, implement the interfaces:

```dart
// Custom OCR implementation
class MyOcrProvider implements OcrProvider {
  @override
  Future<OcrResult> recognizeText(OcrRequest request) async {
    // Your OCR implementation here
  }
  
  @override
  Future<void> dispose() async {
    // Cleanup
  }
}

// Custom PDF implementation
class MyPdfProvider implements PdfProvider {
  @override
  Future<PdfDocument> loadPdf(Uint8List bytes) async {
    // Your PDF loading implementation
  }
  
  // ... implement other methods
}
```

## Supported ID Formats

### Hong Kong ID (HKID)

- Format: `A123456(7)` or `AB987654(3)`
- Validates checksum using Mod 11 algorithm
- Extracts: Letter prefix, digits, check digit

### China Resident ID

- Format: 18-digit number (e.g., `110101199001011234`)
- Validates checksum using MOD 11-2 algorithm
- Extracts: Area code, date of birth, gender, check digit

### Passport MRZ (TD3)

- Format: 2 lines × 44 characters (Machine Readable Zone)
- Extracts: Issuing country, name, passport number, nationality, DOB, sex, expiry date

## API Reference

### Core Services

- `IdRecognitionService`: High-level service for ID recognition (OCR + parsing)
- `PdfFormService`: High-level service for PDF form operations
- `IdParser`: Standalone parser for ID documents (no OCR)

### Provider Interfaces

- `OcrProvider`: Abstract interface for OCR implementations
- `PdfProvider`: Abstract interface for PDF implementations

### Models

- `IdParseResult`: Base class for parsed ID results
- `HkidResult`: Hong Kong ID parse result
- `ChinaIdResult`: China ID parse result
- `PassportResult`: Passport MRZ parse result
- `SignatureResult`: Signature data container

## Example App

See the `example` folder (if included) or the Demo_Sample app for complete working examples.

## License

This package is private and not published to pub.dev.

## Support

For issues or questions, contact your development team.

