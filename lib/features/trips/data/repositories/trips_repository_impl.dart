import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:acepool/core/services/directions_service.dart';
import 'package:acepool/core/utils/ride_matcher.dart';
import 'package:acepool/features/home/domain/entities/upcoming_trip.dart';
import 'package:acepool/features/trips/domain/entities/available_ride.dart';
import 'package:acepool/features/trips/domain/entities/driver_profile_stats.dart';
import 'package:acepool/features/trips/domain/entities/requested_ride.dart';
import 'package:acepool/features/trips/domain/repositories/trips_repository.dart';

class TripsRepositoryImpl implements TripsRepository {
  TripsRepositoryImpl({
    FirebaseFirestore? db,
    FirebaseAuth? firebaseAuth,
    DirectionsService? directions,
  })  : _db = db ??
            FirebaseFirestore.instanceFor(
              app: Firebase.app(),
              databaseId: 'acepool',
            ),
        _auth = firebaseAuth ?? FirebaseAuth.instance,
        _directions = directions ?? DirectionsService();

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final DirectionsService _directions;

  @override
  Future<List<UpcomingTrip>> getTrips(String rideMode) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);

    final snapshot = await _db
        .collection('rides')
        .where('uid', isEqualTo: uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
        .orderBy('date')
        .get();

    return snapshot.docs
        .where((doc) => doc.data()['rideMode'] == rideMode)
        .map((doc) {
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
        vehicleType: data['vehicleType'] as String?,
      );
    }).where((trip) => trip.status != 'completed' && trip.status != 'cancelled').toList();
  }

  @override
  Future<List<AvailableRide>> getAvailableRides({
    String? fromAddress,
    String? toAddress,
    double? fromLat,
    double? fromLng,
    double? toLat,
    double? toLng,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];
    final userDoc = await _db.collection('users').doc(uid).get();

    final matchRadiusKm =
        (userDoc.data()?['routeMatchingRadius'] as num?)?.toDouble() ?? 5.0;

    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);

    final hasCommuteLocation = (fromAddress?.trim().isNotEmpty ?? false) &&
        (toAddress?.trim().isNotEmpty ?? false);
    if (!hasCommuteLocation) return [];

    final userHomeAddress = fromAddress!;
    final userOfficeAddress = toAddress!;
    final userHomeLat = fromLat;
    final userHomeLng = fromLng;
    final userOfficeLat = toLat;
    final userOfficeLng = toLng;

    final snap = await _db
        .collection('rides')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
        .get();

    Map<String, (double? price, String? status)> requestedRideNegotiations = {};
    try {
      final myRequestsSnap = await _db
          .collection('ride_requests')
          .where('riderId', isEqualTo: uid)
          .get();
      for (var d in myRequestsSnap.docs) {
        final data = d.data();
        if (data['status'] == 'cancelled') continue;
        requestedRideNegotiations[data['rideId'] as String] = (
          (data['negotiatedPrice'] as num?)?.toDouble(),
          data['negotiationStatus'] as String?,
        );
      }
    } catch (_) {}

    final rides = <AvailableRide>[];
    for (final doc in snap.docs) {
      final d = doc.data();
      if (d['rideMode'] != 'offer') continue;
      if (d['uid'] == uid) continue;
      final seatCount = d['seatCount'] as int;
      final seatsFilled = (d['seatsFilled'] as int?) ?? 0;
      if (seatsFilled >= seatCount) continue;

      String driverName = '';
      String driverPhotoUrl = '';
      String driverPhone = '';
      try {
        final driverDoc = await _db.collection('users').doc(d['uid'] as String).get();
        driverName = driverDoc.data()?['fullName'] as String? ?? '';
        driverPhotoUrl = driverDoc.data()?['profileImageUrl'] as String? ?? '';
        driverPhone = driverDoc.data()?['phone'] as String? ?? '';
      } catch (_) {}
      if (driverName.isEmpty) driverName = 'Driver';

      final date = (d['date'] as Timestamp).toDate();
      final timeMap = d['time'] as Map<String, dynamic>;
      final rideFrom = d['fromAddress'] as String;
      final rideTo = d['toAddress'] as String;
      final rideFromLat = (d['fromLat'] as num?)?.toDouble() ??
          (d['fromLatLng'] as Map<String, dynamic>?)?['latitude'] as double?;
      final rideFromLng = (d['fromLng'] as num?)?.toDouble() ??
          (d['fromLatLng'] as Map<String, dynamic>?)?['longitude'] as double?;
      final rideToLat = (d['toLat'] as num?)?.toDouble() ??
          (d['toLatLng'] as Map<String, dynamic>?)?['latitude'] as double?;
      final rideToLng = (d['toLng'] as num?)?.toDouble() ??
          (d['toLatLng'] as Map<String, dynamic>?)?['longitude'] as double?;
      final rideRouteDistanceKm = (d['routeDistanceKm'] as num?)?.toDouble();
      final fareMap = d['fare'] as Map<String, dynamic>?;
      final farePerSeat = (fareMap?['farePerSeat'] as num?)?.toDouble();

      // Only worth a live Google Directions call when the user's commute
      // points aren't already close to the ride's own endpoints — that case
      // is already a match without needing a real-route detour check.
      double? liveDetourKm;
      final haveUserCoords = userHomeLat != null &&
          userHomeLng != null &&
          userOfficeLat != null &&
          userOfficeLng != null;
      final haveRideCoords =
          rideFromLat != null && rideFromLng != null && rideToLat != null && rideToLng != null;
      if (haveUserCoords && haveRideCoords && rideRouteDistanceKm != null) {
        final endpointsClose =
            RideMatcher.distanceKm(userHomeLat, userHomeLng, rideFromLat, rideFromLng) <=
                    matchRadiusKm &&
                RideMatcher.distanceKm(userOfficeLat, userOfficeLng, rideToLat, rideToLng) <=
                    matchRadiusKm;
        if (!endpointsClose) {
          final viaDistanceKm = await _directions.fetchRouteDistanceKm(
            originLat: rideFromLat,
            originLng: rideFromLng,
            destLat: rideToLat,
            destLng: rideToLng,
            waypoints: [
              [userHomeLat, userHomeLng],
              [userOfficeLat, userOfficeLng],
            ],
          );
          if (viaDistanceKm != null) {
            liveDetourKm = viaDistanceKm - rideRouteDistanceKm;
          }
        }
      }

      final match = RideMatcher.computeMatch(
        userFromAddress: userHomeAddress,
        userToAddress: userOfficeAddress,
        userFromLat: userHomeLat,
        userFromLng: userHomeLng,
        userToLat: userOfficeLat,
        userToLng: userOfficeLng,
        rideFromAddress: rideFrom,
        rideToAddress: rideTo,
        rideFromLat: rideFromLat,
        rideFromLng: rideFromLng,
        rideToLat: rideToLat,
        rideToLng: rideToLng,
        liveDetourKm: liveDetourKm,
        matchRadiusKm: matchRadiusKm,
      );
      if (!match.isMatch) continue;

      rides.add(AvailableRide(
        id: doc.id,
        driverId: d['uid'] as String,
        driverName: driverName,
        driverPhotoUrl: driverPhotoUrl,
        driverPhone: driverPhone,
        date: date,
        time: TimeOfDay(hour: timeMap['hour'] as int, minute: timeMap['minute'] as int),
        fromAddress: rideFrom,
        toAddress: rideTo,
        fromLat: rideFromLat,
        fromLng: rideFromLng,
        toLat: rideToLat,
        toLng: rideToLng,
        seatsFilled: seatsFilled,
        seatsTotal: seatCount,
        vehicleType: d['vehicleType'] as String? ?? 'car',
        alreadyRequested: requestedRideNegotiations.containsKey(doc.id),
        matchPercent: match.matchPercent,
        distanceKm: match.distanceKm,
        defaultPickupPoint: userHomeAddress.isNotEmpty ? userHomeAddress : rideFrom,
        farePerSeat: farePerSeat,
        negotiatedPrice: requestedRideNegotiations[doc.id]?.$1,
        negotiationStatus: requestedRideNegotiations[doc.id]?.$2,
        userFromAddress: userHomeAddress,
        userToAddress: userOfficeAddress,
        userFromLat: userHomeLat,
        userFromLng: userHomeLng,
        userToLat: userOfficeLat,
        userToLng: userOfficeLng,
      ));
    }

    rides.sort((a, b) => b.matchPercent.compareTo(a.matchPercent));
    return rides;
  }

  @override
  Future<List<RequestedRide>> getRideRequests({
    String? homeFromAddress,
    String? homeToAddress,
    double? homeFromLat,
    double? homeFromLng,
    double? homeToLat,
    double? homeToLng,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    final userDoc = await _db.collection('users').doc(uid).get();
    final matchRadiusKm = (userDoc.data()?['routeMatchingRadius'] as num?)?.toDouble() ?? 5.0;

    final snap = await _db
        .collection('ride_requests')
        .where('riderId', isEqualTo: uid)
        .orderBy('rideDate', descending: true)
        .get();

    final requests = <RequestedRide>[];
    for (final doc in snap.docs) {
      final d = doc.data();
      if (d['status'] == 'completed' || d['status'] == 'cancelled') continue;
      final rideId = d['rideId'] as String;

      final rideDoc = await _db.collection('rides').doc(rideId).get();
      final rideData = rideDoc.data();
      if (rideData == null) continue;

      String driverPhotoUrl = '';
      String driverPhone = '';
      try {
        final driverDoc = await _db.collection('users').doc(d['driverId'] as String).get();
        driverPhotoUrl = driverDoc.data()?['profileImageUrl'] as String? ?? '';
        driverPhone = driverDoc.data()?['phone'] as String? ?? '';
      } catch (_) {}

      final rideTime = d['rideTime'] as Map<String, dynamic>;
      final storedDriverName = d['driverName'] as String?;

      final riderStartLatLng = d['riderStartLatLng'] as Map<String, dynamic>?;
      final riderEndLatLng = d['riderEndLatLng'] as Map<String, dynamic>?;

      final rideFromLat = (rideData['fromLat'] as num?)?.toDouble() ??
          (rideData['fromLatLng'] as Map<String, dynamic>?)?['latitude'] as double?;
      final rideFromLng = (rideData['fromLng'] as num?)?.toDouble() ??
          (rideData['fromLatLng'] as Map<String, dynamic>?)?['longitude'] as double?;
      final rideToLat = (rideData['toLat'] as num?)?.toDouble() ??
          (rideData['toLatLng'] as Map<String, dynamic>?)?['latitude'] as double?;
      final rideToLng = (rideData['toLng'] as num?)?.toDouble() ??
          (rideData['toLatLng'] as Map<String, dynamic>?)?['longitude'] as double?;

      final match = RideMatcher.computeMatch(
        userFromAddress: homeFromAddress ?? '',
        userToAddress: homeToAddress ?? '',
        userFromLat: homeFromLat,
        userFromLng: homeFromLng,
        userToLat: homeToLat,
        userToLng: homeToLng,
        rideFromAddress: rideData['fromAddress'] as String? ?? '',
        rideToAddress: rideData['toAddress'] as String? ?? '',
        rideFromLat: rideFromLat,
        rideFromLng: rideFromLng,
        rideToLat: rideToLat,
        rideToLng: rideToLng,
        matchRadiusKm: matchRadiusKm,
      );

      requests.add(RequestedRide(
        id: doc.id,
        rideId: rideId,
        driverId: d['driverId'] as String? ?? '',
        driverName: (storedDriverName != null && storedDriverName.isNotEmpty)
            ? storedDriverName
            : 'Driver',
        driverPhotoUrl: driverPhotoUrl,
        driverPhone: driverPhone,
        date: (d['rideDate'] as Timestamp).toDate(),
        time: TimeOfDay(hour: rideTime['hour'] as int, minute: rideTime['minute'] as int),
        fromAddress: d['rideFrom'] as String,
        toAddress: d['rideTo'] as String,
        riderStartAddress: d['riderStartAddress'] as String? ?? '',
        riderEndAddress: d['riderEndAddress'] as String? ?? '',
        riderStartLat: (riderStartLatLng?['latitude'] as num?)?.toDouble(),
        riderStartLng: (riderStartLatLng?['longitude'] as num?)?.toDouble(),
        riderEndLat: (riderEndLatLng?['latitude'] as num?)?.toDouble(),
        riderEndLng: (riderEndLatLng?['longitude'] as num?)?.toDouble(),
        seatsFilled: rideData['seatsFilled'] as int? ?? 0,
        seatsTotal: rideData['seatCount'] as int? ?? 0,
        status: d['status'] as String? ?? 'pending',
        farePerSeat: (rideData['fare'] as Map?)?['farePerSeat'] as double?,
        negotiatedPrice: (d['negotiatedPrice'] as num?)?.toDouble(),
        negotiationStatus: d['negotiationStatus'] as String?,
        vehicleType: rideData['vehicleType'] as String? ?? 'car',
        matchPercent: match.matchPercent,
        distanceKm: match.distanceKm,
      ));
    }
    return requests;
  }

  @override
  Future<void> cancelOfferedRide(String tripId, {required String reason}) async {
    await _db.collection('rides').doc(tripId).update({
      'status': 'cancelled',
      'cancellationReason': reason,
      'cancelledAt': FieldValue.serverTimestamp(),
    });

    final requests =
        await _db.collection('ride_requests').where('rideId', isEqualTo: tripId).get();

    final batch = _db.batch();
    for (var doc in requests.docs) {
      batch.update(doc.reference, {
        'status': 'cancelled',
        'cancellationReason': 'Driver cancelled: $reason',
      });
    }
    await batch.commit();
  }

  @override
  Future<void> updateTripStatus(String tripId, String status) async {
    await _db.collection('rides').doc(tripId).update({'status': status});
  }

  @override
  Future<String> requestAvailableRide({
    required AvailableRide ride,
    String message = '',
    double? negotiatedPrice,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return '';

    String riderName = '';
    String? riderPhotoUrl;
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      riderName = userDoc.data()?['fullName'] as String? ?? '';
      riderPhotoUrl = userDoc.data()?['profileImageUrl'] as String?;
    } catch (_) {}

    // Decide if we should meet at driver's endpoints (Endpoint Match)
    // or at rider's requested points (Detour Match).
    bool isEndpointMatch = false;
    if (ride.userFromLat != null &&
        ride.userFromLng != null &&
        ride.fromLat != null &&
        ride.fromLng != null &&
        ride.userToLat != null &&
        ride.userToLng != null &&
        ride.toLat != null &&
        ride.toLng != null) {
      final dFrom =
          RideMatcher.distanceKm(ride.userFromLat!, ride.userFromLng!, ride.fromLat!, ride.fromLng!);
      final dTo =
          RideMatcher.distanceKm(ride.userToLat!, ride.userToLng!, ride.toLat!, ride.toLng!);
      isEndpointMatch =
          dFrom <= RideMatcher.maxMatchDistanceKm && dTo <= RideMatcher.maxMatchDistanceKm;
    }

    final pickupPoint = isEndpointMatch ? ride.fromAddress : 'Pick Up Point';
    final pickupLatLng = isEndpointMatch
        ? {'latitude': ride.fromLat, 'longitude': ride.fromLng}
        : (ride.userFromLat != null && ride.fromLat != null
            ? RideMatcher.projectPointToSegment(ride.fromLat!, ride.fromLng!, ride.toLat!,
                ride.toLng!, ride.userFromLat!, ride.userFromLng!)
            : {'latitude': ride.userFromLat, 'longitude': ride.userFromLng});

    final dropOffPoint = isEndpointMatch ? ride.toAddress : 'Drop Point';
    final dropOffLatLng = isEndpointMatch
        ? {'latitude': ride.toLat, 'longitude': ride.toLng}
        : (ride.userToLat != null && ride.fromLat != null
            ? RideMatcher.projectPointToSegment(ride.fromLat!, ride.fromLng!, ride.toLat!,
                ride.toLng!, ride.userToLat!, ride.userToLng!)
            : {'latitude': ride.userToLat, 'longitude': ride.userToLng});

    final requestRef = _db.collection('ride_requests').doc();
    final rideRef = _db.collection('rides').doc(ride.id);
    final batch = _db.batch();

    batch.set(requestRef, {
      'rideId': ride.id,
      'riderId': uid,
      'riderName': riderName,
      'riderPhotoUrl': riderPhotoUrl,
      'riderStartAddress': ride.userFromAddress,
      'riderEndAddress': ride.userToAddress,
      'riderStartLatLng': (ride.userFromLat != null && ride.userFromLng != null)
          ? {'latitude': ride.userFromLat, 'longitude': ride.userFromLng}
          : null,
      'riderEndLatLng': (ride.userToLat != null && ride.userToLng != null)
          ? {'latitude': ride.userToLat, 'longitude': ride.toLng}
          : null,
      'pickupPoint': pickupPoint,
      'pickupLatLng': pickupLatLng,
      'dropOffPoint': dropOffPoint,
      'dropOffLatLng': dropOffLatLng,
      'pickupTime': {'hour': ride.time.hour, 'minute': ride.time.minute},
      'message': message,
      'negotiatedPrice': negotiatedPrice,
      'status': 'accepted',
      'createdAt': FieldValue.serverTimestamp(),
      'rideFrom': ride.fromAddress,
      'rideTo': ride.toAddress,
      'rideDate': Timestamp.fromDate(ride.date),
      'rideTime': {'hour': ride.time.hour, 'minute': ride.time.minute},
      'driverId': ride.driverId,
      'driverName': ride.driverName,
    });
    batch.update(rideRef, {'seatsFilled': FieldValue.increment(1)});
    await batch.commit();

    return riderName;
  }

  @override
  Future<void> cancelRideRequest({
    required String requestId,
    required String rideId,
    required String reason,
  }) async {
    final batch = _db.batch();
    batch.update(_db.collection('ride_requests').doc(requestId), {
      'status': 'cancelled',
      'cancellationReason': reason,
      'cancelledAt': FieldValue.serverTimestamp(),
    });
    batch.update(_db.collection('rides').doc(rideId), {
      'seatsFilled': FieldValue.increment(-1),
    });
    await batch.commit();
  }

  @override
  Future<DriverProfileStats> getDriverProfileStats(String driverId) async {
    final doc = await _db.collection('users').doc(driverId).get();
    final data = doc.data();
    return DriverProfileStats(
      employeeId: data?['employeeId'] as String? ?? 'ASC 2001922',
      completedRidesCount: data?['completedRidesCount'] as int? ?? 30,
      rating: (data?['rating'] as num?)?.toDouble() ?? 4.72,
      ratingCount: data?['ratingCount'] as int? ?? 15,
    );
  }
}
