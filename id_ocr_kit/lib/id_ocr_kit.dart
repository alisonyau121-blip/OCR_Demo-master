library id_ocr_kit;


export 'providers/ocr_provider.dart';

/// PDF provider interface and related types
export 'providers/pdf_provider.dart';
export 'src/adapters/mlkit_ocr_adapter.dart';
export 'src/adapters/syncfusion_pdf_adapter.dart';

export 'services/id_recognition_service.dart';

/// PDF form filling service
export 'services/pdf_form_service.dart';

/// ID parser (standalone parsing without OCR)
export 'services/id_parser.dart';

/// ID parsing models (IdParseResult, HkidResult, ChinaIdResult, PassportResult)
export 'models/id_parsers.dart';

/// Signature result model
export 'models/signature_result.dart';



