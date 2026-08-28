import 'package:acepool/core/usecases/scan_license_usecase.dart';
import 'package:acepool/core/utils/license_scanner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScanLicenseUseCase', () {
    test('forwards the image path to the injected scan function', () async {
      String? capturedPath;
      final useCase = ScanLicenseUseCase(
        scan: (path) async {
          capturedPath = path;
          return const LicenseScanResult(licenseNumber: 'KA0120230012345', ocrFailed: false);
        },
      );

      await useCase.call('/tmp/license.jpg');

      expect(capturedPath, '/tmp/license.jpg');
    });

    test('returns the result produced by the injected scan function', () async {
      final expected = const LicenseScanResult(licenseNumber: 'KA0120230012345', ocrFailed: false);
      final useCase = ScanLicenseUseCase(scan: (_) async => expected);

      final result = await useCase.call('/any/path.jpg');

      expect(result.licenseNumber, expected.licenseNumber);
      expect(result.ocrFailed, expected.ocrFailed);
    });

    test('propagates a null licenseNumber with ocrFailed false', () async {
      final useCase = ScanLicenseUseCase(
        scan: (_) async => const LicenseScanResult(ocrFailed: false),
      );

      final result = await useCase.call('/any/path.jpg');

      expect(result.licenseNumber, isNull);
      expect(result.ocrFailed, isFalse);
    });

    test('propagates ocrFailed true', () async {
      final useCase = ScanLicenseUseCase(
        scan: (_) async => const LicenseScanResult(ocrFailed: true),
      );

      final result = await useCase.call('/any/path.jpg');

      expect(result.licenseNumber, isNull);
      expect(result.ocrFailed, isTrue);
    });

    test('propagates an exception thrown by the injected scan function', () async {
      final useCase = ScanLicenseUseCase(
        scan: (_) async => throw Exception('boom'),
      );

      expect(() => useCase.call('/any/path.jpg'), throwsA(isA<Exception>()));
    });
  });
}
