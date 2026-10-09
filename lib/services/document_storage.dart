import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/scanned_document.dart';

class DocumentStorage {
  static Future<Directory> getPdfDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory('${docsDir.path}/EasyPDF');
    if (!pdfDir.existsSync()) {
      pdfDir.createSync(recursive: true);
    }
    return pdfDir;
  }

  static Future<List<ScannedDocument>> getAllPdfs() async {
    final pdfDir = await getPdfDirectory();
    if (!pdfDir.existsSync()) return [];

    final List<FileSystemEntity> entities = pdfDir.listSync();
    final List<ScannedDocument> docs = [];

    for (final entity in entities) {
      if (entity is File && entity.path.toLowerCase().endsWith('.pdf')) {
        final stat = entity.statSync();
        final fileName = entity.path.split(Platform.pathSeparator).last;
        final cleanName = fileName.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');

        docs.add(
          ScannedDocument(
            id: entity.path,
            name: cleanName,
            filePath: entity.path,
            createdAt: stat.modified,
            fileSizeBytes: stat.size,
          ),
        );
      }
    }

    // Sort by creation date descending (newest first)
    docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return docs;
  }

  static Future<void> deletePdf(String filePath) async {
    final file = File(filePath);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  static Future<File?> renamePdf(String oldFilePath, String newName) async {
    final oldFile = File(oldFilePath);
    if (!oldFile.existsSync()) return null;

    final dirPath = oldFile.parent.path;
    final sanitizedName = newName.replaceAll(RegExp(r'[^\w\s.-]'), '_').trim();
    final cleanName = sanitizedName.isEmpty ? 'Renamed_Doc' : sanitizedName;
    final finalFileName = cleanName.toLowerCase().endsWith('.pdf') ? cleanName : '$cleanName.pdf';
    final newPath = '$dirPath/$finalFileName';

    if (oldFilePath == newPath) return oldFile;

    return await oldFile.rename(newPath);
  }
}
