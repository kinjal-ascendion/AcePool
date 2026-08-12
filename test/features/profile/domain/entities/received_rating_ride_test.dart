import 'package:acepool/features/profile/domain/entities/received_rating_ride.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReceivedRatingRide', () {
    test('constructor assigns all fields', () {
      final ride = ReceivedRatingRide(
        rideId: 'ride1',
        date: DateTime(2024, 5, 1),
        time: const TimeOfDay(hour: 8, minute: 15),
        pickup: 'Office',
        drop: 'Home',
        rating: 4.5,
        reviews: 3,
      );

      expect(ride.rideId, 'ride1');
      expect(ride.date, DateTime(2024, 5, 1));
      expect(ride.time, const TimeOfDay(hour: 8, minute: 15));
      expect(ride.pickup, 'Office');
      expect(ride.drop, 'Home');
      expect(ride.rating, 4.5);
      expect(ride.reviews, 3);
    });
  });

  group('RatingsSummary', () {
    test('constructor assigns all fields', () {
      final ride = ReceivedRatingRide(
        rideId: 'ride1',
        date: DateTime(2024, 5, 1),
        time: const TimeOfDay(hour: 8, minute: 15),
        pickup: 'Office',
        drop: 'Home',
        rating: 4.5,
        reviews: 3,
      );

      final summary = RatingsSummary(
        averageRating: 4.2,
        totalReviews: 10,
        ratingCounts: const {5: 4, 4: 3, 3: 2, 2: 1, 1: 0},
        rides: [ride],
      );

      expect(summary.averageRating, 4.2);
      expect(summary.totalReviews, 10);
      expect(summary.ratingCounts, {5: 4, 4: 3, 3: 2, 2: 1, 1: 0});
      expect(summary.rides, [ride]);
    });

    test('supports empty ratingCounts and rides', () {
      const summary = RatingsSummary(
        averageRating: 0,
        totalReviews: 0,
        ratingCounts: {},
        rides: [],
      );

      expect(summary.averageRating, 0);
      expect(summary.totalReviews, 0);
      expect(summary.ratingCounts, isEmpty);
      expect(summary.rides, isEmpty);
    });
  });
}
