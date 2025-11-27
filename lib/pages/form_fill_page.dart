import 'package:flutter/material.dart';
import 'package:id_ocr_kit/id_ocr_kit.dart';

class FormFillPage extends StatefulWidget {
  final Map<String, String>? existingFormData;
  final SignatureResult? existingSignature;
  
  const FormFillPage({
    super.key,
    this.existingFormData,
    this.existingSignature,
  });

  @override
  State<FormFillPage> createState() => _FormFillPageState();
}

class _FormFillPageState extends State<FormFillPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;

  // Form controllers
  final _fullNameController = TextEditingController();
  final _fullNameLocController = TextEditingController();
  final _dayController = TextEditingController();
  final _monthController = TextEditingController();
  final _yearController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _businessNatureController = TextEditingController();
  final _designationController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _hkbrController = TextEditingController();
  final _natureOfBusinessController = TextEditingController();
  final _adviserNameController = TextEditingController();
  final _licenceNoController = TextEditingController();

  // Radio button selections
  String? _gender; // Male or Female
  String? _maritalStatus; // Single, Married, Divorced, Widowed
  String? _educationLevel; // Primary, Vocational, Tertiary, Secondary

  @override
  void initState() {
    super.initState();
    // Load existing form data if available
    if (widget.existingFormData != null) {
      _fullNameController.text = widget.existingFormData!['FullName'] ?? '';
      _fullNameLocController.text = widget.existingFormData!['FullNameLoc'] ?? '';
      _dayController.text = widget.existingFormData!['Day'] ?? '';
      _monthController.text = widget.existingFormData!['Month'] ?? '';
      _yearController.text = widget.existingFormData!['Year'] ?? '';
      _nationalityController.text = widget.existingFormData!['Nationality'] ?? '';
      _businessNatureController.text = widget.existingFormData!['BusinessNature'] ?? '';
      _designationController.text = widget.existingFormData!['Designation'] ?? '';
      _companyNameController.text = widget.existingFormData!['CompanyName'] ?? '';
      _hkbrController.text = widget.existingFormData!['HKBR'] ?? '';
      _natureOfBusinessController.text = widget.existingFormData!['NatureofBusiness'] ?? '';
      _adviserNameController.text = widget.existingFormData!['AdviserName'] ?? '';
      _licenceNoController.text = widget.existingFormData!['LicenceNo'] ?? '';
      
      _gender = widget.existingFormData!['Gender'];
      _maritalStatus = widget.existingFormData!['MaritalStatus'];
      _educationLevel = widget.existingFormData!['EducationLevel'];
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _fullNameLocController.dispose();
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    _nationalityController.dispose();
    _businessNatureController.dispose();
    _designationController.dispose();
    _companyNameController.dispose();
    _hkbrController.dispose();
    _natureOfBusinessController.dispose();
    _adviserNameController.dispose();
    _licenceNoController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Please fill in all required fields');
      return;
    }

    // Validate required radio selections
    if (_gender == null) {
      _showErrorSnackBar('Please select gender');
      return;
    }
    if (_maritalStatus == null) {
      _showErrorSnackBar('Please select marital status');
      return;
    }
    if (_educationLevel == null) {
      _showErrorSnackBar('Please select education level');
      return;
    }

    try {
      setState(() => _isProcessing = true);

      // Build form data map
      final formData = {
        'FullName': _fullNameController.text,
        'FullNameLoc': _fullNameLocController.text,
        'Day': _dayController.text,
        'Month': _monthController.text,
        'Year': _yearController.text,
        'Nationality': _nationalityController.text,
        'BusinessNature': _businessNatureController.text,
        'Designation': _designationController.text,
        'CompanyName': _companyNameController.text,
        'HKBR': _hkbrController.text,
        'NatureofBusiness': _natureOfBusinessController.text,
        'AdviserName': _adviserNameController.text,
        'LicenceNo': _licenceNoController.text,
        // Store selections for later use
        'Gender': _gender!,
        'MaritalStatus': _maritalStatus!,
        'EducationLevel': _educationLevel!,
        // Map selections to PDF checkbox fields
        'Male': _gender == 'Male' ? 'Yes' : '',
        'Female': _gender == 'Female' ? 'Yes' : '',
        'Single': _maritalStatus == 'Single' ? 'Yes' : '',
        'Married': _maritalStatus == 'Married' ? 'Yes' : '',
        'Divorced': _maritalStatus == 'Divorced' ? 'Yes' : '',
        'Widowed': _maritalStatus == 'Widowed' ? 'Yes' : '',
        'Primary': _educationLevel == 'Primary' ? 'Yes' : '',
        'Secondary': _educationLevel == 'Secondary' ? 'Yes' : '',
        'Vocational': _educationLevel == 'Vocational' ? 'Yes' : '',
        'Tertiary': _educationLevel == 'Tertiary' ? 'Yes' : '',
      };

      setState(() => _isProcessing = false);

      // Show success dialog
      _showSuccessDialog(formData);

    } catch (e) {
      setState(() => _isProcessing = false);
      _showErrorSnackBar('Form submission failed: $e');
    }
  }

  void _showSuccessDialog(Map<String, String> formData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Form Saved!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your information has been saved.'),
            const SizedBox(height: 16),
            if (widget.existingSignature != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, color: Colors.purple, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '您的簽名已保留，將一起插入到PDF中',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            const Text(
              '返回主頁面點擊 "Generate Signed PDF" 生成完整的MINA PDF。',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, formData); // Return form data to main page
            },
            icon: const Icon(Icons.check),
            label: const Text('確定'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fill Personal Information'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personal Information Form',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Please fill in your personal information below. Fields marked with * are required.',
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Basic Information Section
                _buildSectionTitle('Basic Information'),
                _buildTextField(
                  controller: _fullNameController,
                  label: 'Full Name *',
                  icon: Icons.person,
                  required: true,
                ),
                TextFormField(
                  controller: _fullNameLocController,
                  decoration: InputDecoration(
                    labelText: 'Full Name (Local Language) - 中文名稱',
                    hintText: '例如：陳大文',
                    prefixIcon: const Icon(Icons.language, color: Colors.blue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  // Allow Chinese input
                  keyboardType: TextInputType.text,
                  // No input formatters - allow all characters including Chinese
                ),
                const SizedBox(height: 16),

                // Date of Birth
                const SizedBox(height: 16),
                const Text(
                  'Date of Birth *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _dayController,
                        label: 'Day',
                        icon: Icons.calendar_today,
                        keyboardType: TextInputType.number,
                        required: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTextField(
                        controller: _monthController,
                        label: 'Month',
                        icon: Icons.calendar_month,
                        keyboardType: TextInputType.number,
                        required: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTextField(
                        controller: _yearController,
                        label: 'Year',
                        icon: Icons.event,
                        keyboardType: TextInputType.number,
                        required: true,
                      ),
                    ),
                  ],
                ),

                // Gender
                const SizedBox(height: 16),
                _buildRadioGroup(
                  title: 'Gender *',
                  value: _gender,
                  options: ['Male', 'Female'],
                  onChanged: (value) => setState(() => _gender = value),
                ),

                _buildTextField(
                  controller: _nationalityController,
                  label: 'Nationality *',
                  icon: Icons.flag,
                  required: true,
                ),

                // Marital Status
                const SizedBox(height: 16),
                _buildRadioGroup(
                  title: 'Marital Status *',
                  value: _maritalStatus,
                  options: ['Single', 'Married', 'Divorced', 'Widowed'],
                  onChanged: (value) => setState(() => _maritalStatus = value),
                ),

                // Education Level
                const SizedBox(height: 16),
                _buildRadioGroup(
                  title: 'Education Level *',
                  value: _educationLevel,
                  options: ['Primary', 'Secondary', 'Vocational', 'Tertiary'],
                  onChanged: (value) => setState(() => _educationLevel = value),
                ),

                // Business Information Section
                const SizedBox(height: 24),
                _buildSectionTitle('Business Information'),
                _buildTextField(
                  controller: _companyNameController,
                  label: 'Company Name',
                  icon: Icons.business,
                ),
                _buildTextField(
                  controller: _designationController,
                  label: 'Designation/Position',
                  icon: Icons.work,
                ),
                _buildTextField(
                  controller: _businessNatureController,
                  label: 'Business Nature',
                  icon: Icons.store,
                ),
                _buildTextField(
                  controller: _natureOfBusinessController,
                  label: 'Nature of Business',
                  icon: Icons.description,
                ),
                _buildTextField(
                  controller: _hkbrController,
                  label: 'HKBR Number',
                  icon: Icons.numbers,
                ),

                // Adviser Information Section
                const SizedBox(height: 24),
                _buildSectionTitle('Adviser Information'),
                _buildTextField(
                  controller: _adviserNameController,
                  label: 'Adviser Name',
                  icon: Icons.support_agent,
                ),
                _buildTextField(
                  controller: _licenceNoController,
                  label: 'Licence Number',
                  icon: Icons.card_membership,
                ),

                // Existing Signature Display
                if (widget.existingSignature != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.verified, color: Colors.purple),
                            SizedBox(width: 8),
                            Text(
                              'Existing Signature',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 120,
                                height: 60,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[400]!),
                                ),
                                child: Image.memory(
                                  widget.existingSignature!.previewPng,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Role: ${widget.existingSignature!.role}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.existingSignature!.timestamp
                                          .toString()
                                          .substring(0, 16),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '✓ 此簽名將自動包含在生成的PDF中',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _submitForm,
                    icon: const Icon(Icons.send, size: 24),
                    label: const Text(
                      'Submit Form',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Loading Overlay
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Submitting form...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: required
            ? (value) {
                if (value == null || value.isEmpty) {
                  return 'This field is required';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Widget _buildRadioGroup({
    required String title,
    required String? value,
    required List<String> options,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: options.map((option) {
            return FilterChip(
              label: Text(option),
              selected: value == option,
              onSelected: (selected) {
                if (selected) {
                  onChanged(option);
                }
              },
              selectedColor: Colors.blue[200],
              checkmarkColor: Colors.blue[900],
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
}

