import 'package:acepool/features/onboarding/domain/onboarding_selection.dart';

import '../entities/auth_user.dart';
import '../entities/signup_details.dart';

abstract class AuthRepository {
  /// Signs in with [username]/[password]. If [onboardingSelection] is
  /// provided, merges it into the user's Firestore doc after a successful
  /// sign-in (covers the case where onboarding happened before login).
  Future<AuthUser> signIn({
    required String username,
    required String password,
    OnboardingSelection? onboardingSelection,
  });

  Future<AuthUser> signUp(SignupDetails details);

  /// Signs in via Microsoft/Azure AD SSO. Restricts to @ascendion.com
  /// accounts; throws [AuthException] and signs the user back out if a
  /// non-ascendion.com account completes the OAuth flow.
  Future<AuthUser> signInWithMicrosoft();

  /// Generates and sends a fresh OTP for [uid]/[email]. Failures are logged,
  /// not thrown, matching the original fire-and-forget send behavior.
  Future<void> sendOtp({required String email, required String uid});

  /// Returns true on success and deletes the OTP document. Throws
  /// [AuthException] with a user-facing message for not-found/expired/
  /// mismatched OTPs or any other verification failure.
  Future<bool> verifyOtp({required String uid, required String enteredOtp});

  /// Deletes the in-progress signup's otp doc, user doc, and auth account.
  /// Best-effort - errors are swallowed, matching the original cleanup flow.
  Future<void> cancelSignup({required String uid});
}
