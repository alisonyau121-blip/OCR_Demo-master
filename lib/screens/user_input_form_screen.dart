import 'package:flutter/material.dart';

/// User Input Form for collecting Designation, Company Name, and Adviser Name
class UserInputFormScreen extends StatefulWidget {
  const UserInputFormScreen({super.key});

  @override
  State<UserInputFormScreen> createState() => _UserInputFormScreenState();
}

class _UserInputFormScreenState extends State<UserInputFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _designationController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _adviserNameController = TextEditingController();

  @override
  void dispose() {
    _designationController.dispose();
    _companyNameController.dispose();
    _adviserNameController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Return form data as Map
      final formData = {
        'Designation': _designationController.text.trim(),
        'CompanyName': _companyNameController.text.trim(),
        'AdviserName': _adviserNameController.text.trim(),
      };
      Navigator.pop(context, formData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Input Form'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                
                // Form title and description
                const Icon(
                  Icons.assignment,
                  size: 64,
                  color: Colors.amber,
                ),
                const SizedBox(height: 16),
                const Text(
                  'User Information',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please fill in the required information',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                // Designation field
                _buildTextField(
                  controller: _designationController,
                  labelText: 'Designation / 職稱',
                  hintText: 'e.g., Manager, Director',
                  icon: Icons.work_outline,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter designation / 請輸入職稱';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // Company Name field
                _buildTextField(
                  controller: _companyNameController,
                  labelText: 'Company Name / 公司名稱',
                  hintText: 'e.g., ABC Corporation Ltd.',
                  icon: Icons.business,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter company name / 請輸入公司名稱';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // Adviser Name field
                _buildTextField(
                  controller: _adviserNameController,
                  labelText: 'Adviser Name / 顧問姓名',
                  hintText: 'e.g., John Chan',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter adviser name / 請輸入顧問姓名';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                
                // Submit button
                ElevatedButton.icon(
                  onPressed: _submitForm,
                  icon: const Icon(Icons.check_circle, size: 28),
                  label: const Text(
                    'Submit / 提交',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(icon, size: 28),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade400, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.amber, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade900,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        labelStyle: const TextStyle(fontSize: 16),
        hintStyle: TextStyle(color: Colors.grey.shade600),
      ),
      style: const TextStyle(fontSize: 18),
      validator: validator,
      textCapitalization: TextCapitalization.words,
    );
  }
}

