import 'package:flutter/material.dart';

/// One of the current user's (rider's) completed rides, which they can
/// optionally rate the driver on, if not already rated.
class RiderRatableRide {
  RiderRatableRide({
    required this.requestId,
    required this.rideId,
    required this.driverId,
    required this.date,
    required this.time,
    required this.pickup,
    required this.drop,
    required this.riderRating,
  });

  final String requestId;
  final String rideId;
  final String driverId;
  final DateTime date;
  final TimeOfDay time;
  final String pickup;
  final String drop;
  final int? riderRating;

  RiderRatableRide copyWith({int? riderRating}) {
    return RiderRatableRide(
      requestId: requestId,
      rideId: rideId,
      driverId: driverId,
      date: date,
      time: time,
      pickup: pickup,
      drop: drop,
      riderRating: riderRating ?? this.riderRating,
    );
  }
}
