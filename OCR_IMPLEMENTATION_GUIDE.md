# Flutter OCR Implementation Guide

This project contains **two complete OCR implementations** for scanning and converting images to text.

## 📦 Implementations

### 1. **Simple OCR App** (Recommended for beginners)
**Files:** `lib/simple_ocr_page.dart` + `lib/simple_main.dart`

A clean, streamlined implementation with:
- ✅ Image picker (Camera & Gallery)
- ✅ ML Kit text recognition
- ✅ Tesseract OCR (offline)
- ✅ Selectable text display
- ✅ Copy to clipboard
- ✅ Loading states and error handling
- ✅ Simple, easy-to-understand code

**Perfect for:** Learning, quick prototypes, simple OCR needs

### 2. **Advanced Scan Page** (Feature-rich)
**Files:** `lib/scan_page.dart` + `lib/main.dart`

A comprehensive implementation with:
- ✅ All features from Simple OCR
- ✅ Three OCR methods (OcrService, ML Kit, Tesseract)
- ✅ Advanced Chinese text recognition
- ✅ Save extracted text to file
- ✅ Image compression and optimization
- ✅ More robust error handling
- ✅ Professional UI layout

**Perfect for:** Production apps, advanced features, multiple OCR engines

---

## 🚀 How to Run

### Option A: Simple OCR App

1. Open `lib/simple_main.dart`
2. **Rename** `simple_main.dart` to `main.dart` (backup the original if needed)
3. Run the app:
   ```bash
   flutter run
   ```

### Option B: Advanced Scan Page (Current Default)

The project is already configured to use this. Just run:
```bash
flutter run
```

Or import and use `ScanPage` in your navigation:
```dart
import 'package:hello_flutter/scan_page.dart';

// Navigate to scan page
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const ScanPage()),
);
```

---

## 📋 Required Dependencies

All dependencies are already in `pubspec.yaml`:

```yaml
dependencies:
  google_mlkit_text_recognition: ^0.15.0  # ML Kit OCR
  tesseract_ocr: ^0.4.0                   # Tesseract OCR
  image_picker: ^1.2.0                    # Image selection
  camera: ^0.11.2                         # Camera access
  path_provider: ^2.1.5                   # File saving
  path: ^1.9.1                            # Path manipulation
```

Install dependencies:
```bash
flutter pub get
```

---

## 🔧 Platform Setup

### Android

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

### iOS

Add to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan documents</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to select images</string>
```

---

## 📖 Code Examples

### Simple OCR Implementation

```dart
import 'package:hello_flutter/simple_ocr_page.dart';

// Use in your app
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: OCRApp(), // Simple OCR page
    );
  }
}
```

### Using Individual OCR Methods

```dart
// ML Kit (Fast, accurate, online)
Future<void> extractWithMLKit() async {
  final inputImage = InputImage.fromFile(imageFile);
  final textRecognizer = TextRecognizer();
  final recognizedText = await textRecognizer.processImage(inputImage);
  print(recognizedText.text);
  textRecognizer.close();
}

// Tesseract (Offline, versatile)
Future<void> extractWithTesseract() async {
  final text = await TesseractOcr.extractText(imagePath);
  print(text);
}
```

---

## 🎯 Feature Comparison

| Feature | Simple OCR | Advanced Scan Page |
|---------|------------|-------------------|
| ML Kit OCR | ✅ | ✅ |
| Tesseract OCR | ✅ | ✅ |
| Custom OcrService | ❌ | ✅ |
| Chinese text support | ❌ | ✅ |
| Copy to clipboard | ✅ | ✅ |
| Save to file | ❌ | ✅ |
| Image compression | ❌ | ✅ |
| Loading states | ✅ | ✅ |
| Error handling | ✅ | ✅ Enhanced |
| Code complexity | Simple | Advanced |
| Lines of code | ~200 | ~320 |

---

## 🐛 Troubleshooting

### ML Kit not working
- Ensure Google Play Services is installed (Android)
- Check internet connection on first use (downloads ML models)

### Tesseract errors
- Ensure sufficient storage space
- May require language data files for non-English text

### Camera permission denied
- Check platform-specific permissions in AndroidManifest.xml / Info.plist
- Ask user to enable permissions in device settings

### "flutter command not found"
- Install Flutter SDK: https://flutter.dev/docs/get-started/install
- Add Flutter to your PATH environment variable

---

## 📚 Additional Resources

- [ML Kit Text Recognition](https://developers.google.com/ml-kit/vision/text-recognition)
- [Tesseract OCR](https://github.com/tesseract-ocr/tesseract)
- [Flutter Image Picker](https://pub.dev/packages/image_picker)

---

## 🎓 Learning Path

1. **Start with Simple OCR** (`simple_ocr_page.dart`)
   - Understand basic OCR workflow
   - Learn image picker integration
   - Practice with ML Kit and Tesseract

2. **Explore Advanced Features** (`scan_page.dart`)
   - Study file saving implementation
   - Learn about image optimization
   - See production-ready error handling

3. **Customize for Your Needs**
   - Add language selection
   - Implement text formatting
   - Add export options (PDF, etc.)

---

## 💡 Tips

- **Use ML Kit** for quick, accurate text recognition (requires internet)
- **Use Tesseract** for offline scenarios or specific languages
- **Compress images** before processing to avoid out-of-memory errors
- **Always handle errors** gracefully with user-friendly messages
- **Test on real devices** - camera and OCR work differently on emulators

---

Happy coding! 🚀

