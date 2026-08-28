import 'package:acepool/features/auth/domain/entities/auth_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthException', () {
    test('exposes the message it was constructed with', () {
      const exception = AuthException('Something went wrong');

      expect(exception.message, 'Something went wrong');
    });

    test('toString returns the message', () {
      const exception = AuthException('Invalid username or password');

      expect(exception.toString(), 'Invalid username or password');
    });

    test('is an Exception', () {
      const exception = AuthException('boom');

      expect(exception, isA<Exception>());
    });
  });
}
