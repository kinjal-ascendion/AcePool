import 'package:acepool/core/services/directions_service.dart';
import 'package:acepool/core/utils/ride_matcher.dart';
import 'package:acepool/features/rides/domain/entities/ride_match.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class FindMatchingRidesUseCase {
  final FirebaseFirestore _db;
  final DirectionsService _directions;

  FindMatchingRidesUseCase({FirebaseFirestore? db, DirectionsService? directions})
      : _db = db ?? FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'acepool'),
        _directions = directions ?? DirectionsService();

  Future<List<RideMatch>> call({
    required String fromAddress,
    required String toAddress,
    double? fromLat,
    double? fromLng,
    double? toLat,
    double? toLng,
    required DateTime date,
    required TimeOfDay time,
    required String vehicleType,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    // Kick off the independent reads together instead of awaiting them one
    // at a time — each .get() starts its network call immediately.
    final userDocFuture = _db.collection('users').doc(uid).get();
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final ridesSnapFuture = _db
        .collection('rides')
        .where('rideMode', isEqualTo: 'offer')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .get();
    final myRequestsSnapFuture = _db
        .collection('ride_requests')
        .where('riderId', isEqualTo: uid)
        .where('status', isEqualTo: 'accepted')
        .get();

    final userDoc = await userDocFuture;
    final snap = await ridesSnapFuture;
    final myRequestsSnap = await myRequestsSnapFuture;

    final matchRadiusKm =
        (userDoc.data()?['routeMatchingRadius'] as num?)?.toDouble() ?? 5.0;

    final requestedRideIds = myRequestsSnap.docs
        .map((d) => d.data()['rideId'] as String)
        .toSet();

    final candidates = snap.docs.where((doc) {
      final d = doc.data();
      if (d['uid'] == uid) return false;
      final rideVehicleType = d['vehicleType'] as String? ?? 'car';
      if (rideVehicleType != vehicleType) return false;
      final seatCount = d['seatCount'] as int;
      final seatsFilled = (d['seatsFilled'] as int?) ?? 0;
      if (seatsFilled >= seatCount) return false;
      return true;
    }).toList();

    // Fetch each distinct driver's profile once, in parallel, instead of
    // once per ride inside the loop below.
    final driverIds = candidates.map((doc) => doc.data()['uid'] as String).toSet();
    final driverProfiles = <String, ({String name, String? photoUrl})>{};
    await Future.wait(driverIds.map((driverId) async {
      try {
        final driverDoc = await _db.collection('users').doc(driverId).get();
        final dd = driverDoc.data();
        driverProfiles[driverId] = (
          name: dd?['fullName'] as String? ?? '',
          photoUrl: dd?['profileImageUrl'] as String?,
        );
      } catch (_) {
        driverProfiles[driverId] = (name: '', photoUrl: null);
      }
    }));

    final matchResults = await Future.wait(candidates.map((doc) async {
      final d = doc.data();
      final rideVehicleType = d['vehicleType'] as String? ?? 'car';
      final seatCount = d['seatCount'] as int;
      final seatsFilled = (d['seatsFilled'] as int?) ?? 0;
      final rideFrom = d['fromAddress'] as String;
      final rideTo = d['toAddress'] as String;
      final rideFromLat = (d['fromLat'] as num?)?.toDouble();
      final rideFromLng = (d['fromLng'] as num?)?.toDouble();
      final rideToLat = (d['toLat'] as num?)?.toDouble();
      final rideToLng = (d['toLng'] as num?)?.toDouble();
      final rideRouteDistanceKm = (d['routeDistanceKm'] as num?)?.toDouble();
      final fareMap = d['fare'] as Map<String, dynamic>?;
      final farePerSeat = (fareMap?['farePerSeat'] as num?)?.toDouble();

      // Only worth a live Google Directions call when the rider's points
      // aren't already close to the ride's own endpoints — that case is
      // already a match without needing a real-route detour check.
      double? liveDetourKm;
      final haveSearchCoords =
          fromLat != null && fromLng != null && toLat != null && toLng != null;
      final haveRideCoords = rideFromLat != null &&
          rideFromLng != null &&
          rideToLat != null &&
          rideToLng != null;
      if (haveSearchCoords && haveRideCoords && rideRouteDistanceKm != null) {
        final endpointsClose =
            RideMatcher.distanceKm(fromLat, fromLng, rideFromLat, rideFromLng) <=
                    RideMatcher.maxMatchDistanceKm &&
                RideMatcher.distanceKm(toLat, toLng, rideToLat, rideToLng) <=
                    RideMatcher.maxMatchDistanceKm;
        if (!endpointsClose) {
          final viaDistanceKm = await _directions.fetchRouteDistanceKm(
            originLat: rideFromLat,
            originLng: rideFromLng,
            destLat: rideToLat,
            destLng: rideToLng,
            waypoints: [
              [fromLat, fromLng],
              [toLat, toLng],
            ],
          );
          if (viaDistanceKm != null) {
            liveDetourKm = viaDistanceKm - rideRouteDistanceKm;
          }
        }
      }

      final match = RideMatcher.computeMatch(
        userFromAddress: fromAddress,
        userToAddress: toAddress,
        userFromLat: fromLat,
        userFromLng: fromLng,
        userToLat: toLat,
        userToLng: toLng,
        rideFromAddress: rideFrom,
        rideToAddress: rideTo,
        rideFromLat: rideFromLat,
        rideFromLng: rideFromLng,
        rideToLat: rideToLat,
        rideToLng: rideToLng,
        liveDetourKm: liveDetourKm,
        matchRadiusKm: matchRadiusKm,
      );
      if (!match.isMatch) return null;
      final fromDistanceKm = match.distanceKm;
      final matchPercent = match.matchPercent;

      final driverId = d['uid'] as String;
      final driver = driverProfiles[driverId];

      final rideDate = (d['date'] as Timestamp).toDate();
      final timeMap = d['time'] as Map<String, dynamic>;

      return RideMatch(
        id: doc.id,
        driverId: driverId,
        driverName: driver?.name ?? '',
        driverPhotoUrl: driver?.photoUrl,
        date: rideDate,
        time: TimeOfDay(
            hour: timeMap['hour'] as int, minute: timeMap['minute'] as int),
        fromAddress: rideFrom,
        toAddress: rideTo,
        seatsFilled: seatsFilled,
        seatsTotal: seatCount,
        vehicleType: rideVehicleType,
        alreadyRequested: requestedRideIds.contains(doc.id),
        distanceKm: fromDistanceKm,
        matchPercent: matchPercent,
        farePerSeat: farePerSeat,
        fromLat: rideFromLat,
        fromLng: rideFromLng,
        toLat: rideToLat,
        toLng: rideToLng,
      );
    }));

    final results = matchResults.whereType<RideMatch>().toList();

    results.sort((a, b) {
      if (a.distanceKm == null && b.distanceKm == null) return 0;
      if (a.distanceKm == null) return 1;
      if (b.distanceKm == null) return -1;
      return a.distanceKm!.compareTo(b.distanceKm!);
    });

    return results;
  }
}
