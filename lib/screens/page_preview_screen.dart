import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/pdf_service.dart';
import '../services/rewarded_ad_service.dart';
import '../services/scanner_service.dart';
import '../widgets/scan_option_bottom_sheet.dart';
import 'pdf_viewer_screen.dart';

class PagePreviewScreen extends StatefulWidget {
  final List<String> initialImagePaths;

  const PagePreviewScreen({
    super.key,
    required this.initialImagePaths,
  });

  @override
  State<PagePreviewScreen> createState() => _PagePreviewScreenState();
}

class _PagePreviewScreenState extends State<PagePreviewScreen> {
  late List<String> _imagePaths;
  late TextEditingController _fileNameController;
  PageFormatOption _selectedFormat = PageFormatOption.a4;
  bool _isGenerating = false;
  final ScannerService _scannerService = ScannerService();
  final RewardedAdService _rewardedAdService = RewardedAdService();

  @override
  void initState() {
    super.initState();
    _imagePaths = List.from(widget.initialImagePaths);
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    _fileNameController = TextEditingController(text: 'Scan_$timestamp');
    _rewardedAdService.loadAd();
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  Future<void> _addMorePages() async {
    final source = await ScanOptionBottomSheet.show(context);
    if (source == null) return;

    List<String> newPaths = [];

    try {
      if (source == ScanSource.camera) {
        newPaths = await _scannerService.scanDocument();
      } else {
        newPaths = await _scannerService.pickFromGallery();
      }

      if (newPaths.isNotEmpty) {
        setState(() {
          _imagePaths.addAll(newPaths);
        });
      }
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (!errStr.contains('cancel') && !errStr.contains('user_cancelled')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding pages: $e')),
          );
        }
      }
    }
  }

  Future<void> _cropPage(int index) async {
    try {
      final croppedPath = await _scannerService.cropImage(_imagePaths[index]);
      if (croppedPath != null) {
        setState(() {
          _imagePaths[index] = croppedPath;
        });
      }
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (!errStr.contains('cancel') && !errStr.contains('user_cancelled')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error cropping image: $e')),
          );
        }
      }
    }
  }

  void _removePage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
    if (_imagePaths.isEmpty) {
      Navigator.pop(context);
    }
  }

  void _onSavePressed() {
    if (_imagePaths.isEmpty) return;

    final name = _fileNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a document name')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.ondemand_video_rounded, color: Colors.blue, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Watch Ad to Save PDF',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: const Text(
          'Please watch a short video ad to save and generate your PDF document.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () {
              Navigator.pop(context);
              _rewardedAdService.showAd(
                onRewarded: () {
                  _generatePdf();
                },
                onAdNotReady: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ad loading... Generating PDF.')),
                  );
                  _generatePdf();
                },
              );
            },
            child: const Text('Watch Ad & Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePdf() async {
    final name = _fileNameController.text.trim();

    setState(() {
      _isGenerating = true;
    });

    try {
      final pdfFile = await PdfService.generatePdf(
        imagePaths: _imagePaths,
        fileName: name,
        formatOption: _selectedFormat,
      );

      if (mounted) {
        // Navigate to PDF viewer screen and replace preview screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PdfViewerScreen(pdfPath: pdfFile.path),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review & Edit Pages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            tooltip: 'Add More Pages',
            onPressed: _addMorePages,
          ),
        ],
      ),
      body: _isGenerating
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Generating PDF Document...',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _fileNameController,
                        decoration: InputDecoration(
                          labelText: 'Document Name',
                          hintText: 'Enter file name',
                          prefixIcon: const Icon(Icons.picture_as_pdf),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _fileNameController.clear(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Page Size: ', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SegmentedButton<PageFormatOption>(
                              segments: const [
                                ButtonSegment(
                                  value: PageFormatOption.a4,
                                  label: Text('A4'),
                                ),
                                ButtonSegment(
                                  value: PageFormatOption.letter,
                                  label: Text('Letter'),
                                ),
                                ButtonSegment(
                                  value: PageFormatOption.fitImage,
                                  label: Text('Auto'),
                                ),
                              ],
                              selected: {_selectedFormat},
                              onSelectionChanged: (Set<PageFormatOption> newSelection) {
                                setState(() {
                                  _selectedFormat = newSelection.first;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Pages: ${_imagePaths.length}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addMorePages,
                        icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                        label: const Text('Add Page'),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _imagePaths.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final item = _imagePaths.removeAt(oldIndex);
                        _imagePaths.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      final path = _imagePaths[index];
                      return Card(
                        key: ValueKey(path + index.toString()),
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(8),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(path),
                              width: 50,
                              height: 65,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            'Page ${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text('Crop, rotate or drag to reorder'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.crop_rotate),
                                tooltip: 'Crop / Rotate',
                                onPressed: () => _cropPage(index),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: theme.colorScheme.error,
                                ),
                                tooltip: 'Delete Page',
                                onPressed: () => _removePage(index),
                              ),
                              const Icon(Icons.drag_handle),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _isGenerating ? null : _onSavePressed,
            icon: const Icon(Icons.ondemand_video_rounded),
            label: Text(
              'Watch Ad & Save PDF (${_imagePaths.length} ${_imagePaths.length == 1 ? 'Page' : 'Pages'})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
