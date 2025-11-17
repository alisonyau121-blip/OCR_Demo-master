import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logging/logging.dart';
import '../utils/logger.dart';

/// Screen to preview PDF documents from assets or memory
class PdfViewerScreen extends StatefulWidget {
  final String? assetPath;
  final Uint8List? pdfBytes;
  final String title;

  const PdfViewerScreen({
    super.key,
    this.assetPath,
    this.pdfBytes,
    this.title = 'PDF Preview',
  }) : assert(assetPath != null || pdfBytes != null, 
              'Either assetPath or pdfBytes must be provided');

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  static final _log = Logger('PdfViewerScreen');
  
  String? _localPath;
  bool _isLoading = true;
  String? _errorMessage;
  int _totalPages = 0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadPdfFromAsset();
  }

  /// Load PDF from assets or memory and copy to temp directory for flutter_pdfview
  Future<void> _loadPdfFromAsset() async {
    try {
      Uint8List pdfData;
      String fileName;
      
      if (widget.pdfBytes != null) {
        // Use PDF from memory
        _log.info('Loading PDF from memory bytes');
        pdfData = widget.pdfBytes!;
        fileName = 'preview_pdf.pdf';
      } else {
        // Load PDF from assets
        _log.info('Loading PDF from asset: ${widget.assetPath}');
        final ByteData data = await rootBundle.load(widget.assetPath!);
        pdfData = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        fileName = widget.assetPath!.split('/').last;
      }
      
      // Get temporary directory
      final Directory tempDir = await getTemporaryDirectory();
      final File tempFile = File('${tempDir.path}/$fileName');
      
      // Write to temp file
      await tempFile.writeAsBytes(pdfData, flush: true);
      
      _log.info('PDF copied to temp: ${tempFile.path}');
      
      setState(() {
        _localPath = tempFile.path;
        _isLoading = false;
      });
    } catch (e, st) {
      _log.severe('Failed to load PDF', e, st);
      setState(() {
        _errorMessage = 'Failed to load PDF: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        actions: [
          if (_totalPages > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Text(
                  '${_currentPage + 1}/$_totalPages',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading PDF...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    if (_localPath == null) {
      return const Center(
        child: Text('No PDF file loaded'),
      );
    }

    return PDFView(
      filePath: _localPath!,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: true,
      pageSnap: true,
      fitPolicy: FitPolicy.WIDTH,
      onRender: (pages) {
        setState(() {
          _totalPages = pages ?? 0;
        });
        _log.info('PDF rendered with $_totalPages pages');
      },
      onPageChanged: (page, total) {
        setState(() {
          _currentPage = page ?? 0;
        });
      },
      onError: (error) {
        _log.severe('PDF view error: $error');
        setState(() {
          _errorMessage = 'Error displaying PDF: $error';
        });
      },
      onPageError: (page, error) {
        _log.warning('Error on page $page: $error');
      },
    );
  }
}

