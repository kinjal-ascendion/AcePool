class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Thrown when the user dismisses an SSO sign-in sheet without completing
/// it. Callers should treat this as a silent no-op, not a failure.
class SsoCancelledException implements Exception {
  const SsoCancelledException();
}
