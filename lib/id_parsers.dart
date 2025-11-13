// ID Parsers: HKID, China ID Card, Passport MRZ

/// Base class for parse results
abstract class IdParseResult {
  final String type;
  final Map<String, String> fields;
  final bool isValid;
  
  IdParseResult({
    required this.type,
    required this.fields,
    required this.isValid,
  });
}

/// HKID (Hong Kong ID Card) parse result
class HkidResult extends IdParseResult {
  HkidResult({
    required super.fields,
    required super.isValid,
  }) : super(type: 'HKID - Hong Kong ID Card');
}

/// China ID Card parse result
class ChinaIdResult extends IdParseResult {
  ChinaIdResult({
    required super.fields,
    required super.isValid,
  }) : super(type: 'China ID Card');
}

/// Passport MRZ parse result
class PassportResult extends IdParseResult {
  PassportResult({
    required super.fields,
    required super.isValid,
  }) : super(type: 'Passport');
}

/// Unified ID parser interface
class IdParser {
  /// Try to parse all types of IDs
  static List<IdParseResult> parseAll(String text) {
    final results = <IdParseResult>[];
    
    // Try HKID
    final hkid = HkidParser.parse(text);
    if (hkid != null) results.add(hkid);
    
    // Try China ID Card
    final chinaId = ChinaIdParser.parse(text);
    if (chinaId != null) results.add(chinaId);
    
    // Try Passport MRZ
    final passport = PassportMrzParser.parse(text);
    if (passport != null) results.add(passport);
    
    return results;
  }
}

/// HKID (Hong Kong ID Card) Parser
class HkidParser {
  // HKID format: A123456(7) or AB987654(3)
  static final RegExp _hkidPattern = RegExp(
    r'([A-Z]{1,2})(\d{6})\s*\(([0-9A])\)',
    caseSensitive: true,
  );
  
  // Also match format without parentheses: A1234567
  static final RegExp _hkidSimplePattern = RegExp(
    r'([A-Z]{1,2})(\d{6})([0-9A])',
    caseSensitive: true,
  );
  
  static HkidResult? parse(String text) {
    // Try format with parentheses first
    var match = _hkidPattern.firstMatch(text);
    match ??= _hkidSimplePattern.firstMatch(text);
    
    if (match == null) return null;
    
    final letters = match.group(1)!;
    final digits = match.group(2)!;
    final checkDigit = match.group(3)!;
    
    final fullId = '$letters$digits$checkDigit';
    final isValid = validateHkid(letters, digits, checkDigit);
    
    return HkidResult(
      fields: {
        'ID Number': fullId,
        'Letter Prefix': letters,
        'Digits': digits,
        'Check Digit': checkDigit,
        'Validation': isValid ? '✓ Valid' : '✗ Invalid',
      },
      isValid: isValid,
    );
  }
  
  /// HKID check digit algorithm
  static bool validateHkid(String letters, String digits, String checkDigit) {
    try {
      // Convert letters to numbers
      final letterValues = <int>[];
      for (var i = 0; i < letters.length; i++) {
        letterValues.add(letters.codeUnitAt(i) - 'A'.codeUnitAt(0) + 10);
      }
      
      // If only one letter, prepend 36 (weight for space)
      if (letterValues.length == 1) {
        letterValues.insert(0, 36);
      }
      
      // Calculate weighted sum
      var sum = letterValues[0] * 9 + letterValues[1] * 8;
      for (var i = 0; i < 6; i++) {
        sum += int.parse(digits[i]) * (7 - i);
      }
      
      // Calculate check digit
      final remainder = sum % 11;
      final expected = remainder == 0 ? '0' : 
                      remainder == 1 ? 'A' : 
                      (11 - remainder).toString();
      
      return checkDigit == expected;
    } catch (e) {
      return false;
    }
  }
}

/// China 18-digit ID Card Parser
class ChinaIdParser {
  static final RegExp _chinaIdPattern = RegExp(
    r'\b(\d{6})(\d{4})(\d{2})(\d{2})(\d{3})([0-9Xx])\b',
  );
  
  static ChinaIdResult? parse(String text) {
    final match = _chinaIdPattern.firstMatch(text);
    if (match == null) return null;
    
    final areaCode = match.group(1)!;
    final year = match.group(2)!;
    final month = match.group(3)!;
    final day = match.group(4)!;
    final sequence = match.group(5)!;
    final checkDigit = match.group(6)!.toUpperCase();
    
    final fullId = '$areaCode$year$month$day$sequence$checkDigit';
    final isValid = validateChinaId(fullId);
    
    // Gender determination (last digit of sequence)
    final sequenceLastDigit = int.parse(sequence[2]);
    final gender = sequenceLastDigit % 2 == 0 ? 'Female' : 'Male';
    
    return ChinaIdResult(
      fields: {
        'ID Number': fullId,
        'Area Code': areaCode,
        'Date of Birth': '$year-$month-$day',
        'Gender': gender,
        'Sequence': sequence,
        'Check Digit': checkDigit,
        'Validation': isValid ? '✓ Valid' : '✗ Invalid',
      },
      isValid: isValid,
    );
  }
  
