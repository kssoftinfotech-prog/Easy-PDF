import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../services/document_storage.dart';
import '../services/review_service.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfPath;

  const PdfViewerScreen({
    super.key,
    required this.pdfPath,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late String _currentPath;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.pdfPath;
  }

  String get _fileName {
    final name = _currentPath.split(Platform.pathSeparator).last;
    return name.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
  }

  Future<void> _sharePdf() async {
    final file = File(_currentPath);
    if (file.existsSync()) {
      await Share.shareXFiles(
        [XFile(_currentPath)],
        text: 'Sharing scanned PDF document: $_fileName',
      );
    }
  }

  Future<void> _renamePdf() async {
    final controller = TextEditingController(text: _fileName);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename PDF'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'File Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != _fileName) {
      final renamedFile = await DocumentStorage.renamePdf(_currentPath, newName);
      if (renamedFile != null && mounted) {
        setState(() {
          _currentPath = renamedFile.path;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document renamed successfully')),
        );
      }
    }
  }

  Future<void> _deletePdf() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete PDF?'),
        content: Text('Are you sure you want to delete "$_fileName"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DocumentStorage.deletePdf(_currentPath);
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate deleted
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = File(_currentPath);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.star_rate_rounded),
            tooltip: 'Rate App',
            onPressed: () => ReviewService.requestRateApp(context),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share PDF',
            onPressed: _sharePdf,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Rename',
            onPressed: _renamePdf,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: _deletePdf,
          ),
        ],
      ),
      body: file.existsSync()
          ? PdfPreview(
              build: (format) => file.readAsBytes(),
              allowSharing: true,
              allowPrinting: true,
              canChangePageFormat: false,
              useActions: false, // We provide clean top AppBar actions
            )
          : const Center(
              child: Text('PDF File not found'),
            ),
    );
  }
}
