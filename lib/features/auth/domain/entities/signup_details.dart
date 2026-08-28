import 'package:acepool/features/onboarding/domain/onboarding_selection.dart';

class SignupDetails {
  const SignupDetails({
    required this.fullName,
    required this.employeeId,
    required this.phone,
    required this.emailUsername,
    required this.password,
    this.onboardingSelection,
    this.licenseVerified,
    this.licenseNumber,
  });

  final String fullName;
  final String employeeId;
  final String phone;
  final String emailUsername;
  final String password;
  final OnboardingSelection? onboardingSelection;

  /// Only set when the license section was shown and at least one side was
  /// scanned - mirrors the original signup form's conditional Firestore write.
  final bool? licenseVerified;
  final String? licenseNumber;
}
