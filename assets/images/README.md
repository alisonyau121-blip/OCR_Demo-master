# 测试图片文件夹

## 如何添加图片到项目

### 方法 1: 使用 Windows 文件管理器

1. 打开文件管理器
2. 导航到: `C:\Users\alisonqiu\Documents\Demo_Sample\assets\images\`
3. 将您的图片文件复制到此文件夹
4. 建议的图片命名：
   - `hkid_sample.jpg` - 香港身份证样本
   - `cnid_sample.jpg` - 中国身份证样本
   - `passport_sample.jpg` - 护照样本

### 方法 2: 使用命令行

```powershell
# 复制图片到项目
Copy-Item "C:\path\to\your\image.jpg" "C:\Users\alisonqiu\Documents\Demo_Sample\assets\images\"
```

### 支持的图片格式

- JPG/JPEG
- PNG
- BMP
- GIF

## 使用测试图片

运行应用后，在主页面可以选择 "Use Test Images" 来使用项目中的测试图片。

