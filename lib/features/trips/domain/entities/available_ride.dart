import 'package:flutter/material.dart';

import 'package:acepool/core/utils/ride_matcher.dart';

/// A driver-offered ride matched against the rider's current Home
/// find-ride form (shared with `home`'s `HomeBloc`), shown on the Trips
/// "Suggested Rides" tab.
class AvailableRide {
  const AvailableRide({
    required this.id,
    required this.driverId,
    required this.driverName,
    this.driverPhotoUrl = '',
    this.driverPhone = '',
    required this.date,
    required this.time,
    required this.fromAddress,
    required this.toAddress,
    this.fromLat,
    this.fromLng,
    this.toLat,
    this.toLng,
    required this.seatsFilled,
    required this.seatsTotal,
    required this.vehicleType,
    required this.alreadyRequested,
    required this.matchPercent,
    required this.defaultPickupPoint,
    required this.distanceKm,
    this.farePerSeat,
    this.negotiatedPrice,
    this.negotiationStatus,
    this.requestId,
    this.userFromAddress = '',
    this.userToAddress = '',
    this.userFromLat,
    this.userFromLng,
    this.userToLat,
    this.userToLng,
  });

  final String id;
  final String driverId;
  final String driverName;
  final String driverPhotoUrl;
  final String driverPhone;
  final DateTime date;
  final TimeOfDay time;
  final String fromAddress;
  final String toAddress;
  final double? fromLat;
  final double? fromLng;
  final double? toLat;
  final double? toLng;
  final int seatsFilled;
  final int seatsTotal;
  final String vehicleType;
  final bool alreadyRequested;
  final int matchPercent;
  final String defaultPickupPoint;
  final double? distanceKm;
  final double? farePerSeat;
  final double? negotiatedPrice;
  final String? negotiationStatus;
  final String? requestId;

  /// The rider's own commute points at the time this match was computed
  /// (read from `HomeBloc`'s find-ride form) — needed again when creating
  /// the ride_request doc.
  final String userFromAddress;
  final String userToAddress;
  final double? userFromLat;
  final double? userFromLng;
  final double? userToLat;
  final double? userToLng;

  double? get effectiveFare =>
      (negotiationStatus == 'accepted' && negotiatedPrice != null)
          ? negotiatedPrice
          : farePerSeat;

  String? get distanceLabel =>
      distanceKm == null ? null : RideMatcher.formatDistance(distanceKm!);

  String get timeLabel {
    final h = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final m = time.minute.toString().padLeft(2, '0');
    final p = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  String get dateLabel {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }
}
