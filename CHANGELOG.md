# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-11-25

### Added
- Initial release of ID OCR Kit
- ID document recognition support:
  - Hong Kong ID (HKID) with MOD 11 checksum validation
  - China Resident ID (18-digit) with MOD 11-2 checksum validation
  - Passport MRZ (TD3 format) parsing
- PDF form filling capabilities:
  - Text field filling
  - Signature image insertion
  - Flexible positioning with PdfRect
- Provider pattern architecture:
  - OcrProvider interface for OCR implementations
  - PdfProvider interface for PDF operations
- Reference implementations:
  - MlKitOcrAdapter (Google ML Kit Text Recognition)
  - SyncfusionPdfAdapter (Syncfusion Flutter PDF)
- High-level services:
  - IdRecognitionService (OCR + parsing)
  - PdfFormService (form filling + signatures)
  - IdParser (standalone parsing without OCR)
- Comprehensive example app demonstrating all features
- Full documentation and API reference

### Features
- Zero lock-in design: easily switch between OCR/PDF providers
- Dual-script OCR support (Latin + Chinese)
- Automatic text deduplication
- Robust error handling with typed exceptions
- Platform-agnostic PDF operations
- Image fitting modes for PDF signatures (fill, contain, cover)

[0.1.0]: https://github.com/your-org/id_ocr_kit/releases/tag/v0.1.0

