# 🚀 快速命令参考

## 运行应用

```powershell
# PowerShell 辅助脚本（推荐）
.\flutter-run.ps1 run

# 批处理文件
flutter-run.bat run

# 完整路径
C:\flutter\bin\flutter.bat run
```

## 常用命令

```powershell
# 检查 Flutter 环境
.\flutter-run.ps1 doctor

# 查看可用设备
.\flutter-run.ps1 devices

# 安装依赖
.\flutter-run.ps1 pub get

# 清理构建
.\flutter-run.ps1 clean

# 查看 Flutter 版本
.\flutter-run.ps1 --version
```

## 测试 ID 解析器

```powershell
# 运行测试示例
.\flutter-run.ps1 run lib/id_test_examples.dart
```

## Android 模拟器

```powershell
# 列出模拟器
C:\Users\%USERNAME%\AppData\Local\Android\Sdk\emulator\emulator.exe -list-avds

# 启动模拟器
C:\Users\%USERNAME%\AppData\Local\Android\Sdk\emulator\emulator.exe -avd [设备名]

# 或通过 Flutter
.\flutter-run.ps1 emulators
.\flutter-run.ps1 emulators --launch [设备名]
```

## 构建应用

```powershell
# Android APK (Debug)
.\flutter-run.ps1 build apk

# Android APK (Release)
.\flutter-run.ps1 build apk --release

# Windows Desktop
.\flutter-run.ps1 build windows

# Web
.\flutter-run.ps1 build web
```

## 调试

```powershell
# 查看日志
.\flutter-run.ps1 logs

# 热重载（在运行时按 'r'）
# 完全重启（在运行时按 'R'）
# 退出（在运行时按 'q'）
```

## 项目管理

```powershell
# 更新依赖
.\flutter-run.ps1 pub upgrade

# 查看过期依赖
.\flutter-run.ps1 pub outdated

# 分析代码
.\flutter-run.ps1 analyze

# 格式化代码
.\flutter-run.ps1 format .
```

## 问题排查

```powershell
# 完整健康检查
.\flutter-run.ps1 doctor -v

# 清理并重新获取依赖
.\flutter-run.ps1 clean
.\flutter-run.ps1 pub get

# 查看设备详情
.\flutter-run.ps1 devices -v
```

## 快捷键（运行时）

| 按键 | 功能 |
|------|------|
| `r` | 热重载（保持状态） |
| `R` | 完全重启 |
| `h` | 显示帮助 |
| `c` | 清空控制台 |
| `q` | 退出 |
| `d` | 分离调试器 |
| `s` | 保存截图 |
| `w` | 调试 Widget 层级 |
| `t` | 调试渲染性能 |

## 项目结构

```
hello_flutter/
├── lib/
│   ├── main.dart              # 主应用（相机 + OCR + UI）
│   ├── id_parsers.dart        # ID 解析器（HKID/大陆/护照）
│   ├── id_test_examples.dart  # 测试示例
│   ├── scan_page.dart         # 高级扫描页面
│   └── simple_ocr_page.dart   # 简单 OCR 页面
├── android/                   # Android 配置
├── ios/                       # iOS 配置
├── pubspec.yaml              # 依赖配置
├── flutter-run.ps1           # PowerShell 辅助脚本
├── flutter-run.bat           # 批处理辅助脚本
├── ID_OCR_README.md          # ID OCR 完整文档
├── QUICK_START.md            # 快速入门
└── README.md                 # 项目说明
```

## 证件测试数据

### HKID 示例
```
A123456(7)
AB987654(3)
Z123456(0)
```

### 大陆身份证示例
```
110101199003078515
440301198001011234
11010519900307799X
```

### 护照 MRZ TD3 示例
```
P<CHNZHANG<<MING<<<<<<<<<<<<<<<<<<<<<<<<<<<
E123456780CHN8001011M2512314<<<<<<<<<<<<<<08
```

## 常见错误解决

### "flutter: command not found"
```powershell
# 使用辅助脚本
.\flutter-run.ps1 run

# 或添加到 PATH（见 SETUP_FLUTTER_PATH.md）
```

### "No devices found"
```powershell
# 检查设备
.\flutter-run.ps1 doctor
.\flutter-run.ps1 devices

# 启动模拟器或连接真机
```

### "Gradle build failed"
```powershell
# 清理并重建
.\flutter-run.ps1 clean
.\flutter-run.ps1 pub get
.\flutter-run.ps1 run
```

### "Camera permission denied"
检查 `android/app/src/main/AndroidManifest.xml` 是否有：
```xml
<uses-permission android:name="android.permission.CAMERA"/>
```

## 下一步

1. ✅ 运行应用：`.\flutter-run.ps1 run`
2. ✅ 拍摄证件照片
3. ✅ 查看识别结果
4. ✅ 测试不同证件类型
5. ✅ 阅读 `ID_OCR_README.md` 了解详细功能

---

**提示：** 所有命令都可以用 `.\flutter-run.ps1` 替换 `flutter`


