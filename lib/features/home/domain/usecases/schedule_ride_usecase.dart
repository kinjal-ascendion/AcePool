import 'package:acepool/core/services/directions_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ScheduleRideUseCase {
  final FirebaseFirestore _db;
  final DirectionsService _directions;

  ScheduleRideUseCase({FirebaseFirestore? db, DirectionsService? directions})
      : _db = db ?? FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'acepool'),
        _directions = directions ?? DirectionsService();

  Future<void> call({
    required String rideMode,
    required String vehicleType,
    required String fromAddress,
    required String toAddress,
    double? fromLat,
    double? fromLng,
    double? toLat,
    double? toLng,
    required DateTime date,
    required TimeOfDay time,
    required int seatCount,
    double? routeDistanceKm,
    int? routeDurationMinutes,
    Map<String, dynamic>? fare,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    // Only re-fetch when the caller hasn't already resolved the route
    // (e.g. on the Pricing screen, which needs it before this is called).
    if (routeDistanceKm == null &&
        fromLat != null &&
        fromLng != null &&
        toLat != null &&
        toLng != null) {
      routeDistanceKm = await _directions.fetchRouteDistanceKm(
        originLat: fromLat,
        originLng: fromLng,
        destLat: toLat,
        destLng: toLng,
      );
    }

    await _db.collection('rides').add({
      'uid': uid,
      'rideMode': rideMode,
      'vehicleType': vehicleType,
      'fromAddress': fromAddress,
      'toAddress': toAddress,
      'fromLat': fromLat,
      'fromLng': fromLng,
      'toLat': toLat,
      'toLng': toLng,
      'routeDistanceKm': routeDistanceKm,
      'routeDurationMinutes': routeDurationMinutes,
      'date': Timestamp.fromDate(date),
      'time': {'hour': time.hour, 'minute': time.minute},
      'seatCount': seatCount,
      'seatsFilled': 0,
      if (fare != null) 'fare': fare,
      'createdAt': FieldValue.serverTimestamp(),
    }).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception('Request timed out. Check your connection.'),
    );
  }
}
