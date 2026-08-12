import 'package:acepool/features/profile/domain/entities/rider_review.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RiderReview', () {
    RiderReview buildReview({int? driverRating}) {
      return RiderReview(
        requestId: 'req1',
        riderId: 'rider1',
        riderName: 'Rider One',
        employeeId: 'E1',
        pickupPoint: 'Pickup',
        dropOffPoint: 'Dropoff',
        driverRating: driverRating,
      );
    }

    test('constructor assigns all fields', () {
      final review = buildReview(driverRating: 4);

      expect(review.requestId, 'req1');
      expect(review.riderId, 'rider1');
      expect(review.riderName, 'Rider One');
      expect(review.employeeId, 'E1');
      expect(review.pickupPoint, 'Pickup');
      expect(review.dropOffPoint, 'Dropoff');
      expect(review.driverRating, 4);
    });

    test('driverRating can be null', () {
      final review = buildReview();
      expect(review.driverRating, isNull);
    });

    group('copyWith', () {
      test('overrides driverRating when provided', () {
        final review = buildReview(driverRating: 2);
        final updated = review.copyWith(driverRating: 5);

        expect(updated.driverRating, 5);
        expect(updated.requestId, review.requestId);
        expect(updated.riderId, review.riderId);
        expect(updated.riderName, review.riderName);
        expect(updated.employeeId, review.employeeId);
        expect(updated.pickupPoint, review.pickupPoint);
        expect(updated.dropOffPoint, review.dropOffPoint);
      });

      test('keeps existing driverRating when not provided', () {
        final review = buildReview(driverRating: 2);
        final updated = review.copyWith();

        expect(updated.driverRating, 2);
      });

      test('keeps null driverRating when not provided and originally null', () {
        final review = buildReview();
        final updated = review.copyWith();

        expect(updated.driverRating, isNull);
      });
    });
  });
}
