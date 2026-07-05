import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class LicenseOcrValidator {
  LicenseOcrValidator._();

  static const _keywords = [
    'DRIVING LICENCE',
    'DRIVING LICENSE',
    'UNION OF INDIA',
    'TRANSPORT DEPARTMENT',
    'MOTOR VEHICLE',
    'LICENCE TO DRIVE',
    'LICENSE TO DRIVE',
    'AUTHORISATION TO DRIVE',
    'NON-TRANSPORT',
  ];

  static Future<bool> looksLikeDrivingLicense(File file) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(InputImage.fromFile(file));
      final text = result.text.toUpperCase();
      if (text.length < 15) return false;
      return _keywords.any(text.contains);
    } catch (_) {
      return false;
    } finally {
      await recognizer.close();
    }
  }
}
