import 'package:acepool/features/profile/domain/entities/profile_summary.dart';

abstract class ProfileRepository {
  Stream<ProfileSummary> watchProfile();

  Future<void> updateProfile({
    required String fullName,
    required String phone,
    required String email,
    bool? licenceVerified,
    String? licenceNumber,
  });

  Future<double> getRouteMatchingRadius();

  Future<void> saveRouteMatchingRadius(double radius);

  Future<void> logout();

  Future<void> savePaymentDetails({
    required String method,
    required String upiId,
    required String upiPhone,
  });

  Future<({String method, String upiId, String upiPhone})> getPaymentDetails();
}
