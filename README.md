# ID OCR Kit

A Flutter package for ID document recognition and PDF form filling with flexible provider pattern design.

[![pub package](https://img.shields.io/pub/v/id_ocr_kit.svg)](https://pub.dev/packages/id_ocr_kit)

## Features

- 🆔 **ID Document Recognition**: Hong Kong ID (HKID), China Resident ID, Passport MRZ (TD3)
- 📄 **PDF Form Filling**: Fill text fields and insert signature images  
- 🔌 **Provider Pattern**: Bring your own OCR/PDF implementation
- ✅ **Built-in Validators**: Checksum validation for all ID types
- 📦 **Reference Implementations**: ML Kit OCR & Syncfusion PDF adapters included
- 🎯 **Zero Lock-in**: Interface-based design allows switching providers

## Supported Documents

| Document Type | Format | Validation |
|--------------|--------|------------|
| Hong Kong ID (HKID) | `A123456(7)` or `AB123456(7)` | MOD 11 checksum |
| China Resident ID | 18-digit with check code | MOD 11-2 checksum |
| Passport MRZ | TD3 (2 lines × 44 chars) | Basic field extraction |

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  id_ocr_kit: ^0.1.0
  
  # Choose your OCR provider
  google_mlkit_text_recognition: ^0.15.0  # Option 1: Google ML Kit
  
  # Choose your PDF provider (optional, for PDF features)
  syncfusion_flutter_pdf: ^31.2.10        # Option 1: Syncfusion
```

## Quick Start

### 1. ID Recognition (OCR + Parsing)

```dart
import 'package:id_ocr_kit/id_ocr_kit.dart';
import 'package:image_picker/image_picker.dart';

// Create OCR provider
final ocrProvider = MlKitOcrAdapter();

// Create ID recognition service
final idService = IdRecognitionService(ocrProvider: ocrProvider);

// Pick image and recognize
final image = await ImagePicker().pickImage(source: ImageSource.camera);
final result = await idService.recognizeId(File(image!.path));

if (result.isSuccess) {
  for (final id in result.parsedIds!) {
    print('Type: ${id.type}');
    print('Valid: ${id.isValid}');
    print('Fields: ${id.fields}');
  }
}

// Clean up
await idService.dispose();
```

### 2. Standalone ID Parsing (No OCR)

If you already have OCR text, you can parse directly:

```dart
import 'package:id_ocr_kit/id_ocr_kit.dart';

// Parse all ID types from text
final parsedIds = IdParser.parseAll(ocrText);

// Or parse specific type
final hkid = HkidParser.parse('A123456(7)');
if (hkid != null && hkid.isValid) {
  print('Valid HKID: ${hkid.fields['ID Number']}');
}
```

### 3. PDF Form Filling

```dart
import 'package:id_ocr_kit/id_ocr_kit.dart';

// Create PDF provider
final pdfProvider = SyncfusionPdfAdapter();
final pdfService = PdfFormService(pdfProvider: pdfProvider);

// Fill form fields
final result = await pdfService.fillForm(
  templatePdf: templateBytes,
  fieldValues: {
    'CustomerName': 'John Doe',
    'IDNumber': 'A123456(7)',
    'DateOfBirth': '1990-01-01',
  },
);

if (result.isSuccess) {
  await File('output.pdf').writeAsBytes(result.pdfBytes!);
}
```

### 4. Insert Signatures into PDF

```dart
final result = await pdfService.insertSignatures(
  templatePdf: pdfBytes,
  signatures: {
    'clientSignature': SignatureInsertConfig(
      pageIndex: 0,
      signatureBytes: signaturePng,
      rect: PdfRect(left: 100, top: 500, width: 150, height: 50),
      fit: PdfImageFit.contain,
    ),
  },
);
```

## Architecture

This package uses the **Provider Pattern** to remain plugin-agnostic:

```
┌─────────────────────────────────────┐
│   Your App                          │
├─────────────────────────────────────┤
│   id_ocr_kit (this package)         │
│   ├── Services (high-level)         │
│   ├── Providers (interfaces)        │
│   └── Models (data structures)      │
├─────────────────────────────────────┤
│   Your Choice of Implementation:    │
│   ├── ML Kit / Tesseract / AWS      │
│   └── Syncfusion / pdf package      │
└─────────────────────────────────────┘
```

### Implementing Your Own Provider

#### Custom OCR Provider

```dart
class MyOcrProvider implements OcrProvider {
  @override
  Future<OcrResult> recognizeText(OcrRequest request) async {
    // Your OCR implementation (Tesseract, AWS Textract, etc.)
    final text = await yourOcrEngine.process(request.imageFile);
    
    return OcrResult(
      text: text,
      lines: text.split('\n'),
      processingTime: Duration(seconds: 1),
    );
  }
  
  @override
  Future<void> dispose() async {
    // Clean up resources
  }
}
```

#### Custom PDF Provider

```dart
class MyPdfProvider implements PdfProvider {
  @override
  Future<PdfDocument> loadPdf(Uint8List bytes) async {
    // Your PDF implementation
  }
  
  @override
  Future<void> fillTextField({
    required PdfDocument document,
    required String fieldName,
    required String value,
  }) async {
    // Fill text field implementation
  }
  
  // Implement other required methods...
}
```

## ID Validation Details

### Hong Kong ID (HKID)
- Format: 1-2 letters + 6 digits + check digit in parentheses
- Example: `A123456(7)` or `AB987654(3)`
- Algorithm: MOD 11 with letter-to-number mapping

### China Resident ID
- Format: 18 digits (6-digit area code + 8-digit DOB + 3-digit sequence + check)
- Example: `110101199001011234`
- Algorithm: MOD 11-2 with weighted sum
- Extracts: Date of birth, Gender (odd=Male, even=Female)

### Passport MRZ (TD3)
- Format: 2 lines × 44 characters, charset [A-Z0-9<]
- Extracts: Country, Name, Passport No., Nationality, DOB, Sex, Expiry

## Example App

See the [example](example/) directory for a complete demo app showing:
- Camera capture
- ID recognition  
- PDF form filling
- Signature capture and insertion

To run the example:

```bash
cd example
flutter run
```

## Platform Support

| Platform | OCR | PDF |
|----------|-----|-----|
| Android  | ✅  | ✅  |
| iOS      | ✅  | ✅  |
| Web      | ⚠️  | ✅  |
| Desktop  | ⚠️  | ✅  |

*Note: OCR support depends on your chosen provider implementation.*

## Dependencies

### Core (Required)
- `flutter` SDK
- `logging: ^1.2.0`

### For Reference Implementations (Optional)
- `google_mlkit_text_recognition: ^0.15.0` (for MlKitOcrAdapter)
- `syncfusion_flutter_pdf: ^31.2.10` (for SyncfusionPdfAdapter)

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Issues

If you encounter any issues, please file them on the [issue tracker](https://github.com/your-org/id_ocr_kit/issues).
