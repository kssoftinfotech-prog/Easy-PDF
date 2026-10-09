import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

enum PageFormatOption {
  a4,
  letter,
  fitImage,
}

class PdfService {
  static Future<File> generatePdf({
    required List<String> imagePaths,
    required String fileName,
    PageFormatOption formatOption = PageFormatOption.a4,
  }) async {
    final pdf = pw.Document();

    for (final imagePath in imagePaths) {
      final file = File(imagePath);
      if (!file.existsSync()) continue;

      final bytes = await file.readAsBytes();
      final image = pw.MemoryImage(bytes);

      PdfPageFormat format;
      switch (formatOption) {
        case PageFormatOption.a4:
          format = PdfPageFormat.a4;
          break;
        case PageFormatOption.letter:
          format = PdfPageFormat.letter;
          break;
        case PageFormatOption.fitImage:
          final double w = (image.width ?? 595).toDouble();
          final double h = (image.height ?? 842).toDouble();
          format = PdfPageFormat(w, h, marginAll: 0);
          break;
      }

      pdf.addPage(
        pw.Page(
          pageFormat: format,
          margin: formatOption == PageFormatOption.fitImage 
              ? pw.EdgeInsets.zero 
              : const pw.EdgeInsets.all(16),
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(
                image,
                fit: pw.BoxFit.contain,
              ),
            );
          },
        ),
      );
    }

    final outputDir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory('${outputDir.path}/EasyPDF');
    if (!pdfDir.existsSync()) {
      pdfDir.createSync(recursive: true);
    }

    final sanitizedName = fileName.replaceAll(RegExp(r'[^\w\s.-]'), '_').trim();
    final cleanName = sanitizedName.isEmpty ? 'Scanned_Doc' : sanitizedName;
    final finalFileName = cleanName.toLowerCase().endsWith('.pdf') ? cleanName : '$cleanName.pdf';
    final outputFile = File('${pdfDir.path}/$finalFileName');

    await outputFile.writeAsBytes(await pdf.save());
    return outputFile;
  }
}
