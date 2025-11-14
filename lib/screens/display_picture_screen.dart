import 'dart:io';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../services/ocr_service.dart';
import '../id_parsers.dart';

/// Screen for displaying captured/selected image and OCR recognition results
class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;
  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  State<DisplayPictureScreen> createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  static final _log = Logger('DisplayPictureScreen');
  
  bool _isProcessing = false;
  String _rawOcrText = '';
  List<IdParseResult> _parseResults = [];
  
  @override
  void initState() {
    super.initState();
    // Delay auto-start recognition to give UI time to initialize
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _log.info('UI initialized, starting auto-recognition');
        _processImage();
      }
    });
  }
  
  /// Main orchestrator for the OCR recognition workflow
  Future<void> _processImage() async {
    if (!mounted) return;
    
    _setProcessingState(true);
    
    OcrService? ocrService;
    
    try {
      _log.info('========================================');
      _log.info('Starting OCR recognition process for: ${widget.imagePath}');
      
      // Step 1: Validate image file exists
      final imageFile = await _validateImageFile();
      
      // Step 2: Perform OCR
      ocrService = OcrService();
      final text = await _performOcr(ocrService, imageFile);
      
      // Step 3: Parse recognized text
      final results = _parseDocuments(text);
      
      // Step 4: Update UI with results
      await _updateResults(text, results);
      
      _log.info('Recognition process completed successfully!');
      _log.info('========================================');
      
    } catch (e, st) {
      _log.severe('OCR recognition failed', e, st);
      await _handleError(e, st);
    } finally {
      // Step 5: Cleanup resources
      await _cleanup(ocrService);
    }
  }

  /// Step 1: Validate that the image file exists and is accessible
  Future<File> _validateImageFile() async {
    _log.fine('Validating image file: ${widget.imagePath}');
    
    final imageFile = File(widget.imagePath);
    
    if (!await imageFile.exists()) {
      throw FileSystemException(
        'Image file does not exist',
        widget.imagePath,
      );
    }
    
    final fileSize = await imageFile.length();
    _log.info('Image file validated: $fileSize bytes');
    
    return imageFile;
  }

  /// Step 2: Perform OCR on the validated image file
  Future<String> _performOcr(OcrService ocrService, File imageFile) async {
    _log.info('Starting OCR processing...');
    
    final text = await ocrService.processImage(imageFile);
    
    _log.info('OCR completed! Text length: ${text.length}');
    if (text.isNotEmpty && text.length > 10) {
      final preview = text.substring(0, text.length > 100 ? 100 : text.length);
      _log.fine('OCR text preview: $preview...');
    } else {
      _log.fine('OCR text: $text');
    }
    
    return text;
  }

  /// Step 3: Parse the recognized text for ID document information
  List<IdParseResult> _parseDocuments(String text) {
    _log.info('Starting document parsing...');
    
    final results = IdParser.parseAll(text);
    
    _log.info('Found ${results.length} document(s)');
    for (final result in results) {
      _log.fine('  - ${result.type} (valid: ${result.isValid})');
    }
    
    return results;
  }

  /// Step 4: Update UI with OCR and parsing results
  Future<void> _updateResults(String text, List<IdParseResult> results) async {
    if (!mounted) {
      _log.warning('Widget unmounted, skipping UI update');
      return;
    }
    
    setState(() {
      _rawOcrText = text;
      _parseResults = results;
      _isProcessing = false;
    });
    
    _log.fine('UI updated with results');
  }

  /// Step 5: Cleanup resources (OCR service)
  Future<void> _cleanup(OcrService? ocrService) async {
    if (ocrService == null) return;
    
    try {
      await ocrService.dispose();
      _log.fine('OCR service disposed');
    } catch (e, st) {
      _log.severe('Failed to dispose OCR service', e, st);
    }
  }

  /// Handle errors during OCR processing
  Future<void> _handleError(Object error, StackTrace stackTrace) async {
    _log.severe('========================================');
    _log.severe('Error details', error, stackTrace);
    _log.severe('========================================');
    
    if (!mounted) return;
    
    setState(() {
      _rawOcrText = 'Recognition failed:\n$error\n\nDetails:\n$stackTrace';
      _isProcessing = false;
    });
    
    // Show error snackbar
    if (mounted) {
      final errorMsg = error.toString();
      final shortMsg = errorMsg.length > 50 
          ? '${errorMsg.substring(0, 50)}...' 
          : errorMsg;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recognition failed: $shortMsg'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Details',
            onPressed: () => _showErrorDialog(error, stackTrace),
          ),
        ),
      );
    }
  }

  /// Show detailed error information in a dialog
  void _showErrorDialog(Object error, StackTrace stackTrace) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error Details'),
        content: SingleChildScrollView(
          child: Text('$error\n\n$stackTrace'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Helper to set processing state
  void _setProcessingState(bool isProcessing) {
    if (!mounted) return;
    
    setState(() {
      _isProcessing = isProcessing;
      _rawOcrText = '';
      _parseResults = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ID OCR Recognition'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isProcessing ? null : _processImage,
            tooltip: 'Re-recognize',
          ),
        ],
      ),
      body: Column(
        children: [
          // Image preview
          Container(
            height: 200,
            width: double.infinity,
            color: Colors.black,
            child: Image.file(
              File(widget.imagePath),
              fit: BoxFit.contain,
            ),
          ),
          
          // Recognition results
          Expanded(
            child: _isProcessing
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Recognizing...'),
                      ],
                    ),
                  )
                : _buildResultsView(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Parse results
          if (_parseResults.isEmpty)
            Card(
              color: Colors.orange.shade900,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No valid ID document recognized\nPlease ensure the image is clear and contains the complete document',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._parseResults.map(_buildResultCard),
          
          const SizedBox(height: 24),
          
          // Raw OCR text (for debugging)
          ExpansionTile(
            title: const Text(
              'Raw OCR Text (Debug)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            initiallyExpanded: _parseResults.isEmpty,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  _rawOcrText.isEmpty ? '(empty)' : _rawOcrText,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultCard(IdParseResult result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: result.isValid ? Colors.green.shade900 : Colors.red.shade900,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                Icon(
                  result.isValid ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.type,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white54, height: 24),
            
            // Fields list
            ...result.fields.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SelectableText(
                      entry.value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

