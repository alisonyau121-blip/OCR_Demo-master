# PDF Field Mapping Guide

## 🎯 Purpose

This guide helps you map internal PDF field names (like `TextField19`, `Text Field8`) to the actual visible fields in your PDF forms.

---

## 🔍 Enhanced Inspector Features

### **What You Get Now:**

1. **Page Number** - Which page each field is on
2. **Position Coordinates** - Exact location (top, left, bottom, right)
3. **Field Size** - Width and height in pixels
4. **Field Type** - TextBox, CheckBox, etc.
5. **Current Value** - For text fields, shows current content
6. **Organized by Page** - Fields grouped and sorted by page and position

---

## 📊 Console Output Example

When you click "Inspect Form Fields", you'll see detailed output like this:

```
📋 PDF Form Fields Analysis
================================================================================

📍 Field 1: TextField19
   Type: PdfTextBoxField
   Page: 1 of 2
   Position:
     • Top: 125px (from top of page)
     • Left: 50px (from left edge)
     • Bottom: 145px
     • Right: 200px
   Size: 150px × 20px
   Current Value: "(empty)"
   Max Length: 0

📍 Field 2: Name
   Type: PdfTextBoxField
   Page: 2 of 2
   Position:
     • Top: 650px (from top of page)
     • Left: 75px (from left edge)
     • Bottom: 670px
     • Right: 250px
   Size: 175px × 20px
   Current Value: "(empty)"
   Max Length: 0

📍 Field 73: ClientSign
   Type: PdfTextBoxField
   Page: 2 of 2
   Position:
     • Top: 700px (from top of page)
     • Left: 350px (from left edge)
     • Bottom: 750px
     • Right: 500px
   Size: 150px × 50px
   Current Value: "(empty)"
   Max Length: 0

================================================================================
✅ Total fields found: 73
```

---

## 🗺️ Dialog Summary View

The popup dialog shows:

```
Found 73 fields:

📄 PAGE 1:
  1. TextField19
     Position: (50, 125)
  5. EmailAddress
     Position: (50, 200)
  ...

📄 PAGE 2:
  71. Name
     Position: (75, 650)
  73. ClientSign
     Position: (350, 700)
  ...

💡 Check console for complete details with coordinates!
```

---

## 🎯 How to Use This Information

### **Step 1: Run Inspector**
1. Open your app
2. Select the PDF (MINA or CA3) from dropdown
3. Click "Inspect Form Fields"
4. Look at both the dialog AND console output

### **Step 2: Identify Fields by Position**

**For fields at the TOP of page:**
- Low `top` value (e.g., 50-200px)
- These are header fields

**For fields at the BOTTOM of page:**
- High `top` value (e.g., 600-800px)
- These are signature/date fields

**For fields on the LEFT:**
- Low `left` value (e.g., 50-150px)

**For fields on the RIGHT:**
- High `left` value (e.g., 300-500px)

### **Step 3: Cross-Reference with PDF**

Open your CA3.pdf in a viewer and:

1. Look at the signature section (usually bottom of last page)
2. Note visible labels like "Name of First client", "Date", "Signature"
3. Match these with fields that have:
   - Same page number (usually page 2)
   - Similar vertical position (high `top` value)
   - Appropriate horizontal position (`left` value)

---

## 📝 Example Mapping Process

### **Finding "Name of First Client" Field:**

1. **Visual observation**: It's on page 2, bottom left section
2. **Console search**: Look for fields with:
   - `Page: 2`
   - `Top: 600-700px` (bottom area)
   - `Left: 50-150px` (left side)
3. **Match found**: `Field 71: Name`
   ```
   Page: 2
   Top: 650px
   Left: 75px
   ```

### **Finding Date Field Next to Signature:**

1. **Visual**: Next to signature box, shows "dd/mm/yyyy"
2. **Console search**: 
   - Same page as signature field
   - Similar `top` value
   - Different `left` value (further right)
3. **Match found**: `TextField19`
   ```
   Page: 2
   Top: 655px
   Left: 250px
   ```

---

## 🎨 Common CA3 PDF Fields (Reference)

Based on typical CA3 forms, here are likely mappings:

| Visible Label | Likely Field Name | Location |
|--------------|-------------------|----------|
| Name of First client | `Name` or similar | Page 2, Bottom Left |
| Date (Individual) | `TextField*` | Page 2, Bottom |
| Signature (Client) | `ClientSign` | Page 2, Bottom Right |
| Email Address | `EmailAddress` | Page 1, Middle |
| ID Number | `IdNo` | Page 1, Top |
| Mobile Number | `Mobile` | Page 1, Middle |
| Company Name | `CompanyName` | Page 1, Top |
| Adviser Name | `AdviserName` | Page 2, Bottom |
| Adviser Signature | `AdviserSign` | Page 2, Bottom |

*(Use inspector to verify exact names for your PDF)*

---

## 💡 Pro Tips

### **Tip 1: Sort by Page**
Fields are now grouped by page in the dialog, making it easier to locate them.

### **Tip 2: Use Position for Disambiguation**
If you see multiple fields with similar names (like `Text Field8`, `Text Field9`):
- Compare their `top` and `left` values
- Lower `top` = higher on page
- Lower `left` = further left

### **Tip 3: Field Name Patterns**
- `*Sign` = Signature fields
- `*Date` or `Text Field*` near signatures = Date fields
- `*Name` = Name fields
- `*Address*` = Address fields
- `Text Field##` = Generic fields (need position to identify)

### **Tip 4: Check Field Size**
- Large height (50px+) = Signature or multi-line text
- Small height (15-25px) = Single-line input
- Very wide = Address or long text fields

---

## 🚀 Next Steps

After mapping your fields:

1. **Document your findings** - Create a reference list
2. **Update form filling code** - Use correct field names
3. **Test with real data** - Verify fields populate correctly
4. **Share mapping** - Help your team with the field names

---

## 📞 Quick Reference Commands

```dart
// Get field names list
final fields = await PdfFieldInspector.getFormFieldNames('assets/pdfs/CA 3.pdf');

// Get detailed field info
final details = await PdfFieldInspector.getFormFieldDetails('assets/pdfs/CA 3.pdf');

// Fill a specific field
await pdfAdapter.fillTextField(
  document: pdfDoc,
  fieldName: 'ClientSign', // Use exact name from inspector
  value: 'Your Value',
);
```

---

## ✅ Checklist

- [ ] Run inspector on CA3.pdf
- [ ] Note down field names for key fields (Name, Date, Signature)
- [ ] Cross-reference with visual PDF
- [ ] Create your own mapping document
- [ ] Test field filling with discovered names
- [ ] Update form filling logic

Happy mapping! 🎉

