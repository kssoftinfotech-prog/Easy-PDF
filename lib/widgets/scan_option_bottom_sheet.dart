import 'package:flutter/material.dart';

enum ScanSource { camera, gallery }

class ScanOptionBottomSheet extends StatelessWidget {
  const ScanOptionBottomSheet({super.key});

  static Future<ScanSource?> show(BuildContext context) {
    return showModalBottomSheet<ScanSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const ScanOptionBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Create New PDF',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose how you want to add documents or photos',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.document_scanner,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            title: const Text(
              'Scan Document',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pop(context, ScanSource.camera),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.photo_library,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
            title: const Text(
              'Import from Gallery',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pop(context, ScanSource.gallery),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
