import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:validifydart/validify_dart.dart';

class LicenseScanResult {
  const LicenseScanResult({this.licenseNumber, required this.ocrFailed});

  final String? licenseNumber;
  final bool ocrFailed;
}

/// Shared driving-license image source picker + OCR extraction, used by
/// both the Signup and Account Settings license upload flows.
class LicenseScanner {
  LicenseScanner._();

  static Future<ImageSource?> chooseImageSource(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  /// Runs OCR on [imagePath] and tries to extract a valid license number.
  /// [LicenseScanResult.ocrFailed] is only true when OCR itself throws
  /// (unreadable image) - a clean scan with no match returns a result with
  /// a null [LicenseScanResult.licenseNumber] and ocrFailed = false, since
  /// most licenses only print the full number on one side.
  static Future<LicenseScanResult> extractLicenseNumber(
    String imagePath,
  ) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await recognizer.processImage(inputImage);
      final match = RegExp(
        r'([A-Z]{2})[-\s]*(\d{2})[-\s]*(\d{11})',
      ).firstMatch(recognizedText.text);
      if (match == null) return const LicenseScanResult(ocrFailed: false);
      final cleaned = '${match[1]}${match[2]}${match[3]}';
      final valid = ValidifyDart.isValidDrivingLicense(cleaned);
      return LicenseScanResult(
        licenseNumber: valid ? cleaned : null,
        ocrFailed: false,
      );
    } catch (_) {
      return const LicenseScanResult(ocrFailed: true);
    } finally {
      recognizer.close();
    }
  }
}
