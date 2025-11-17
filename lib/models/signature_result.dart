import 'dart:typed_data';

/// Result object containing signature data for future integrations
class SignatureResult {
  /// White background PNG for preview/display
  final Uint8List previewPng;

  /// Transparent background PNG for overlaying on documents
  final Uint8List transparentPng;

  /// Timestamp when the signature was created
  final DateTime timestamp;

  /// Role of the signer: "Client" or "Adviser"
  final String role;

  /// Default filename pattern for saving
  String get defaultFilename {
    final dateStr = timestamp.toIso8601String().replaceAll(RegExp(r'[:\-.]'), '');
    final roleStr = role.toLowerCase();
    return 'signature_${roleStr}_$dateStr';
  }

  const SignatureResult({
    required this.previewPng,
    required this.transparentPng,
    required this.timestamp,
    required this.role,
  });

  /// Convert to a map for serialization or storage
  Map<String, dynamic> toMap() {
    return {
      'previewPng': previewPng,
      'transparentPng': transparentPng,
      'timestamp': timestamp.toIso8601String(),
      'role': role,
    };
  }

  /// Create from map
  factory SignatureResult.fromMap(Map<String, dynamic> map) {
    return SignatureResult(
      previewPng: map['previewPng'] as Uint8List,
      transparentPng: map['transparentPng'] as Uint8List,
      timestamp: DateTime.parse(map['timestamp'] as String),
      role: map['role'] as String,
    );
  }
}

