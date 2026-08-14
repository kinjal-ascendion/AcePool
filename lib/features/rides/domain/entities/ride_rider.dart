import 'package:flutter/material.dart';

/// A rider whose request on a driver's ride has a given status
/// (used by the driver-facing "riders confirmed" list).
class RideRider {
  const RideRider({
    required this.requestId,
    required this.riderId,
    required this.riderName,
    this.riderPhotoUrl,
    required this.employeeId,
    required this.pickupPoint,
    this.pickupLat,
    this.pickupLng,
    this.dropOffLat,
    this.dropOffLng,
    required this.pickupTime,
    this.negotiatedPrice,
    this.negotiationStatus,
  });

  final String requestId;
  final String riderId;
  final String riderName;
  final String? riderPhotoUrl;
  final String employeeId;
  final String pickupPoint;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropOffLat;
  final double? dropOffLng;
  final TimeOfDay pickupTime;
  final double? negotiatedPrice;
  final String? negotiationStatus;

  String get pickupTimeLabel {
    final h = pickupTime.hourOfPeriod == 0 ? 12 : pickupTime.hourOfPeriod;
    final m = pickupTime.minute.toString().padLeft(2, '0');
    final period = pickupTime.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }
}
