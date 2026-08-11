import 'package:flutter/material.dart';

/// One of the current user's (driver's) completed offered rides, showing
/// how many of its riders have been rated.
class DriverRatableRide {
  DriverRatableRide({
    required this.requestId,
    required this.rideId,
    required this.driverId,
    required this.date,
    required this.time,
    required this.pickup,
    required this.drop,
    required this.driverRating,
    required this.ratedRiders,
    required this.totalRiders,
  });

  final String requestId;
  final String rideId;
  final String driverId;
  final DateTime date;
  final TimeOfDay time;
  final String pickup;
  final String drop;
  final int? driverRating;
  final int ratedRiders;
  final int totalRiders;
}
