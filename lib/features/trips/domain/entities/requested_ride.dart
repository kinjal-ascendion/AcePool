import 'package:flutter/material.dart';

import 'package:acepool/core/utils/ride_matcher.dart';

/// One of the current user's own ride_requests, shown on the Trips
/// "Ride Requests" tab.
class RequestedRide {
  final String id;
  final String rideId;
  final String driverId;
  final String driverName;
  final String driverPhotoUrl;
  final String driverPhone;
  final DateTime date;
  final TimeOfDay time;
  final String fromAddress;
  final String toAddress;
  final String riderStartAddress;
  final String riderEndAddress;
  final double? riderStartLat;
  final double? riderStartLng;
  final double? riderEndLat;
  final double? riderEndLng;
  final int seatsFilled;
  final int seatsTotal;
  final String status;
  final double? farePerSeat;
  final double? negotiatedPrice;
  final String? negotiationStatus;
  final String vehicleType;
  final int matchPercent;
  final double? distanceKm;

  double? get effectiveFare =>
      (negotiationStatus == 'accepted' && negotiatedPrice != null)
          ? negotiatedPrice
          : farePerSeat;

  RequestedRide({
    required this.id,
    required this.rideId,
    required this.driverId,
    required this.driverName,
    required this.driverPhotoUrl,
    this.driverPhone = '',
    required this.date,
    required this.time,
    required this.fromAddress,
    required this.toAddress,
    required this.riderStartAddress,
    required this.riderEndAddress,
    this.riderStartLat,
    this.riderStartLng,
    this.riderEndLat,
    this.riderEndLng,
    required this.seatsFilled,
    required this.seatsTotal,
    required this.status,
    this.farePerSeat,
    this.negotiatedPrice,
    this.negotiationStatus,
    required this.vehicleType,
    required this.matchPercent,
    this.distanceKm,
  });

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
