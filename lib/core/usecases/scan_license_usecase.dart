import '../utils/license_scanner.dart';

class ScanLicenseUseCase {
  ScanLicenseUseCase({Future<LicenseScanResult> Function(String)? scan})
      : _scan = scan ?? LicenseScanner.extractLicenseNumber;

  final Future<LicenseScanResult> Function(String) _scan;

  Future<LicenseScanResult> call(String imagePath) => _scan(imagePath);
}
