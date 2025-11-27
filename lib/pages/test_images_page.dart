import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:id_ocr_kit/id_ocr_kit.dart';

class TestImagesPage extends StatefulWidget {
  const TestImagesPage({super.key});

  @override
  State<TestImagesPage> createState() => _TestImagesPageState();
}

class _TestImagesPageState extends State<TestImagesPage> {
  final List<String> _testImages = [
    'assets/images/hkid_sample.jpg',
    'assets/images/cnid_sample.jpg',
    'assets/images/passport_sample.jpg',
  ];

  File? _selectedImage;
  IdRecognitionResult? _result;
  bool _isProcessing = false;
  late final IdRecognitionService _idService;

  @override
  void initState() {
    super.initState();
    _idService = IdRecognitionService(
      ocrProvider: MlKitOcrAdapter(),
    );
  }

  @override
  void dispose() {
    _idService.dispose();
    super.dispose();
  }

  Future<File?> _loadAssetImage(String assetPath) async {
    try {
      // Load asset as bytes
      final byteData = await rootBundle.load(assetPath);
      
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final fileName = assetPath.split('/').last;
      final file = File('${tempDir.path}/$fileName');
      
      // Write bytes to file
      await file.writeAsBytes(byteData.buffer.asUint8List());
      
      return file;
    } catch (e) {
      debugPrint('Error loading asset: $e');
      return null;
    }
  }

  Future<void> _processTestImage(String assetPath) async {
    setState(() => _isProcessing = true);

    try {
      final imageFile = await _loadAssetImage(assetPath);
      
      if (imageFile == null) {
        _showErrorSnackBar('Failed to load test image');
        setState(() => _isProcessing = false);
        return;
      }

      setState(() => _selectedImage = imageFile);

      // Use id_ocr_kit to recognize ID
      final result = await _idService.recognizeId(imageFile);

      setState(() {
        _result = result;
        _isProcessing = false;
      });

      if (result.isSuccess && result.hasIds) {
        _showSuccessSnackBar('ID recognized successfully!');
      } else {
        _showWarningSnackBar('No ID found in image');
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showErrorSnackBar('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test with Sample Images'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Card
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            const Text(
                              'Test Images',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Place your test images in:\nassets/images/\n\nSupported filenames:\n• hkid_sample.jpg\n• cnid_sample.jpg\n• passport_sample.jpg',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Test Image Buttons
                const Text(
                  'Select a test image:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                _buildTestImageButton(
                  'Hong Kong ID Sample',
                  Icons.badge,
                  Colors.blue,
                  _testImages[0],
                ),
                const SizedBox(height: 12),

                _buildTestImageButton(
                  'China ID Sample',
                  Icons.credit_card,
                  Colors.red,
                  _testImages[1],
                ),
                const SizedBox(height: 12),

                _buildTestImageButton(
                  'Passport Sample',
                  Icons.flight_takeoff,
                  Colors.green,
                  _testImages[2],
                ),
                const SizedBox(height: 24),

                // Selected Image Preview
                if (_selectedImage != null) ...[
                  const Text(
                    'Selected Image:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Image.file(
                      _selectedImage!,
                      height: 250,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Results
                if (_result != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _result!.hasIds
                                    ? Icons.check_circle
                                    : Icons.warning,
                                color: _result!.hasIds
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _result!.hasIds
                                    ? 'ID Recognized (${_result!.idCount})'
                                    : 'No ID Found',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                          if (_result!.hasIds) ...[
                            const Divider(height: 24),
                            for (var id in _result!.parsedIds!)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    id.type,
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  for (var entry in id.fields.entries)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              entry.key,
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                              entry.value.toString(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
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
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Processing with id_ocr_kit...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTestImageButton(
    String label,
    IconData icon,
    Color color,
    String assetPath,
  ) {
    return ElevatedButton.icon(
      onPressed: _isProcessing ? null : () => _processTestImage(assetPath),
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
      ),
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

