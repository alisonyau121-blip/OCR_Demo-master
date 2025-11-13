import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:gal/gal.dart';

class SignaturePreviewPage extends StatefulWidget {
  final Uint8List previewPngBytes;
  final Uint8List transparentPngBytes;

  const SignaturePreviewPage({
    super.key,
    required this.previewPngBytes,
    required this.transparentPngBytes,
  });

  @override
  State<SignaturePreviewPage> createState() => _SignaturePreviewPageState();
}

class _SignaturePreviewPageState extends State<SignaturePreviewPage> {
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    // Keep portrait orientation (signature page already set it)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void dispose() {
    // Belt-and-suspenders: restore portrait on dispose
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Future<void> _handleAccept() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Signature'),
        content: const Text('What would you like to do with your signature?'),
        actions: [
          TextButton(
            child: const Text('Save to Gallery'),
            onPressed: () => Navigator.pop(context, 'save'),
          ),
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );

    if (result == null || !mounted) return;

    if (result == 'save') {
      await _saveToGallery();
    }
  }

  Future<void> _saveToGallery() async {
    setState(() => _processing = true);

    try {
      // Generate timestamp-based filename
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'signature_$timestamp.png';
      
      // Save to temporary directory first
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$fileName';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(widget.previewPngBytes);
      
      // Save to gallery using Gal
      await Gal.putImage(tempPath, album: 'Signatures');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Signature saved to gallery!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Clean up temp file
      try {
        await tempFile.delete();
      } catch (_) {
        // Ignore cleanup errors
      }

      // Belt-and-suspenders: restore portrait before popping
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);

      if (!mounted) return;

      // Return to home
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  Future<void> _handleReject() async {
    // Belt-and-suspenders: restore portrait before popping
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    if (!mounted) return;

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_processing,
      onPopInvoked: (didPop) async {
        if (didPop) {
          // Belt-and-suspenders: catch system back/swipe
          await SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
          ]);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Preview Signature'),
          centerTitle: true,
          leading: _processing
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _handleReject,
                ),
        ),
        body: _processing
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Processing...'),
                  ],
                ),
              )
            : Column(
                children: [
                  // Preview area
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              widget.previewPngBytes,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // Accept button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _processing ? null : _handleAccept,
                            icon: const Icon(Icons.check, size: 32),
                            label: const Text(
                              'Accept',
                              style: TextStyle(fontSize: 20),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              minimumSize: const Size.fromHeight(60),
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Reject button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _processing ? null : _handleReject,
                            icon: const Icon(Icons.close, size: 32),
                            label: const Text(
                              'Reject',
                              style: TextStyle(fontSize: 20),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              minimumSize: const Size.fromHeight(60),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
      ),
    );
  }
}

