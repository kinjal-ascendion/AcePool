import 'package:acepool/core/utils/license_scanner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mocktail/mocktail.dart';

class MockTextRecognizer extends Mock implements TextRecognizer {}

void main() {
  setUpAll(() {
    registerFallbackValue(InputImage.fromFilePath('/fake/path.jpg'));
  });

  group('LicenseScanner.extractLicenseNumber', () {
    test('returns the license number when the regex matches valid text', () async {
      final recognizer = MockTextRecognizer();
      // "KA" + "01" + 11 digits -> matches
      // r'([A-Z]{2})[-\s]*(\d{2})[-\s]*(\d{11})' and, once concatenated,
      // always satisfies ValidifyDart's `^[A-Z]{2}[0-9]{13}$` pattern.
      when(() => recognizer.processImage(any())).thenAnswer(
        (_) async => RecognizedText(
          text: 'Driving Licence\nKA01 20230012345\nValid till 2030',
          blocks: const [],
        ),
      );

      final result = await LicenseScanner.extractLicenseNumber(
        '/some/path.jpg',
        recognizer: recognizer,
      );

      expect(result.licenseNumber, 'KA0120230012345');
      expect(result.ocrFailed, isFalse);
    });

    test('matches with hyphen/space separators between the license number groups', () async {
      final recognizer = MockTextRecognizer();
      when(() => recognizer.processImage(any())).thenAnswer(
        (_) async => RecognizedText(text: 'MH-12-98765432109', blocks: const []),
      );

      final result = await LicenseScanner.extractLicenseNumber(
        '/some/path.jpg',
        recognizer: recognizer,
      );

      expect(result.licenseNumber, 'MH1298765432109');
      expect(result.ocrFailed, isFalse);
    });

    test('returns null licenseNumber and ocrFailed false when there is no regex match', () async {
      final recognizer = MockTextRecognizer();
      when(() => recognizer.processImage(any())).thenAnswer(
        (_) async => RecognizedText(text: 'No license number here at all', blocks: const []),
      );

      final result = await LicenseScanner.extractLicenseNumber(
        '/some/path.jpg',
        recognizer: recognizer,
      );

      expect(result.licenseNumber, isNull);
      expect(result.ocrFailed, isFalse);
    });

    test('returns null licenseNumber and ocrFailed false on empty recognized text', () async {
      final recognizer = MockTextRecognizer();
      when(() => recognizer.processImage(any())).thenAnswer(
        (_) async => RecognizedText(text: '', blocks: const []),
      );

      final result = await LicenseScanner.extractLicenseNumber(
        '/some/path.jpg',
        recognizer: recognizer,
      );

      expect(result.licenseNumber, isNull);
      expect(result.ocrFailed, isFalse);
    });

    test('sets ocrFailed true when processImage throws', () async {
      final recognizer = MockTextRecognizer();
      when(() => recognizer.processImage(any())).thenThrow(Exception('unreadable image'));

      final result = await LicenseScanner.extractLicenseNumber(
        '/some/path.jpg',
        recognizer: recognizer,
      );

      expect(result.licenseNumber, isNull);
      expect(result.ocrFailed, isTrue);
    });

    test('does not call close() on an injected (caller-owned) recognizer', () async {
      final recognizer = MockTextRecognizer();
      when(() => recognizer.processImage(any())).thenAnswer(
        (_) async => RecognizedText(text: 'no match', blocks: const []),
      );
      // Intentionally not stubbing close() — if the scanner called it without
      // us providing a stub, mocktail would still accept the call (returns
      // null), but verifyNever below asserts it's never invoked at all.

      await LicenseScanner.extractLicenseNumber('/some/path.jpg', recognizer: recognizer);

      verifyNever(() => recognizer.close());
    });

    test('does not call close() on an injected recognizer even when processImage throws', () async {
      final recognizer = MockTextRecognizer();
      when(() => recognizer.processImage(any())).thenThrow(Exception('boom'));

      await LicenseScanner.extractLicenseNumber('/some/path.jpg', recognizer: recognizer);

      verifyNever(() => recognizer.close());
    });
  });
}
