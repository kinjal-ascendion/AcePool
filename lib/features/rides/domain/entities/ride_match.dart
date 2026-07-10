import 'package:acepool/core/utils/date_time_formatter.dart';
import 'package:acepool/core/utils/ride_matcher.dart';
import 'package:flutter/material.dart';

/// A driver-offered ride that matched a rider's search criteria.
class RideMatch {
  const RideMatch({
    required this.id,
    required this.driverId,
    required this.driverName,
    this.driverPhotoUrl,
    required this.date,
    required this.time,
    required this.fromAddress,
    required this.toAddress,
    required this.seatsFilled,
    required this.seatsTotal,
    required this.vehicleType,
    required this.alreadyRequested,
    required this.distanceKm,
    required this.matchPercent,
  });

  final String id;
  final String driverId;
  final String driverName;
  final String? driverPhotoUrl;
  final DateTime date;
  final TimeOfDay time;
  final String fromAddress;
  final String toAddress;
  final int seatsFilled;
  final int seatsTotal;
  final String vehicleType;
  final bool alreadyRequested;
  final double? distanceKm;
  final int matchPercent;

  String get timeLabel => DateTimeFormatter.time12h(time);
  String get dateLabel =>
      DateTimeFormatter.monthDayYear(date) +
      DateTimeFormatter.relativeDayLabel(date);
  String? get distanceLabel =>
      distanceKm == null ? null : RideMatcher.formatDistance(distanceKm!);
}
