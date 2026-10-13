import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../models/scanned_document.dart';
import '../services/document_storage.dart';
import '../services/review_service.dart';
import '../services/scanner_service.dart';
import '../widgets/document_card.dart';
import '../widgets/scan_option_bottom_sheet.dart';
import 'page_preview_screen.dart';
import 'pdf_viewer_screen.dart';
import 'privacy_policy_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ScannedDocument> _documents = [];
  List<ScannedDocument> _filteredDocuments = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final ScannerService _scannerService = ScannerService();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterDocuments);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDocuments();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<bool> _checkAndRequestPermissions(ScanSource source) async {
    final cameraStatus = await Permission.camera.status;
    final photosStatus = await Permission.photos.status;
    final storageStatus = await Permission.storage.status;
    final hasStorage = photosStatus.isGranted || storageStatus.isGranted;

    if (cameraStatus.isGranted && (source == ScanSource.camera || hasStorage)) {
      return true;
    }

    // Request permissions
    final requestedCamera = await Permission.camera.request();
    PermissionStatus requestedStorage = PermissionStatus.granted;
    if (source == ScanSource.gallery) {
      requestedStorage = await Permission.photos.request();
      if (!requestedStorage.isGranted) {
        requestedStorage = await Permission.storage.request();
      }
    }

    if (requestedCamera.isGranted && (source == ScanSource.camera || requestedStorage.isGranted)) {
      return true;
    }

    // If denied or permanently denied, show settings dialog
    if (mounted) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permissions Required'),
          content: const Text(
            'Camera and Storage permissions are required to scan physical documents and import photos from your gallery. Please grant permissions in App Settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    }
    return false;
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
    });

    final docs = await DocumentStorage.getAllPdfs();

    if (mounted) {
      setState(() {
        _documents = docs;
        _isLoading = false;
        _filterDocuments();
      });
    }
  }

  void _filterDocuments() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredDocuments = List.from(_documents);
      } else {
        _filteredDocuments = _documents
            .where((doc) => doc.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _startScanFlow(ScanSource source) async {
    final hasPermission = await _checkAndRequestPermissions(source);
    if (!hasPermission) return;

    try {
      List<String> imagePaths = [];
      if (source == ScanSource.camera) {
        imagePaths = await _scannerService.scanDocument();
      } else {
        imagePaths = await _scannerService.pickFromGallery();
      }

      if (imagePaths.isNotEmpty && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PagePreviewScreen(initialImagePaths: imagePaths),
          ),
        );
        _loadDocuments();
      }
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (!errStr.contains('cancel') && !errStr.contains('user_cancelled')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to get images: $e')),
          );
        }
      }
    }
  }

  void _openScanOptions() async {
    final source = await ScanOptionBottomSheet.show(context);
    if (source != null) {
      _startScanFlow(source);
    }
  }

  Future<void> _shareDocument(ScannedDocument doc) async {
    if (doc.exists) {
      await Share.shareXFiles(
        [XFile(doc.filePath)],
        text: 'Sharing ${doc.name}.pdf',
      );
    }
  }

  Future<void> _renameDocument(ScannedDocument doc) async {
    final controller = TextEditingController(text: doc.name);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename PDF'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Document Name',
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

    if (newName != null && newName.isNotEmpty && newName != doc.name) {
      await DocumentStorage.renamePdf(doc.filePath, newName);
      _loadDocuments();
    }
  }

  Future<void> _deleteDocument(ScannedDocument doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete PDF?'),
        content: Text('Are you sure you want to delete "${doc.name}"?'),
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
      await DocumentStorage.deletePdf(doc.filePath);
      _loadDocuments();
    }
  }

  Future<bool> _onWillPop() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App?'),
        content: const Text('Are you sure you want to exit Easy PDF?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _onWillPop();
        // ignore: use_build_context_synchronously
        if (!mounted) return;
        if (shouldExit) {
          // ignore: use_build_context_synchronously
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.document_scanner_rounded,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Easy PDF Maker',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.privacy_tip_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                );
              },
              tooltip: 'Privacy Policy',
            ),
            IconButton(
              icon: const Icon(Icons.star_rate_rounded),
              onPressed: () => ReviewService.requestRateApp(context),
              tooltip: 'Rate App',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadDocuments,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadDocuments,
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search PDF documents...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Document List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredDocuments.isEmpty
                        ? _buildEmptyState(context)
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredDocuments.length,
                            itemBuilder: (context, index) {
                              final doc = _filteredDocuments[index];
                              return DocumentCard(
                                document: doc,
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PdfViewerScreen(pdfPath: doc.filePath),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadDocuments();
                                  }
                                },
                                onShare: () => _shareDocument(doc),
                                onRename: () => _renameDocument(doc),
                                onDelete: () => _deleteDocument(doc),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openScanOptions,
          icon: const Icon(Icons.camera_alt),
          label: const Text(
            'Scan Document',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.document_scanner_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchController.text.isNotEmpty ? 'No Documents Found' : 'No Scanned PDFs Yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No document matches your search query. ✨'
                  : 'Tap the "Scan Document" button below to scan hardcopy documents or import photos from gallery.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
