# 📸 Flutter OCR App

A complete Flutter application for scanning images and extracting text using ML Kit and Tesseract OCR engines.

## 🆕 **NEW: ID OCR Demo - 身份证/护照识别**

**完整的证件识别系统已实现！** 支持：
- 🇭🇰 **香港身份证 (HKID)** - 自动校验位验证
- 🇨🇳 **大陆 18 位身份证** - MOD 11-2 校验算法
- 🛂 **护照 MRZ TD3** - 机读区解析（2行×44字符）

**查看完整文档：** [`ID_OCR_README.md`](ID_OCR_README.md)

## ✨ Features

- 📷 **Camera capture** - 相机拍照，自动识别
- 🔍 **Auto OCR** - Google ML Kit 文字识别
- 🆔 **ID Parsing** - 智能解析证件字段
- ✅ **Validation** - 自动校验位验证
- 🎨 **Smart UI** - 绿色(有效) / 红色(无效) / 橙色(未识别)
- 🐛 **Debug mode** - 显示原始 OCR 文本
- 🖼️ **Gallery support** - 也可选择图库图片
- 📋 **Copy & Save** - 复制或保存识别结果

## 🚀 Quick Start

### ⚠️ Flutter PATH Issue Fix

Your Flutter is installed at `C:\flutter` but not in PATH. Choose one option:

#### Option 1: Use Helper Scripts (Easiest)

```powershell
# PowerShell (Recommended)
.\flutter-run.ps1 run

# Or Command Prompt
flutter-run.bat run
```

#### Option 2: Use Full Path

```powershell
C:\flutter\bin\flutter.bat run
```

#### Option 3: Add to PATH (Permanent)

See detailed instructions in [`SETUP_FLUTTER_PATH.md`](SETUP_FLUTTER_PATH.md)

### 📦 Install Dependencies

Already done! ✅ But if needed:

```powershell
# Using helper script
.\flutter-run.ps1 pub get

# Or full path
C:\flutter\bin\flutter.bat pub get
```

### 🏃 Run the App

```powershell
# Using helper script
.\flutter-run.ps1 run

# Or full path
C:\flutter\bin\flutter.bat run

# Select device when prompted
```

## 📂 Project Structure

```
hello_flutter/
├── lib/
│   ├── main.dart                  # 🆕 ID OCR Demo (Camera + Parser + UI)
│   ├── id_parsers.dart            # 🆕 ID解析器 (HKID/大陆/护照)
│   ├── id_test_examples.dart      # 🆕 测试示例和用例
│   ├── scan_page.dart             # Advanced OCR page (320 lines)
│   ├── simple_main.dart           # Simple entry point
│   └── simple_ocr_page.dart       # Simple OCR app (200 lines)
├── ID_OCR_README.md               # 🆕 ID OCR 完整文档
├── COMMANDS.md                    # 🆕 快速命令参考
├── OCR_IMPLEMENTATION_GUIDE.md    # Full documentation
├── QUICK_START.md                 # Quick reference
├── SETUP_FLUTTER_PATH.md          # Flutter PATH setup guide
├── flutter-run.ps1                # PowerShell helper script
├── flutter-run.bat                # Batch helper script
└── README.md                      # This file
```

## 🆔 ID OCR Implementation

**主应用 (`main.dart`) 现在是一个完整的证件识别系统！**

### 支持的证件类型

1. **🇭🇰 香港身份证 (HKID)**
   ```
   格式示例: A123456(7), AB987654(3)
   ✓ 单/双字母前缀自动识别
   ✓ 校验位算法验证
   ```

2. **🇨🇳 大陆 18 位身份证**
   ```
   格式示例: 110101199003078515
   ✓ 地区码、出生日期、性别提取
   ✓ MOD 11-2 校验算法
   ```

3. **🛂 护照 MRZ (TD3 格式)**
   ```
   两行各 44 字符机读区
   ✓ 护照号、姓名、国籍、日期提取
   ✓ 完整 MRZ 行保留用于验证
   ```

