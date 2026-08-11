import '../utils/license_scanner.dart';

class ScanLicenseUseCase {
  Future<LicenseScanResult> call(String imagePath) =>
      LicenseScanner.extractLicenseNumber(imagePath);
}
