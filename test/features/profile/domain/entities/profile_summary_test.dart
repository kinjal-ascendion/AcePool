import 'package:acepool/features/profile/domain/entities/profile_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileSummary', () {
    test('constructor assigns required fields and defaults hasVehicles to false', () {
      const summary = ProfileSummary(fullName: 'Jane Doe', employeeId: 'E1');

      expect(summary.fullName, 'Jane Doe');
      expect(summary.employeeId, 'E1');
      expect(summary.phone, isNull);
      expect(summary.licenceVerified, isNull);
      expect(summary.licenceNumber, isNull);
      expect(summary.travelPreference, isNull);
      expect(summary.hasVehicles, isFalse);
    });

    test('constructor assigns all optional fields when provided', () {
      const summary = ProfileSummary(
        fullName: 'Jane Doe',
        employeeId: 'E1',
        phone: '1234567890',
        licenceVerified: true,
        licenceNumber: 'LIC1',
        travelPreference: 'drive',
        hasVehicles: true,
      );

      expect(summary.phone, '1234567890');
      expect(summary.licenceVerified, isTrue);
      expect(summary.licenceNumber, 'LIC1');
      expect(summary.travelPreference, 'drive');
      expect(summary.hasVehicles, isTrue);
    });

    group('isDriver', () {
      test('true when travelPreference is drive', () {
        const summary = ProfileSummary(
          fullName: 'A',
          employeeId: 'E',
          travelPreference: 'drive',
        );
        expect(summary.isDriver, isTrue);
      });

      test('true when travelPreference is both', () {
        const summary = ProfileSummary(
          fullName: 'A',
          employeeId: 'E',
          travelPreference: 'both',
        );
        expect(summary.isDriver, isTrue);
      });

      test('true when hasVehicles is true even if travelPreference is ride', () {
        const summary = ProfileSummary(
          fullName: 'A',
          employeeId: 'E',
          travelPreference: 'ride',
          hasVehicles: true,
        );
        expect(summary.isDriver, isTrue);
      });

      test('false when travelPreference is ride and hasVehicles is false', () {
        const summary = ProfileSummary(
          fullName: 'A',
          employeeId: 'E',
          travelPreference: 'ride',
        );
        expect(summary.isDriver, isFalse);
      });

      test('false when travelPreference and hasVehicles are both unset', () {
        const summary = ProfileSummary(fullName: 'A', employeeId: 'E');
        expect(summary.isDriver, isFalse);
      });
    });

    group('initials', () {
      test('returns first letters of first two words uppercased', () {
        const summary = ProfileSummary(fullName: 'jane doe', employeeId: 'E');
        expect(summary.initials, 'JD');
      });

      test('returns single letter for single word name', () {
        const summary = ProfileSummary(fullName: 'Jane', employeeId: 'E');
        expect(summary.initials, 'J');
      });

      test('takes only first two words when name has more than two words', () {
        const summary = ProfileSummary(fullName: 'Jane Middle Doe', employeeId: 'E');
        expect(summary.initials, 'JM');
      });

      test('ignores extra whitespace between words', () {
        const summary = ProfileSummary(fullName: '  Jane   Doe  ', employeeId: 'E');
        expect(summary.initials, 'JD');
      });

      test('returns ? for empty name', () {
        const summary = ProfileSummary(fullName: '', employeeId: 'E');
        expect(summary.initials, '?');
      });

      test('returns ? for whitespace-only name', () {
        const summary = ProfileSummary(fullName: '   ', employeeId: 'E');
        expect(summary.initials, '?');
      });
    });
  });
}