  /// 18-digit ID Card validation algorithm (MOD 11-2)
  static bool validateChinaId(String id) {
    if (id.length != 18) return false;
    
    try {
      // Weight factors
      const weights = [7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2];
      // Check codes
      const checkCodes = ['1', '0', 'X', '9', '8', '7', '6', '5', '4', '3', '2'];
      
      var sum = 0;
      for (var i = 0; i < 17; i++) {
        sum += int.parse(id[i]) * weights[i];
      }
      
      final checkIndex = sum % 11;
      final expectedCheck = checkCodes[checkIndex];
      
      return id[17].toUpperCase() == expectedCheck;
    } catch (e) {
      return false;
    }
  }
}

/// Passport MRZ TD3 Format Parser (2 lines × 44 characters each)
class PassportMrzParser {
  static PassportResult? parse(String text) {
    // Preprocessing: remove whitespace, split by lines
    final lines = text.split('\n')
        .map((line) => line.trim().replaceAll(' ', ''))
        .where((line) => line.isNotEmpty)
        .toList();
    
    // Find two consecutive lines, each around 44 characters and starting with P< or containing many < symbols
    for (var i = 0; i < lines.length - 1; i++) {
      final line1 = lines[i];
      final line2 = lines[i + 1];
      
      // TD3 format detection
      if (_isTd3Line(line1) && _isTd3Line(line2)) {
        return _parseTd3(line1, line2);
      }
    }
    
    return null;
  }
  
  static bool _isTd3Line(String line) {
    // TD3 each line should be 44 characters, allow ±3 characters margin
    if (line.length < 40 || line.length > 50) return false;
    
    // Should contain multiple < symbols (MRZ filler character)
    final lessThanCount = '<'.allMatches(line).length;
    if (lessThanCount < 2) return false;
    
    // Should mainly consist of uppercase letters, digits, and <
    final validChars = RegExp(r'^[A-Z0-9<]+$');
    return validChars.hasMatch(line);
  }
  
  static PassportResult? _parseTd3(String line1, String line2) {
    try {
      // Ensure length
      final l1 = line1.padRight(44, '<').substring(0, 44);
      final l2 = line2.padRight(44, '<').substring(0, 44);
      
      // Line 1: P<CountryCodeName
      final docType = l1[0]; // Should be 'P'
      if (docType != 'P') return null;
      
      final countryCode = l1.substring(2, 5).replaceAll('<', '');
      final nameField = l1.substring(5, 44).replaceAll('<', ' ').trim();
      
      // Name format: Surname<<GivenNames
      final nameParts = nameField.split(RegExp(r'\s{2,}'));
      final surname = nameParts.isNotEmpty ? nameParts[0] : '';
      final givenNames = nameParts.length > 1 ? nameParts[1] : '';
      
      // Line 2: PassportNo<<Nationality BirthDate Sex ExpiryDate OptionalData
      final passportNo = l2.substring(0, 9).replaceAll('<', '').trim();
      final passportCheck = l2[9];
      final nationality = l2.substring(10, 13).replaceAll('<', '');
      final birthDate = l2.substring(13, 19); // YYMMDD
      final birthCheck = l2[19];
      final sex = l2[20]; // M/F
      final expiryDate = l2.substring(21, 27); // YYMMDD
      final expiryCheck = l2[27];
      final optionalData = l2.substring(28, 42).replaceAll('<', '').trim();
      final finalCheck = l2[43];
      
      // Format dates
      final formattedBirth = _formatMrzDate(birthDate);
      final formattedExpiry = _formatMrzDate(expiryDate);
      final sexFull = sex == 'M' ? 'Male' : sex == 'F' ? 'Female' : sex;
      
      // Simple validation (in real scenarios, should do complete check digit validation)
      final isValid = passportNo.isNotEmpty && 
                      birthDate.length == 6 && 
                      expiryDate.length == 6;
      
      return PassportResult(
        fields: {
          'Document Type': 'P - Passport',
          'Country Code': countryCode,
          'Surname': surname,
          'Given Names': givenNames,
          'Passport No': passportNo,
          'Nationality': nationality,
          'Date of Birth': formattedBirth,
          'Sex': sexFull,
          'Expiry Date': formattedExpiry,
          if (optionalData.isNotEmpty) 'Optional Data': optionalData,
          'MRZ Line 1': l1,
          'MRZ Line 2': l2,
        },
        isValid: isValid,
      );
    } catch (e) {
      return null;
    }
  }
  
  static String _formatMrzDate(String mrzDate) {
    if (mrzDate.length != 6) return mrzDate;
    
    try {
      var year = int.parse(mrzDate.substring(0, 2));
      final month = mrzDate.substring(2, 4);
      final day = mrzDate.substring(4, 6);
      
      // Determine if 2000s or 1900s
      if (year > 50) {
        year += 1900;
      } else {
        year += 2000;
      }
      
      return '$year-$month-$day';
    } catch (e) {
      return mrzDate;
    }
  }
}

