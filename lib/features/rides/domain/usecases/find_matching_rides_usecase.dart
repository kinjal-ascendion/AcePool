import 'package:acepool/core/utils/ride_matcher.dart';
import 'package:acepool/features/rides/domain/entities/ride_match.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class FindMatchingRidesUseCase {
  final FirebaseFirestore _db;

  FindMatchingRidesUseCase({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'acepool');

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

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snap = await _db
        .collection('rides')
        .where('rideMode', isEqualTo: 'offer')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    final myRequestsSnap = await _db
        .collection('ride_requests')
        .where('riderId', isEqualTo: uid)
        .where('status', isEqualTo: 'accepted')
        .get();
    final requestedRideIds = myRequestsSnap.docs
        .map((d) => d.data()['rideId'] as String)
        .toSet();

    final results = <RideMatch>[];
    for (final doc in snap.docs) {
      final d = doc.data();
      if (d['uid'] == uid) continue;
      final rideVehicleType = d['vehicleType'] as String? ?? 'car';
      if (rideVehicleType != vehicleType) continue;
      final seatCount = d['seatCount'] as int;
      final seatsFilled = (d['seatsFilled'] as int?) ?? 0;
      if (seatsFilled >= seatCount) continue;

      final rideFrom = d['fromAddress'] as String;
      final rideTo = d['toAddress'] as String;
      final rideFromLat = (d['fromLat'] as num?)?.toDouble();
      final rideFromLng = (d['fromLng'] as num?)?.toDouble();
      final rideToLat = (d['toLat'] as num?)?.toDouble();
      final rideToLng = (d['toLng'] as num?)?.toDouble();

      final haveSearchCoords =
          fromLat != null && fromLng != null && toLat != null && toLng != null;
      final haveRideCoords = rideFromLat != null &&
          rideFromLng != null &&
          rideToLat != null &&
          rideToLng != null;

      double? fromDistanceKm;
      int matchPercent;
      bool isMatch;
      if (haveSearchCoords && haveRideCoords) {
        fromDistanceKm =
            RideMatcher.distanceKm(fromLat, fromLng, rideFromLat, rideFromLng);
        final toDistanceKm =
            RideMatcher.distanceKm(toLat, toLng, rideToLat, rideToLng);
        final endpointsMatch = fromDistanceKm <= RideMatcher.maxMatchDistanceKm &&
            toDistanceKm <= RideMatcher.maxMatchDistanceKm;

        // Also accept the rider's pickup/drop being somewhere in between the
        // driver's start and end (an "on the way" match), even when they're
        // nowhere near the driver's own endpoints.
        final fromDeviationKm = RideMatcher.routeDeviationKm(
            rideFromLat, rideFromLng, fromLat, fromLng, rideToLat, rideToLng);
        final toDeviationKm = RideMatcher.routeDeviationKm(
            rideFromLat, rideFromLng, toLat, toLng, rideToLat, rideToLng);
        final fromProgress = RideMatcher.routeProgress(
            rideFromLat, rideFromLng, fromLat, fromLng, rideToLat, rideToLng);
        final toProgress = RideMatcher.routeProgress(
            rideFromLat, rideFromLng, toLat, toLng, rideToLat, rideToLng);
        final onRoute = fromDeviationKm <= RideMatcher.maxRouteDeviationKm &&
            toDeviationKm <= RideMatcher.maxRouteDeviationKm &&
            fromProgress <= toProgress;

        isMatch = endpointsMatch || onRoute;

        if (endpointsMatch) {
          final worstKm = fromDistanceKm > toDistanceKm ? fromDistanceKm : toDistanceKm;
          matchPercent = RideMatcher.matchPercentFromDistance(worstKm);
        } else {
          final worstDeviationKm =
              fromDeviationKm > toDeviationKm ? fromDeviationKm : toDeviationKm;
          matchPercent = RideMatcher.matchPercentFromDistance(
            worstDeviationKm,
            scaleKm: RideMatcher.maxRouteDeviationKm,
          );
        }
      } else {
        isMatch = RideMatcher.fuzzyAddressMatches(rideFrom, fromAddress) &&
            RideMatcher.fuzzyAddressMatches(rideTo, toAddress);
        fromDistanceKm = null;
        matchPercent = 100;
      }
      if (!isMatch) continue;

      String driverName = '';
      String? driverPhotoUrl;
      try {
        final driverDoc = await _db.collection('users').doc(d['uid'] as String).get();
        final dd = driverDoc.data();
        driverName = dd?['fullName'] as String? ?? '';
        driverPhotoUrl = dd?['profileImageUrl'] as String?;
      } catch (_) {}

      final rideDate = (d['date'] as Timestamp).toDate();
      final timeMap = d['time'] as Map<String, dynamic>;

      results.add(RideMatch(
        id: doc.id,
        driverId: d['uid'] as String,
        driverName: driverName,
        driverPhotoUrl: driverPhotoUrl,
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
      ));
    }

    results.sort((a, b) {
      if (a.distanceKm == null && b.distanceKm == null) return 0;
      if (a.distanceKm == null) return 1;
      if (b.distanceKm == null) return -1;
      return a.distanceKm!.compareTo(b.distanceKm!);
    });

    return results;
  }
}
