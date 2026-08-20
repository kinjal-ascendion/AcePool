import 'package:firebase_auth/firebase_auth.dart';

class AuthErrorMapper {
  AuthErrorMapper._();

  static String map(
    FirebaseAuthException e, {
    required String fallback,
  }) {
    switch (e.code) {
      case 'invalid-credential':
        return 'Invalid username or password';
      case 'invalid-email':
        return 'Please enter a valid email';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method.';
      default:
        return fallback;
    }
  }
}
