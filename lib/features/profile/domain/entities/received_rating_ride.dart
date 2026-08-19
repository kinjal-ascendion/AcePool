import 'package:flutter/material.dart';

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

class ReceivedReviewRide {
  const ReceivedReviewRide({
    required this.rideId,
    required this.date,
    required this.time,
    required this.pickup,
    required this.drop,
    required this.riderName,
    this.riderPhotoUrl,
    this.riderEmployeeId,
    this.sentiment,
    this.tags = const [],
    this.comment,
  });

  final String rideId;
  final DateTime date;
  final TimeOfDay time;
  final String pickup;
  final String drop;
  final String riderName;
  final String? riderPhotoUrl;
  final String? riderEmployeeId;
  final int? sentiment;
  final List<String> tags;
  final String? comment;
}

class ReceivedReviewFromDriver {
  const ReceivedReviewFromDriver({
    required this.rideId,
    required this.date,
    required this.time,
    required this.pickup,
    required this.drop,
    required this.driverName,
    this.driverPhotoUrl,
    this.driverEmployeeId,
    this.sentiment,
    this.tags = const [],
    this.comment,
  });

  final String rideId;
  final DateTime date;
  final TimeOfDay time;
  final String pickup;
  final String drop;
  final String driverName;
  final String? driverPhotoUrl;
  final String? driverEmployeeId;
  final int? sentiment;
  final List<String> tags;
  final String? comment;
}
