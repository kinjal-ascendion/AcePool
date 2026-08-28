import 'package:acepool/features/auth/domain/entities/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthUser', () {
    test('stores required uid and email with null displayName by default', () {
      const user = AuthUser(uid: 'uid-1', email: 'user@ascendion.com');

      expect(user.uid, 'uid-1');
      expect(user.email, 'user@ascendion.com');
      expect(user.displayName, isNull);
    });

    test('stores an optional displayName when provided', () {
      const user = AuthUser(
        uid: 'uid-2',
        email: 'jane@ascendion.com',
        displayName: 'Jane Doe',
      );

      expect(user.uid, 'uid-2');
      expect(user.email, 'jane@ascendion.com');
      expect(user.displayName, 'Jane Doe');
    });
  });
}