### 使用流程

1. **拍照** 📷 - 点击相机按钮，对准证件拍照
2. **自动识别** 🔍 - 使用 Google ML Kit 提取文字
3. **智能解析** 🧠 - 自动识别证件类型并提取字段
4. **校验验证** ✅ - 使用官方算法验证证件有效性
5. **查看结果** 📊 - 绿色卡片(有效) / 红色卡片(无效)

### 技术实现

```dart
// OCR 识别
final text = await OcrService().processImage(imageFile);

// 自动解析所有支持的证件类型
final results = IdParser.parseAll(text);

// 查看解析结果
for (var result in results) {
  print('${result.type}: ${result.isValid}');
  print(result.fields);
}
```

**📖 详细文档：** [`ID_OCR_README.md`](ID_OCR_README.md)

---

## 🎯 Three Implementations

### 1. ID OCR Demo (主应用) 🆕
- **File:** `lib/main.dart`
- **Best for:** 证件识别、实名验证、身份核验
- **Features:** 
  - 相机拍照 + 自动 OCR
  - HKID / 大陆身份证 / 护照解析
  - 校验位自动验证
  - 智能 UI（颜色编码状态）
  - 调试模式（查看原始 OCR 文本）

### 2. Simple OCR App
- **File:** `lib/simple_ocr_page.dart`
- **Lines:** ~200
- **Best for:** Learning, prototypes, simple OCR needs
- **Features:** Image picker, ML Kit, Tesseract, Copy

### 2. Advanced Scan Page
- **File:** `lib/scan_page.dart`
- **Lines:** ~320
- **Best for:** Production apps, advanced features
- **Features:** Everything + Save to file, Image compression, Chinese support

## 🛠️ Helper Scripts

### PowerShell Script (`flutter-run.ps1`)

```powershell
# Run app
.\flutter-run.ps1 run

# Check setup
.\flutter-run.ps1 doctor

# List devices
.\flutter-run.ps1 devices

# Show version
.\flutter-run.ps1 --version
```

### Batch Script (`flutter-run.bat`)

```cmd
REM Run app
flutter-run.bat run

REM Check setup
flutter-run.bat doctor
```

## 📱 Platform Support

- ✅ **Android** (requires Android Studio)
- ✅ **iOS** (requires macOS + Xcode)
- ✅ **Windows** (desktop app)
- ✅ **Web** (Chrome)

## 🔧 Dependencies

All dependencies are already configured in `pubspec.yaml`:

```yaml
dependencies:
  google_mlkit_text_recognition: ^0.15.0  # ML Kit OCR
  tesseract_ocr: ^0.4.0                   # Tesseract OCR
  image_picker: ^1.2.0                    # Image selection
  camera: ^0.11.2                         # Camera access
  path_provider: ^2.1.5                   # File operations
  path: ^1.9.1                            # Path utilities
```

## 📖 Documentation

- **[QUICK_START.md](QUICK_START.md)** - Get started in 3 steps
- **[OCR_IMPLEMENTATION_GUIDE.md](OCR_IMPLEMENTATION_GUIDE.md)** - Complete guide
- **[SETUP_FLUTTER_PATH.md](SETUP_FLUTTER_PATH.md)** - Fix Flutter PATH issue

## 🎓 How to Use

1. **Launch the app**
   ```powershell
   .\flutter-run.ps1 run
   ```

2. **Select an image**
   - Tap "Capture Image" 📷
   - Or "Select from Gallery" 🖼️

3. **Extract text**
   - Tap "Extract with ML Kit" ⚡
   - Or "Extract with Tesseract" 🔧

4. **Use the text**
   - Select and copy any part
   - Tap "Copy" for all text 📋
   - Tap "Save" to save as file 💾

## 🔍 Feature Comparison

