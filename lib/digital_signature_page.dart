import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signature/signature.dart';
import 'package:logging/logging.dart';
import 'signature_preview_page.dart';

class DigitalSignaturePage extends StatefulWidget {
  const DigitalSignaturePage({super.key});

  @override
  State<DigitalSignaturePage> createState() => _DigitalSignaturePageState();
}

class _DigitalSignaturePageState extends State<DigitalSignaturePage> {
  static final _log = Logger('DigitalSignaturePage');
  
  late SignatureController _controller;
  bool _saving = false;
  bool _isLandscape = false;

  @override
  void initState() {
    super.initState();
    
    // Set portrait orientation
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    
    // Initialize signature controller
    _controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
    );
  }

  @override
  void dispose() {
    // Belt-and-suspenders: restore portrait on dispose
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveSignature() async {
    if (_controller.isEmpty) {
      _log.warning('Attempted to save empty signature');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please draw a signature first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _log.info('Starting signature save process');
    setState(() => _saving = true);

    try {
      await WidgetsBinding.instance.endOfFrame;

      // Export signature with transparent background
      _log.fine('Exporting transparent PNG');
      final transparentPng = await _controller.toPngBytes();

      // Null check - toPngBytes can return null
      if (transparentPng == null) {
        _log.severe('Failed to generate signature image (returned null)');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      _log.info('Transparent PNG exported: ${transparentPng.length} bytes');

      // Create white background version by compositing
      _log.fine('Creating white background version');
      final previewPng = await _createWhiteBackgroundVersion(transparentPng);
      _log.info('Preview PNG created: ${previewPng.length} bytes');

      if (!mounted) return;

      // If currently in landscape, switch back to portrait before preview
      if (_isLandscape) {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
        if (!mounted) return;
        setState(() => _isLandscape = false);
      }

      if (!mounted) return;
      
      // Navigate to preview page (now in portrait)
      final result = await Navigator.push<dynamic>(
        context,
        MaterialPageRoute(
          builder: (context) => SignaturePreviewPage(
            previewPngBytes: previewPng,
            transparentPngBytes: transparentPng,
          ),
        ),
      );

      // Handle result if needed (for future integrations)
      if (result != null && mounted) {
        _log.info('Signature saved successfully: $result');
      }
    } catch (e, st) {
      _log.severe('Error saving signature', e, st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<Uint8List> _createWhiteBackgroundVersion(Uint8List transparentPng) async {
    // Decode the transparent PNG
    final codec = await ui.instantiateImageCodec(transparentPng);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    // Create a new canvas with white background
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(image.width.toDouble(), image.height.toDouble());

    // Draw white background
    final paint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Draw the signature on top
    canvas.drawImage(image, Offset.zero, Paint());

    // Convert to PNG
    final picture = recorder.endRecording();
    final img = await picture.toImage(image.width, image.height);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  Future<void> _switchOrientation() async {
    // Clear canvas to avoid stretch artifacts
    _controller.clear();

    final newOrientation = _isLandscape
        ? [DeviceOrientation.portraitUp]
        : [
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ];

    await SystemChrome.setPreferredOrientations(newOrientation);

    if (!mounted) return;

    setState(() {
      _isLandscape = !_isLandscape;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isLandscape
              ? 'Switched to landscape. Canvas cleared for larger drawing area.'
              : 'Switched to portrait. Canvas cleared.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          // Belt-and-suspenders: catch system back/swipe
          await SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
          ]);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Digital Signature'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Orientation switch hint
            InkWell(
              onTap: _saving ? null : _switchOrientation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.blue.shade900,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isLandscape
                          ? Icons.screen_lock_portrait
                          : Icons.screen_lock_landscape,
                      size: 20,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Tap to change signature orientation',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            // Signature canvas
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Signature(
                      controller: _controller,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ),
              ),
            ),

            // Action buttons with tap-spam protection
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: AbsorbPointer(
                absorbing: _saving,
                child: Row(
                  children: [
                    // Save button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _saveSignature,
                        icon: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(_saving ? 'Saving...' : 'Save Signature'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size.fromHeight(50),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Clear button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saving
                            ? null
                            : () {
                                _controller.clear();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Canvas cleared'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: const Size.fromHeight(50),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Padding at bottom
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

