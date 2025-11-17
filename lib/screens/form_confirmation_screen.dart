import 'package:flutter/material.dart';

/// Confirmation screen to display submitted form data
class FormConfirmationScreen extends StatelessWidget {
  final Map<String, String> formData;

  const FormConfirmationScreen({
    super.key,
    required this.formData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Submitted'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              
              // Success icon
              const Icon(
                Icons.check_circle,
                size: 100,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              
              // Success message
              const Text(
                'Form Submitted Successfully!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                '表單提交成功！',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              // Display submitted data
              const Text(
                'Submitted Information:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Designation card
              _buildDataCard(
                icon: Icons.work_outline,
                label: 'Designation / 職稱',
                value: formData['Designation'] ?? '',
              ),
              const SizedBox(height: 12),
              
              // Company Name card
              _buildDataCard(
                icon: Icons.business,
                label: 'Company Name / 公司名稱',
                value: formData['CompanyName'] ?? '',
              ),
              const SizedBox(height: 12),
              
              // Adviser Name card
              _buildDataCard(
                icon: Icons.person_outline,
                label: 'Adviser Name / 顧問姓名',
                value: formData['AdviserName'] ?? '',
              ),
              const SizedBox(height: 40),
              
              // Info message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This data will be inserted into the PDF when you generate the signed document.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Back to Home button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.home, size: 28),
                label: const Text(
                  'Back to Home / 返回主頁',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
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
    );
  }

  Widget _buildDataCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade700, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

