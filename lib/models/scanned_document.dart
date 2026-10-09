import 'dart:io';

class ScannedDocument {
  final String id;
  final String name;
  final String filePath;
  final DateTime createdAt;
  final int fileSizeBytes;
  final int pageCount;

  ScannedDocument({
    required this.id,
    required this.name,
    required this.filePath,
    required this.createdAt,
    required this.fileSizeBytes,
    this.pageCount = 1,
  });

  File get file => File(filePath);

  bool get exists => file.existsSync();

  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
