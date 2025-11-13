# Fix Flutter PATH Issue on Windows

## ✅ Current Status
- Flutter **IS INSTALLED** at: `C:\flutter`
- Dependencies **ARE INSTALLED** (flutter pub get completed successfully)
- Issue: Flutter is not in your system PATH

---

## 🚀 Quick Solutions

### Option 1: Use Full Path (Temporary - No Setup Needed)

Use the full path to Flutter commands:

```powershell
# Install dependencies
C:\flutter\bin\flutter.bat pub get

# Run the app
C:\flutter\bin\flutter.bat run

# Check Flutter status
C:\flutter\bin\flutter.bat doctor

# Build APK
C:\flutter\bin\flutter.bat build apk
```

**Pros:** Works immediately, no system changes needed
**Cons:** Must type full path every time

---

### Option 2: Add Flutter to PATH (Permanent - Recommended)

This makes `flutter` command work from anywhere.

#### Step-by-Step Instructions:

1. **Open System Environment Variables**
   - Press `Win + X`
   - Click "System"
   - Click "Advanced system settings" (on the right)
   - Click "Environment Variables..." button

2. **Edit PATH Variable**
   - In "User variables" section, find and select `Path`
   - Click "Edit..."
   - Click "New"
   - Add this line: `C:\flutter\bin`
   - Click "OK" on all windows

3. **Restart Your Terminal**
   - Close all PowerShell/Command Prompt windows
   - Open a new PowerShell window
   - Test: `flutter --version`

4. **Verify Installation**
   ```powershell
   flutter doctor
   ```

---

### Option 3: Use PowerShell Alias (Session-based)

Add alias for current PowerShell session:

```powershell
Set-Alias flutter C:\flutter\bin\flutter.bat
```

To make it permanent, add to your PowerShell profile:

```powershell
# Check if profile exists
Test-Path $PROFILE

# Create profile if it doesn't exist
New-Item -Path $PROFILE -Type File -Force

# Edit profile
notepad $PROFILE

# Add this line to the profile:
Set-Alias flutter C:\flutter\bin\flutter.bat
```

---

### Option 4: Use IDE (No Terminal Commands Needed)

If you're using **Visual Studio Code** or **Android Studio**:

1. **Visual Studio Code:**
   - Install "Flutter" extension
   - Open Command Palette (`Ctrl+Shift+P`)
   - Type "Flutter: Run Flutter Doctor"
   - Use "Flutter: Launch Emulator" or "Flutter: Run Without Debugging"

2. **Android Studio:**
   - Flutter plugin should auto-detect Flutter SDK at `C:\flutter`
   - Use the Run/Debug buttons in the toolbar
   - No terminal commands needed!

---

## 🏃 How to Run Your OCR App Now

### Using Full Path (Works immediately):

```powershell
# Navigate to your project (if not already there)
cd C:\Users\alisonqiu\hello_flutter

# Run the app
C:\flutter\bin\flutter.bat run
```

### After Adding to PATH:

```powershell
# Just use the short command
flutter run
```

---

## 📱 Choose Your Device

When you run `flutter run`, you'll see available devices:

```
Multiple devices found:
Windows (desktop) • windows • windows-x64 • Microsoft Windows
Chrome (web)      • chrome  • web-javascript • Google Chrome
...
```

Select a device:
- Type the device number
- Or specify: `flutter run -d windows`
- Or: `flutter run -d chrome`

---

## 🐛 Troubleshooting

### "No devices found"

Run Flutter doctor to check setup:
```powershell
C:\flutter\bin\flutter.bat doctor
```

Common fixes:
- **Android:** Install Android Studio and Android SDK
- **Windows:** Enable Windows Desktop development
- **Web:** Chrome should work by default
- **iOS:** Only works on macOS

### "Unable to locate Android SDK"

1. Install Android Studio
2. Run: `C:\flutter\bin\flutter.bat doctor --android-licenses`
3. Accept all licenses

### Still having PATH issues?

Check current PATH:
```powershell
$env:Path -split ";"
```

Look for `C:\flutter\bin` in the output.

---

## ✅ Verification Checklist

After adding Flutter to PATH, verify:

```powershell
# Should show Flutter version
flutter --version

# Should show SDK path and doctor results
flutter doctor

# Should list available devices
flutter devices

# Should work in your project
cd C:\Users\alisonqiu\hello_flutter
flutter run
```

---

## 📚 Quick Reference

| Command | Full Path | Short (after PATH setup) |
|---------|-----------|-------------------------|
| Check version | `C:\flutter\bin\flutter.bat --version` | `flutter --version` |
| Install deps | `C:\flutter\bin\flutter.bat pub get` | `flutter pub get` |
| Run app | `C:\flutter\bin\flutter.bat run` | `flutter run` |
| Run doctor | `C:\flutter\bin\flutter.bat doctor` | `flutter doctor` |
| Clean build | `C:\flutter\bin\flutter.bat clean` | `flutter clean` |
| Build APK | `C:\flutter\bin\flutter.bat build apk` | `flutter build apk` |

---

## 🎯 Recommended Next Steps

1. ✅ Dependencies are already installed (done!)
2. Choose a solution above (Option 2 recommended)
3. Run `flutter doctor` to check your setup
4. Run `flutter run` to launch your OCR app
5. Test the app with camera and gallery features

---

## 💡 Pro Tips

- **Use an IDE** (VS Code or Android Studio) - they handle Flutter paths automatically
- **Add to PATH permanently** - saves time in the long run
- **Run `flutter doctor`** - tells you exactly what's missing
- **Use `flutter devices`** - shows all available test devices

---

Good luck! Your OCR app is ready to run! 🚀📸

