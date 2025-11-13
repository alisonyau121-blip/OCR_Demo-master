/// ID OCR Test Examples
/// 
/// This file contains example texts for various ID documents to test parsers
library;

import 'id_parsers.dart';

/// Test all examples
void runAllTests() {
  print('=== ID Parser Tests ===\n');
  
  testHkid();
  print('\n${'='*50}\n');
  
  testChinaId();
  print('\n${'='*50}\n');
  
  testPassport();
}

/// HKID Test Examples
void testHkid() {
  print('【Test HKID - Hong Kong Identity Card】\n');
  
  final testCases = [
    'A123456(7)',      // Single letter format
    'AB987654(3)',     // Double letter format
    'Z123456(0)',      // Another example
    'K123456(7)',      // With parentheses
    'A1234567',        // Without parentheses
  ];
  
  for (var testCase in testCases) {
    print('Input text: "$testCase"');
    final result = HkidParser.parse(testCase);
    
    if (result != null) {
      print('✓ Recognition successful!');
      result.fields.forEach((key, value) {
        print('  $key: $value');
      });
    } else {
      print('✗ Not recognized');
    }
    print('');
  }
}

/// China ID Card Test Examples
void testChinaId() {
  print('【Test China ID Card - 18 Digits】\n');
  
  final testCases = [
    '110101199003078515',  // Beijing Dongcheng, 1990-03-07, Male
    '440301198001011234',  // Guangdong Shenzhen, 1980-01-01
    '11010519900307799X',  // Check digit is X
  ];
  
  for (var testCase in testCases) {
    print('Input text: "$testCase"');
    final result = ChinaIdParser.parse(testCase);
    
    if (result != null) {
      print('✓ Recognition successful!');
      result.fields.forEach((key, value) {
        print('  $key: $value');
      });
    } else {
      print('✗ Not recognized');
    }
    print('');
  }
}

/// Passport MRZ Test Examples
void testPassport() {
  print('【Test Passport MRZ TD3 Format】\n');
  
  // Example 1: Chinese Passport
  final mrz1 = '''
P<CHNZHANG<<MING<<<<<<<<<<<<<<<<<<<<<<<<<<<
E123456780CHN8001011M2512314<<<<<<<<<<<<<<08
''';
  
  print('Example 1: Chinese Passport');
  print('Input MRZ:');
  print(mrz1);
  
  var result = PassportMrzParser.parse(mrz1);
  if (result != null) {
    print('✓ Recognition successful!');
    result.fields.forEach((key, value) {
      print('  $key: $value');
    });
  } else {
    print('✗ Not recognized');
  }
  
  print('\n');
  
  // Example 2: US Passport
  final mrz2 = '''
P<USASMITH<<JOHN<DAVID<<<<<<<<<<<<<<<<<<<<
1234567890USA8501011M2812319<<<<<<<<<<<<<<02
''';
  
  print('Example 2: US Passport');
  print('Input MRZ:');
  print(mrz2);
  
  result = PassportMrzParser.parse(mrz2);
  if (result != null) {
    print('✓ Recognition successful!');
    result.fields.forEach((key, value) {
      print('  $key: $value');
    });
  } else {
    print('✗ Not recognized');
  }
}

/// Test mixed text that OCR might return
void testMixedText() {
  print('【Test Mixed Text (Simulating Real OCR Output)】\n');
  
  // Simulate text that OCR might recognize, including various noise
  final ocrText = '''
  Hong Kong Permanent Identity Card
  HONG KONG PERMANENT IDENTITY CARD
  
  Name: CHAN TAI MAN
  Date of Birth: 01-01-1990
  
  A123456(7)
  
  *** THIS IS A SAMPLE ***
  ''';
  
  print('Simulated OCR output text:');
  print(ocrText);
  print('\nTrying to parse...\n');
  
  final results = IdParser.parseAll(ocrText);
  
  if (results.isEmpty) {
    print('✗ No valid ID document found');
  } else {
    print('✓ Found ${results.length} document(s):');
    for (var result in results) {
      print('\nDocument type: ${result.type}');
      print('Validity: ${result.isValid ? "Valid" : "Invalid"}');
      result.fields.forEach((key, value) {
        print('  $key: $value');
      });
    }
  }
}

/// Main function - can run tests directly
void main() {
  runAllTests();
  print('\n${'='*50}\n');
  testMixedText();
}

