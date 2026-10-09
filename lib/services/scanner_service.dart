import 'package:flutter/material.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class ScannerService {
  final ImagePicker _picker = ImagePicker();

  /// Scans hardcopy documents using Google ML Kit Document Scanner
  Future<List<String>> scanDocument() async {
    final options = DocumentScannerOptions(
      documentFormat: DocumentFormat.jpeg,
      mode: ScannerMode.full,
      pageLimit: 100,
    );

    final documentScanner = DocumentScanner(options: options);
    try {
      final result = await documentScanner.scanDocument();
      await documentScanner.close();

      return result.images;
    } catch (e) {
      await documentScanner.close();
      rethrow;
    }
  }

  /// Pick multiple images from photo gallery
  Future<List<String>> pickFromGallery() async {
    final List<XFile> images = await _picker.pickMultiImage();
    return images.map((xfile) => xfile.path).toList();
  }

  /// Crop and/or rotate an image path using ImageCropper
  Future<String?> cropImage(String imagePath) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imagePath,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop & Rotate Document',
          toolbarColor: const Color(0xFF1E88E5),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Crop & Rotate Document',
        ),
      ],
    );
    return croppedFile?.path;
  }
}
