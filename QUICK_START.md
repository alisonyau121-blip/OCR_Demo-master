# Quick Start Guide - Flutter OCR App

## 🚀 Get Started in 3 Steps

### Step 1: Install Dependencies
```bash
flutter pub get
```

### Step 2: Choose Your Implementation

#### Option A: Simple OCR (Recommended for beginners)
Rename `lib/simple_main.dart` to `lib/main.dart`

#### Option B: Advanced Scan Page (Already configured)
No changes needed - just run!

### Step 3: Run the App
```bash
flutter run
```

---

## 📱 How to Use the App

1. **Select an image**
   - Tap "Capture Image" to take a photo
   - Tap "Select from Gallery" to choose existing image

2. **Extract text**
   - Tap "Extract with ML Kit" for fast, online OCR
   - Tap "Extract with Tesseract" for offline OCR

3. **Use the text**
   - Select and copy any part of the text
   - Tap "Copy" to copy all text to clipboard
   - Tap "Save" to save as a .txt file (Advanced version only)

---

## 🔑 Key Code Snippets

### Pick Image from Camera or Gallery
```dart
Future<void> _pickImage(ImageSource source) async {
  final pickedFile = await ImagePicker().pickImage(source: source);
  if (pickedFile != null) {
    setState(() {
      _image = File(pickedFile.path);
      extractedText = "";
    });
  }
}
```

### Extract Text with ML Kit
```dart
Future<void> _extractTextMLKit() async {
  if (_image == null) return;
  
  final inputImage = InputImage.fromFile(_image!);
  final textRecognizer = TextRecognizer();
  final recognizedText = await textRecognizer.processImage(inputImage);
  
  setState(() {
    extractedText = recognizedText.text;
  });
  
  textRecognizer.close();
}
```

### Extract Text with Tesseract (Offline)
```dart
Future<void> _extractTextTesseract() async {
  if (_image == null) return;
  
  final text = await TesseractOcr.extractText(_image!.path);
  setState(() {
    extractedText = text;
  });
}
```

### Copy Text to Clipboard
```dart
ElevatedButton(
  onPressed: () {
    Clipboard.setData(ClipboardData(text: extractedText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Text copied!')),
    );
  },
  child: const Text("Copy"),
)
```

---

## 🎯 What You Get

### Simple OCR App (`simple_ocr_page.dart`)
- ✅ 200 lines of clean code
- ✅ Easy to understand and modify
- ✅ All essential features
- ✅ Perfect for learning

### Advanced Scan Page (`scan_page.dart`)
- ✅ 320 lines with advanced features
- ✅ Multiple OCR engines
- ✅ File saving capability
- ✅ Production-ready

---

## 🛠️ Platform Configuration

### Android (already configured)
Check `android/app/src/main/AndroidManifest.xml` for camera permissions.

### iOS
Add camera and photo library permissions to `ios/Runner/Info.plist`

---

## ⚡ Quick Tips

- ML Kit requires **internet connection** on first use (downloads models)
- Tesseract works **completely offline**
- Use **image compression** for large images to avoid crashes
- Test on **real devices** for best results

---

## 📊 Performance Comparison

| Method | Speed | Accuracy | Offline | Languages |
|--------|-------|----------|---------|-----------|
| ML Kit | ⚡⚡⚡ Fast | ⭐⭐⭐ High | ❌ No | Limited |
| Tesseract | ⚡⚡ Medium | ⭐⭐ Good | ✅ Yes | 100+ |

---

## 🎓 Next Steps

1. Run the app and test both OCR methods
2. Try different types of images (printed text, handwriting, etc.)
3. Compare ML Kit vs Tesseract results
4. Customize the UI to match your needs
5. Add language selection for Tesseract
6. Implement text formatting or export features

---

## 💬 Need Help?

Check out:
- Full documentation: `OCR_IMPLEMENTATION_GUIDE.md`
- Code files: `lib/simple_ocr_page.dart` and `lib/scan_page.dart`
- Flutter docs: https://flutter.dev/docs

---

Happy scanning! 📸✨