| Feature | ID OCR Demo 🆕 | Simple OCR | Advanced Scan |
|---------|---------------|-----------|---------------|
| ML Kit OCR | ✅ | ✅ | ✅ |
| Tesseract OCR | ❌ | ✅ | ✅ |
| Camera capture | ✅ | ✅ | ✅ |
| ID parsing | ✅ HKID/CN/Passport | ❌ | ❌ |
| Auto validation | ✅ Check digits | ❌ | ❌ |
| Smart UI | ✅ Color-coded | Basic | Advanced |
| Copy to clipboard | ✅ | ✅ | ✅ |
| Save to file | ❌ | ❌ | ✅ |
| Image compression | ❌ | ❌ | ✅ |
| Debug mode | ✅ OCR text view | ❌ | ❌ |
| Best for | 证件识别 | 学习/原型 | 生产应用 |

## 🐛 Troubleshooting

### Flutter not recognized
- Use helper scripts: `.\flutter-run.ps1`
- Or add to PATH: See `SETUP_FLUTTER_PATH.md`

### No devices found
```powershell
.\flutter-run.ps1 doctor
```

### ML Kit errors
- Check internet connection
- Ensure Google Play Services (Android)

### Tesseract errors
- Works offline
- Check storage space

## 📚 Learning Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [ML Kit Text Recognition](https://developers.google.com/ml-kit/vision/text-recognition)
- [Tesseract OCR](https://github.com/tesseract-ocr/tesseract)
- [Image Picker Package](https://pub.dev/packages/image_picker)

## 💡 Tips

- **ML Kit** for quick, accurate recognition (needs internet)
- **Tesseract** for offline or multi-language support
- **Test on real devices** for best camera performance
- **Check `flutter doctor`** if you encounter issues

## 🤝 Common Commands

| Task | Command |
|------|---------|
| Run app | `.\flutter-run.ps1 run` |
| Check setup | `.\flutter-run.ps1 doctor` |
| List devices | `.\flutter-run.ps1 devices` |
| Clean build | `.\flutter-run.ps1 clean` |
| Install deps | `.\flutter-run.ps1 pub get` |
| Build APK | `.\flutter-run.ps1 build apk` |

## 🎉 Status

### ID OCR Demo 🆕
✅ **相机权限/拍照流程** - 已完成  
✅ **Google ML Kit OCR** - 已集成  
✅ **HKID 解析** - 支持校验位验证  
✅ **大陆身份证解析** - MOD 11-2 算法  
✅ **护照 MRZ 解析** - TD3 格式  
✅ **智能 UI** - Card + ListTile + 颜色编码  
✅ **原始文本调试** - ExpansionTile 展示  
✅ **完整文档** - ID_OCR_README.md  
🚀 **可以开始测试了！**

### General
✅ **Dependencies installed**  
✅ **Code ready**  
✅ **Documentation complete**  
✅ **Helper scripts created**  
✅ **3 complete implementations**  
🚀 **Ready to run!**

## 🚀 Next Steps

### For ID OCR Demo:
1. Run: `.\flutter-run.ps1 run`
2. Take photo of ID card / Passport
3. View auto-parsed results
4. Check validation status
5. Test different document types
6. Read [`ID_OCR_README.md`](ID_OCR_README.md) for details

### For General OCR:
1. Run the app: `.\flutter-run.ps1 run`
2. Test both OCR methods
3. Try different images
4. Customize the UI
5. Add more features!

## 📚 Documentation Index

| File | Description |
|------|-------------|
| [`README.md`](README.md) | 项目总览（你在这里）|
| [`ID_OCR_README.md`](ID_OCR_README.md) | 🆕 ID OCR 完整指南 |
| [`COMMANDS.md`](COMMANDS.md) | 🆕 快速命令参考 |
| [`QUICK_START.md`](QUICK_START.md) | 快速入门指南 |
| [`OCR_IMPLEMENTATION_GUIDE.md`](OCR_IMPLEMENTATION_GUIDE.md) | OCR 实现指南 |
| [`SETUP_FLUTTER_PATH.md`](SETUP_FLUTTER_PATH.md) | Flutter PATH 设置 |

---

Made with ❤️ using Flutter
