// CORE PROVIDER INTERFACES
// These are the main abstractions that consumer apps must implement
// or use the provided reference implementations

// OCR provider interface and related types
export 'providers/ocr_provider.dart';

// PDF provider interface and related types
export 'providers/pdf_provider.dart';

// REFERENCE IMPLEMENTATIONS (ADAPTERS)
// Ready-to-use implementations of the provider interfaces
// Consumer apps can use these directly or as examples

// Syncfusion PDF adapter (reference implementation)
export 'src/adapters/syncfusion_pdf_adapter.dart';

// HIGH-LEVEL SERVICES
// Business logic services that combine providers with domain logic

// ID recognition service (OCR + parsing)
export 'services/id_recognition_service.dart';

// PDF form filling service
export 'services/pdf_form_service.dart';

// ID parser (standalone parsing without OCR)
export 'services/id_parser.dart';

// DOMAIN MODELS
// Data structures representing ID documents and their parse results

// ID parsing models (IdParseResult, HkidResult, ChinaIdResult, PassportResult)
export 'models/id_parsers.dart';

// Signature result model (for future PDF signature integration)
export 'models/signature_result.dart';

