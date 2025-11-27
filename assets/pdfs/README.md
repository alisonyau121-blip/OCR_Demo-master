# 测试 PDF 文件夹

## 如何添加 PDF 到项目进行测试

### 方法 1: 使用 Windows 文件管理器（推荐）

1. **打开文件管理器** (`Win + E`)

2. **导航到 PDF 文件夹**:
   ```
   C:\Users\alisonqiu\Documents\Demo_Sample\assets\pdfs\
   ```

3. **复制您的测试 PDF 文件到此文件夹**

4. **建议的文件命名**:
   - `test_id_document.pdf` - 测试身份证文档
   - `sample_form.pdf` - 样本表单
   - `blank_template.pdf` - 空白模板

### 方法 2: 使用 PowerShell 命令

```powershell
# 导航到项目
cd C:\Users\alisonqiu\Documents\Demo_Sample

# 复制 PDF 文件
Copy-Item "C:\path\to\your\file.pdf" ".\assets\pdfs\test_document.pdf"
```

## 应用功能说明

### 真实的 PDF 功能（使用 id_ocr_kit）

1. **Digital Signature** (紫色按钮)
   - ✅ 生成真实的数字签名
   - 使用时间戳和唯一标识符
   - 调用 `id_ocr_kit` 的签名功能

2. **Preview Signed PDF** (橙色按钮)
   - ✅ 打开系统 PDF 查看器
   - 显示生成的 PDF 文档
   - 使用 `open_file` 包

3. **Download Signed PDF** (青色按钮)
   - ✅ PDF 已保存到设备
   - 显示文件保存路径
   - 文件位置: Documents 文件夹

4. **Generate Signed PDF** (靛蓝色按钮)
   - ✅ 使用 `id_ocr_kit` 的 `PdfProvider`
   - 生成包含识别数据的 PDF
   - 如果已签名，创建签名版本

5. **Submit User Form** (绿色按钮)
   - ✅ 使用 `id_ocr_kit` 的 `PdfFormService`
   - 创建表单提交 PDF
   - 保存到 Documents 文件夹

## 生成的 PDF 文件位置

所有生成的 PDF 都会保存在:
```
Windows: C:\Users\alisonqiu\Documents\
Android: /storage/emulated/0/Documents/
iOS: App Documents Directory
```

### 文件命名格式

- `id_document_[timestamp].pdf` - 识别结果文档
- `signed_[timestamp].pdf` - 签名文档
- `form_submission_[timestamp].pdf` - 表单提交

## 支持的 PDF 格式

- ✅ PDF 1.4 及以上版本
- ✅ 文本 PDF
- ✅ 扫描 PDF
- ✅ 多页 PDF

## 使用流程

1. **扫描文档** → 使用 Capture Document 或 Choose from Gallery
2. **应用签名** → 点击 Digital Signature
3. **生成 PDF** → 点击 Generate Signed PDF
4. **预览 PDF** → 点击 Preview Signed PDF
5. **提交表单** → 点击 Submit User Form

## 查看生成的 PDF

### 方法 1: 通过应用
- 点击右上角的文件夹图标 📁
- 查看所有生成的文件路径

### 方法 2: 文件管理器
1. 打开文件管理器
2. 导航到 Documents 文件夹
3. 查找以 `id_document_`, `signed_`, `form_submission_` 开头的文件

### 方法 3: PowerShell
```powershell
# 列出所有生成的 PDF
dir C:\Users\alisonqiu\Documents\*.pdf | Sort-Object LastWriteTime -Descending
```

## 功能技术实现

### 使用的 id_ocr_kit 组件:

1. **PdfProvider** (`DefaultPdfProvider`)
   - `generatePdf(data, signature)` - 生成 PDF
   - `signPdf(file, signature)` - 签名 PDF

2. **PdfFormService**
   - `fillForm(data)` - 填充表单
   - `generateBlankForm()` - 生成空白表单

3. **IdRecognitionService**
   - `recognizeId(imageFile)` - 识别文档
   - 提供数据给 PDF 生成

## 故障排查

### PDF 无法打开

**原因**: 系统没有 PDF 阅读器

**解决方法**:
- Windows: 安装 Adobe Acrobat Reader
- 或使用浏览器打开 PDF

### 找不到生成的 PDF

**解决方法**:
```powershell
# 搜索最近生成的 PDF
dir C:\Users\alisonqiu\Documents\*.pdf | Where-Object {$_.LastWriteTime -gt (Get-Date).AddHours(-1)}
```

### 权限错误

**解决方法**:
- 确保应用有存储权限
- Android: 在设置中授予存储权限

---

**提示**: 所有 PDF 功能都是真实实现，使用 `id_ocr_kit` package 的真实 PDF 生成和处理功能。

