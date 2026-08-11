import 'package:flutter/material.dart';

/// One ride whose rating (given to or by the current user, depending on
/// which query produced it) is being displayed on a ratings summary screen.
class ReceivedRatingRide {
  ReceivedRatingRide({
    required this.rideId,
    required this.date,
    required this.time,
    required this.pickup,
    required this.drop,
    required this.rating,
    required this.reviews,
  });

  final String rideId;
  final DateTime date;
  final TimeOfDay time;
  final String pickup;
  final String drop;
  final double rating;
  final int reviews;
}

/// Aggregate ratings summary shown at the top of a ratings screen, plus the
/// individual ride rows.
class RatingsSummary {
  const RatingsSummary({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingCounts,
    required this.rides,
  });

  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingCounts;
  final List<ReceivedRatingRide> rides;
}
