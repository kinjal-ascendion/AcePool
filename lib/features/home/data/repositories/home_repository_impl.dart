import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:acepool/core/services/directions_service.dart';
import 'package:acepool/features/home/domain/entities/upcoming_trip.dart';
import 'package:acepool/features/home/domain/entities/vehicle_option.dart';
import 'package:acepool/features/home/domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl({FirebaseFirestore? db, DirectionsService? directions})
      : _db = db ??
            FirebaseFirestore.instanceFor(
              app: Firebase.app(),
              databaseId: 'acepool',
            ),
        _directions = directions ?? DirectionsService();

  final FirebaseFirestore _db;
  final DirectionsService _directions;

  @override
  Future<List<UpcomingTrip>> getUpcomingTrips() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);

    final snapshot = await _db
        .collection('rides')
        .where('uid', isEqualTo: uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
        .orderBy('date')
        .limit(3)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final date = (data['date'] as Timestamp).toDate();
      final timeMap = data['time'] as Map<String, dynamic>;

      final fromLat = (data['fromLat'] as num?)?.toDouble();
      final fromLng = (data['fromLng'] as num?)?.toDouble();
      final toLat = (data['toLat'] as num?)?.toDouble();
      final toLng = (data['toLng'] as num?)?.toDouble();

      final fromLatLngMap = data['fromLatLng'] as Map<String, dynamic>?;
      final toLatLngMap = data['toLatLng'] as Map<String, dynamic>?;
      final fareMap = data['fare'] as Map<String, dynamic>?;

      return UpcomingTrip(
        id: doc.id,
        date: DateTime(date.year, date.month, date.day),
        time: TimeOfDay(
          hour: timeMap['hour'] as int,
          minute: timeMap['minute'] as int,
        ),
        fromAddress: data['fromAddress'] as String,
        toAddress: data['toAddress'] as String,
        fromLat: fromLat ?? (fromLatLngMap?['latitude'] as num?)?.toDouble(),
        fromLng: fromLng ?? (fromLatLngMap?['longitude'] as num?)?.toDouble(),
        toLat: toLat ?? (toLatLngMap?['latitude'] as num?)?.toDouble(),
        toLng: toLng ?? (toLatLngMap?['longitude'] as num?)?.toDouble(),
        seatsFilled: (data['seatsFilled'] as int?) ?? 0,
        seatsTotal: data['seatCount'] as int,
        farePerSeat: (fareMap?['farePerSeat'] as num?)?.toDouble(),
        note: data['note'] as String?,
        durationMinutes: (data['routeDurationMinutes'] as num?)?.toInt(),
        status: data['status'] as String? ?? 'upcoming',
      );
    }).where((trip) => trip.status != 'completed' && trip.status != 'cancelled').toList();
  }

  @override
  Future<void> scheduleRide({
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

  @override
  Future<RouteDetails> estimateRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final route = await _directions.fetchRouteDetails(
      originLat: originLat,
      originLng: originLng,
      destLat: destLat,
      destLng: destLng,
    );
    if (route != null) return route;

    // Directions API unreachable (billing disabled, no network, quota,
    // etc.) — fall back to a straight-line estimate so the Pricing screen
    // always has a real starting distance/duration instead of showing 0.
    const straightLineRoadFactor = 1.3;
    const averageSpeedKmh = 30.0;
    final distanceKm =
        _haversineKm(originLat, originLng, destLat, destLng) * straightLineRoadFactor;
    final durationMinutes = (distanceKm / averageSpeedKmh * 60).round();
    return RouteDetails(distanceKm: distanceKm, durationMinutes: durationMinutes);
  }

  @override
  Future<String?> getTravelPreference() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;

    return (doc.data()?['travelPreference'] as String?) ??
        (doc.data()?['travel_preference'] as String?);
  }

  @override
  Future<List<VehicleOption>> getVehicleOptions(String vehicleType) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const [];

    final expectedType = vehicleType == 'bike' ? 'two_wheeler' : 'four_wheeler';
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('vehicles')
        .where('type', isEqualTo: expectedType)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final brand = data['brand'] as String? ?? '';
      final model = data['model'] as String? ?? '';
      final label = [brand, model].where((s) => s.isNotEmpty).join(' ');
      return VehicleOption(
        id: doc.id,
        label: label.isNotEmpty ? label : 'Vehicle',
        type: data['type'] as String? ?? expectedType,
      );
    }).toList();
  }

  double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180);
}
