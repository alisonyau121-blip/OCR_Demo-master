# 📸 如何将图片添加到 Demo 项目

## 📁 项目结构

```
Demo_Sample/
├── assets/
│   └── images/          ← 把图片放在这里
│       ├── hkid_sample.jpg
│       ├── cnid_sample.jpg
│       └── passport_sample.jpg
└── ...
```

## 方法 1: 使用 Windows 文件管理器（推荐）

### 步骤：

1. **打开文件管理器**
   - 按 `Win + E` 键

2. **导航到图片文件夹**
   ```
   C:\Users\alisonqiu\Documents\Demo_Sample\assets\images\
   ```

3. **复制您的三张图片**
   - 找到您本地的三张图片
   - 选中它们
   - 右键点击 → 复制（或按 `Ctrl + C`）

4. **粘贴到 assets/images 文件夹**
   - 在 `assets\images` 文件夹中右键
   - 选择 "粘贴"（或按 `Ctrl + V`）

5. **重命名图片（建议）**
   - `hkid_sample.jpg` - 香港身份证样本
   - `cnid_sample.jpg` - 中国身份证样本
   - `passport_sample.jpg` - 护照样本

## 方法 2: 使用 PowerShell 命令

### 打开 PowerShell：
- 在项目文件夹中，按住 `Shift` 并右键点击
- 选择 "在此处打开 PowerShell 窗口"

### 复制单个图片：
```powershell
Copy-Item "C:\您的图片路径\image1.jpg" ".\assets\images\hkid_sample.jpg"
```

### 复制多张图片：
```powershell
# 如果您的三张图片在同一个文件夹
Copy-Item "C:\您的图片文件夹\*" ".\assets\images\"
```

### 示例：
```powershell
# 假设您的图片在桌面
Copy-Item "C:\Users\alisonqiu\Desktop\hkid.jpg" ".\assets\images\hkid_sample.jpg"
Copy-Item "C:\Users\alisonqiu\Desktop\cnid.jpg" ".\assets\images\cnid_sample.jpg"
Copy-Item "C:\Users\alisonqiu\Desktop\passport.jpg" ".\assets\images\passport_sample.jpg"
```

## 方法 3: 使用拖放（Drag & Drop）

1. 打开两个文件管理器窗口
2. 左侧：导航到您的图片位置
3. 右侧：打开 `C:\Users\alisonqiu\Documents\Demo_Sample\assets\images\`
4. 拖动图片从左侧到右侧

## ✅ 验证图片已添加

### 检查文件夹：
```powershell
cd C:\Users\alisonqiu\Documents\Demo_Sample
dir assets\images
```

应该看到您的图片文件。

## 📱 在应用中使用测试图片

1. **运行应用**
   ```bash
   flutter run
   ```

2. **在主页点击 "Use Test Images" 按钮**

3. **选择要测试的图片类型**
   - Hong Kong ID Sample
   - China ID Sample
   - Passport Sample

4. **应用会自动使用 `id_ocr_kit` 识别图片**

## 🖼️ 支持的图片格式

- ✅ JPG / JPEG
- ✅ PNG
- ✅ BMP
- ✅ GIF

## 📐 建议的图片要求

- **分辨率**: 至少 1280x720 或更高
- **清晰度**: 文字清晰可读
- **格式**: 正面拍摄，无倾斜
- **大小**: 建议 < 5MB

## 🔄 重新加载资源

如果添加图片后应用没有识别到：

1. **停止应用**
   ```bash
   Ctrl + C
   ```

2. **重新运行**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

## 🛠️ 故障排查

### 问题：应用提示 "Failed to load test image"

**解决方法：**
1. 确认图片文件名正确
2. 确认图片在正确的文件夹中
3. 运行 `flutter pub get`
4. 重启应用

### 问题：图片无法识别

**解决方法：**
1. 确保图片清晰
2. 确保 ID 文档在图片中央
3. 尝试更高分辨率的图片

## 📝 快速命令参考

```powershell
# 查看 assets 文件夹内容
dir assets\images

# 复制图片（替换路径）
Copy-Item "源路径" ".\assets\images\新文件名.jpg"

# 删除所有测试图片
Remove-Item ".\assets\images\*.jpg"

# 重新运行应用
flutter clean && flutter pub get && flutter run
```

## 🎯 完整示例

假设您的三张图片在 `D:\TestImages\` 文件夹中：

```powershell
# 1. 导航到项目
cd C:\Users\alisonqiu\Documents\Demo_Sample

# 2. 复制图片
Copy-Item "D:\TestImages\hkid.jpg" ".\assets\images\hkid_sample.jpg"
Copy-Item "D:\TestImages\cnid.jpg" ".\assets\images\cnid_sample.jpg"
Copy-Item "D:\TestImages\passport.jpg" ".\assets\images\passport_sample.jpg"

# 3. 验证
dir assets\images

# 4. 运行应用
flutter run
```

---

**需要帮助？** 确保您的图片文件路径正确，并且文件扩展名是 `.jpg`、`.jpeg` 或 `.png`。

