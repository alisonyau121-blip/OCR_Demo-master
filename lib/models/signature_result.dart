import 'dart:typed_data';

/// Result object containing signature data for future integrations
class SignatureResult {
  /// White background PNG for preview/display
  final Uint8List previewPng;

  /// Transparent background PNG for overlaying on documents
  final Uint8List transparentPng;

  /// Timestamp when the signature was created
  final DateTime timestamp;

  /// Default filename pattern for saving
  String get defaultFilename {
    final dateStr = timestamp.toIso8601String().replaceAll(RegExp(r'[:\-.]'), '');
    return 'signature_$dateStr';
  }

  const SignatureResult({
    required this.previewPng,
    required this.transparentPng,
    required this.timestamp,
  });

  /// Convert to a map for serialization or storage
  Map<String, dynamic> toMap() {
    return {
      'previewPng': previewPng,
      'transparentPng': transparentPng,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create from map
  factory SignatureResult.fromMap(Map<String, dynamic> map) {
    return SignatureResult(
      previewPng: map['previewPng'] as Uint8List,
      transparentPng: map['transparentPng'] as Uint8List,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}

