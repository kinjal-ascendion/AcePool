import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:acepool/core/services/directions_service.dart';
import 'package:acepool/core/utils/ride_matcher.dart';
import 'package:acepool/features/chat/domain/entities/chat_message.dart';
import 'package:acepool/features/chat/domain/repositories/chat_repository.dart';
import 'package:acepool/features/rides/domain/entities/ride_match.dart';
import 'package:acepool/features/rides/domain/entities/ride_rider.dart';
import 'package:acepool/features/rides/domain/entities/rider_journey.dart';
import 'package:acepool/features/rides/domain/repositories/rides_repository.dart';

class RidesRepositoryImpl implements RidesRepository {
  RidesRepositoryImpl({
    required ChatRepository chatRepository,
    FirebaseFirestore? db,
    DirectionsService? directions,
  })  : _chatRepository = chatRepository,
        _db = db ??
            FirebaseFirestore.instanceFor(
              app: Firebase.app(),
              databaseId: 'acepool',
            ),
        _directions = directions ?? DirectionsService();

  final ChatRepository _chatRepository;
  final FirebaseFirestore _db;
  final DirectionsService _directions;

  @override
  Future<List<RideMatch>> findMatchingRides({
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

    final requestedRideIds =
        myRequestsSnap.docs.map((d) => d.data()['rideId'] as String).toSet();

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
    final driverProfiles = <String, ({String name, String? photoUrl, String? phone})>{};
    await Future.wait(driverIds.map((driverId) async {
      try {
        final driverDoc = await _db.collection('users').doc(driverId).get();
        final dd = driverDoc.data();
        driverProfiles[driverId] = (
          name: dd?['fullName'] as String? ?? '',
          photoUrl: dd?['profileImageUrl'] as String?,
          phone: dd?['phone'] as String?,
        );
      } catch (_) {
        driverProfiles[driverId] = (name: '', photoUrl: null, phone: null);
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
        driverPhone: driver?.phone,
        date: rideDate,
        time: TimeOfDay(hour: timeMap['hour'] as int, minute: timeMap['minute'] as int),
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

  @override
  Future<String> requestRide({
    required RideMatch ride,
    required String riderFromAddress,
    double? riderFromLat,
    double? riderFromLng,
    required String riderToAddress,
    double? riderToLat,
    double? riderToLng,
    required TimeOfDay riderTime,
    String message = '',
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
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
    if (riderFromLat != null &&
        riderFromLng != null &&
        ride.fromLat != null &&
        ride.fromLng != null &&
        riderToLat != null &&
        riderToLng != null &&
        ride.toLat != null &&
        ride.toLng != null) {
      final dFrom = RideMatcher.distanceKm(
          riderFromLat, riderFromLng, ride.fromLat!, ride.fromLng!);
      final dTo =
          RideMatcher.distanceKm(riderToLat, riderToLng, ride.toLat!, ride.toLng!);
      isEndpointMatch = dFrom <= RideMatcher.maxMatchDistanceKm &&
          dTo <= RideMatcher.maxMatchDistanceKm;
    }

    final pickupPoint = isEndpointMatch ? ride.fromAddress : riderFromAddress;
    final pickupLatLng = isEndpointMatch
        ? {'latitude': ride.fromLat, 'longitude': ride.fromLng}
        : (riderFromLat != null && ride.fromLat != null
            ? RideMatcher.projectPointToSegment(ride.fromLat!, ride.fromLng!,
                ride.toLat!, ride.toLng!, riderFromLat, riderFromLng!)
            : {'latitude': riderFromLat, 'longitude': riderFromLng});

    final dropOffPoint = isEndpointMatch ? ride.toAddress : riderToAddress;
    final dropOffLatLng = isEndpointMatch
        ? {'latitude': ride.toLat, 'longitude': ride.toLng}
        : (riderToLat != null && ride.fromLat != null
            ? RideMatcher.projectPointToSegment(ride.fromLat!, ride.fromLng!,
                ride.toLat!, ride.toLng!, riderToLat, riderToLng!)
            : {'latitude': riderToLat, 'longitude': riderToLng});

    final requestRef = _db.collection('ride_requests').doc();
    final rideRef = _db.collection('rides').doc(ride.id);
    final batch = _db.batch();
    batch.set(requestRef, {
      'rideId': ride.id,
      'riderId': uid,
      'riderName': riderName,
      'riderPhotoUrl': riderPhotoUrl,
      'riderStartAddress': riderFromAddress,
      'riderEndAddress': riderToAddress,
      'riderStartLatLng': (riderFromLat != null && riderFromLng != null)
          ? {'latitude': riderFromLat, 'longitude': riderFromLng}
          : null,
      'riderEndLatLng': (riderToLat != null && riderToLng != null)
          ? {'latitude': riderToLat, 'longitude': riderToLng}
          : null,
      'pickupPoint': pickupPoint,
      'pickupLatLng': pickupLatLng,
      'dropOffPoint': dropOffPoint,
      'dropOffLatLng': dropOffLatLng,
      'pickupTime': {'hour': riderTime.hour, 'minute': riderTime.minute},
      'message': message,
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
  Future<List<RideRider>> getAcceptedRiders({
    required String rideId,
    String? driverId,
    String status = 'accepted',
  }) async {
    Query<Map<String, dynamic>> query = _db
        .collection('ride_requests')
        .where('rideId', isEqualTo: rideId)
        .where('status', isEqualTo: status);
    if (driverId != null) {
      query = query.where('driverId', isEqualTo: driverId);
    }
    final snap = await query.get();

    final riders = <RideRider>[];
    for (final doc in snap.docs) {
      final d = doc.data();
      String employeeId = '';
      try {
        final userDoc = await _db.collection('users').doc(d['riderId'] as String).get();
        employeeId = userDoc.data()?['employeeId'] as String? ?? '';
      } catch (_) {}

      final pickupTimeMap =
          d['pickupTime'] as Map<String, dynamic>? ?? {'hour': 0, 'minute': 0};

      double? pickupLat;
      double? pickupLng;
      if (d['pickupLatLng'] != null) {
        final m = d['pickupLatLng'] as Map<String, dynamic>;
        pickupLat = (m['latitude'] as num?)?.toDouble();
        pickupLng = (m['longitude'] as num?)?.toDouble();
      }

      double? dropOffLat;
      double? dropOffLng;
      if (d['dropOffLatLng'] != null) {
        final m = d['dropOffLatLng'] as Map<String, dynamic>;
        dropOffLat = (m['latitude'] as num?)?.toDouble();
        dropOffLng = (m['longitude'] as num?)?.toDouble();
      }

      riders.add(RideRider(
        requestId: doc.id,
        riderId: d['riderId'] as String? ?? '',
        riderName: d['riderName'] as String? ?? '',
        riderPhotoUrl: d['riderPhotoUrl'] as String?,
        employeeId: employeeId,
        pickupPoint: d['pickupPoint'] as String? ?? '',
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        dropOffLat: dropOffLat,
        dropOffLng: dropOffLng,
        pickupTime: TimeOfDay(
          hour: (pickupTimeMap['hour'] as num).toInt(),
          minute: (pickupTimeMap['minute'] as num).toInt(),
        ),
      ));
    }

    if (status == 'accepted') {
      await reconcileSeatsFilled(rideId, riders.length);
    }

    return riders;
  }

  @override
  Future<List<RideRider>> getOtherRiders(String rideId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final snap = await _db
        .collection('ride_requests')
        .where('rideId', isEqualTo: rideId)
        .where('status', isEqualTo: 'accepted')
        .get();

    final riders = <RideRider>[];
    for (final doc in snap.docs) {
      final d = doc.data();
      final riderId = d['riderId'] as String? ?? '';

      if (riderId == uid) continue;

      String employeeId = 'AE2610002'; // Default placeholder
      try {
        final userDoc = await _db.collection('users').doc(riderId).get();
        employeeId = userDoc.data()?['employeeId'] as String? ?? 'AE2610002';
      } catch (_) {}

      final pickupTimeMap =
          d['pickupTime'] as Map<String, dynamic>? ?? {'hour': 0, 'minute': 0};

      double? pickupLat;
      double? pickupLng;
      if (d['pickupLatLng'] != null) {
        final m = d['pickupLatLng'] as Map<String, dynamic>;
        pickupLat = (m['latitude'] as num).toDouble();
        pickupLng = (m['longitude'] as num).toDouble();
      }

      riders.add(RideRider(
        requestId: doc.id,
        riderId: riderId,
        riderName: d['riderName'] as String? ?? '',
        riderPhotoUrl: d['riderPhotoUrl'] as String?,
        employeeId: employeeId,
        pickupPoint: d['pickupPoint'] as String? ?? '',
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        pickupTime: TimeOfDay(
          hour: (pickupTimeMap['hour'] as num).toInt(),
          minute: (pickupTimeMap['minute'] as num).toInt(),
        ),
      ));
    }
    return riders;
  }

  @override
  Future<String> requestRideFromDetails({
    required RideMatch ride,
    String? riderFromAddress,
    double? riderFromLat,
    double? riderFromLng,
    String? riderToAddress,
    double? riderToLat,
    double? riderToLng,
    String message = '',
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
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
    if (riderFromLat != null &&
        riderFromLng != null &&
        ride.fromLat != null &&
        ride.fromLng != null &&
        riderToLat != null &&
        riderToLng != null &&
        ride.toLat != null &&
        ride.toLng != null) {
      final dFrom = RideMatcher.distanceKm(
          riderFromLat, riderFromLng, ride.fromLat!, ride.fromLng!);
      final dTo =
          RideMatcher.distanceKm(riderToLat, riderToLng, ride.toLat!, ride.toLng!);
      isEndpointMatch = dFrom <= RideMatcher.maxMatchDistanceKm &&
          dTo <= RideMatcher.maxMatchDistanceKm;
    }

    final pickupPoint =
        isEndpointMatch ? ride.fromAddress : (riderFromAddress ?? ride.fromAddress);
    final pickupLatLng = isEndpointMatch
        ? {'latitude': ride.fromLat, 'longitude': ride.fromLng}
        : (riderFromLat != null && ride.fromLat != null
            ? RideMatcher.projectPointToSegment(ride.fromLat!, ride.fromLng!,
                ride.toLat!, ride.toLng!, riderFromLat, riderFromLng!)
            : {
                'latitude': riderFromLat ?? ride.fromLat,
                'longitude': riderFromLng ?? ride.fromLng,
              });

    final dropOffPoint =
        isEndpointMatch ? ride.toAddress : (riderToAddress ?? ride.toAddress);
    final dropOffLatLng = isEndpointMatch
        ? {'latitude': ride.toLat, 'longitude': ride.toLng}
        : (riderToLat != null && ride.fromLat != null
            ? RideMatcher.projectPointToSegment(ride.fromLat!, ride.fromLng!,
                ride.toLat!, ride.toLng!, riderToLat, riderToLng!)
            : {
                'latitude': riderToLat ?? ride.toLat,
                'longitude': riderToLng ?? ride.toLng,
              });

    final requestRef = _db.collection('ride_requests').doc();
    final rideRef = _db.collection('rides').doc(ride.id);

    final batch = _db.batch();
    batch.set(requestRef, {
      'rideId': ride.id,
      'riderId': uid,
      'riderName': riderName,
      'riderPhotoUrl': riderPhotoUrl,
      'riderStartAddress': riderFromAddress ?? ride.fromAddress,
      'riderEndAddress': riderToAddress ?? ride.toAddress,
      'riderStartLatLng': (riderFromLat != null && riderFromLng != null)
          ? {'latitude': riderFromLat, 'longitude': riderFromLng}
          : null,
      'riderEndLatLng': (riderToLat != null && riderToLng != null)
          ? {'latitude': riderToLat, 'longitude': riderToLng}
          : null,
      'pickupPoint': pickupPoint,
      'pickupLatLng': pickupLatLng,
      'dropOffPoint': dropOffPoint,
      'dropOffLatLng': dropOffLatLng,
      'pickupTime': {'hour': ride.time.hour, 'minute': ride.time.minute},
      'message': message,
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
  Future<List<RideRider>> getRidersForCurrentDriver({
    required String rideId,
    String status = 'accepted',
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];
    return getAcceptedRiders(rideId: rideId, driverId: uid, status: status);
  }

  @override
  Future<void> cancelRiderRequest({
    required String requestId,
    required String rideId,
  }) async {
    await _db.collection('ride_requests').doc(requestId).update({'status': 'rejected'});

    final rideRef = _db.collection('rides').doc(rideId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(rideRef);
      final current = (snap.data()?['seatsFilled'] as int?) ?? 0;
      if (current > 0) {
        tx.update(rideRef, {'seatsFilled': current - 1});
      }
    });
  }

  @override
  Future<void> updateRideStatus(String rideId, String status) async {
    await _db.collection('rides').doc(rideId).update({'status': status});
  }

  @override
  Future<void> cancelRide(String rideId, {required String reason}) async {
    await _db.collection('rides').doc(rideId).update({
      'status': 'cancelled',
      'cancellationReason': reason,
      'cancelledAt': FieldValue.serverTimestamp(),
    });

    final requests =
        await _db.collection('ride_requests').where('rideId', isEqualTo: rideId).get();

    final batch = _db.batch();
    for (final doc in requests.docs) {
      batch.update(doc.reference, {
        'status': 'cancelled',
        'cancellationReason': 'Driver cancelled: $reason',
      });
    }
    await batch.commit();
  }

  @override
  Future<void> reconcileSeatsFilled(String rideId, int acceptedCount) async {
    final rideRef = _db.collection('rides').doc(rideId);
    final snap = await rideRef.get();
    final current = (snap.data()?['seatsFilled'] as int?) ?? 0;
    if (current != acceptedCount) {
      await rideRef.update({'seatsFilled': acceptedCount});
    }
  }

  @override
  Future<bool> isRideOwnedByCurrentUser(String rideId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final doc = await _db.collection('rides').doc(rideId).get();
    if (!doc.exists) return false;
    return doc.data()?['uid'] == uid;
  }

  @override
  Stream<String?> watchRideNote(String rideId) {
    return _db.collection('rides').doc(rideId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return snapshot.data()?['note'] as String?;
    });
  }

  @override
  Future<void> updateRideNote(String rideId, String note) async {
    await _db.collection('rides').doc(rideId).update({'note': note});
  }

  @override
  Future<RiderJourney> getRiderJourney({
    required RideMatch ride,
    String? riderFromAddress,
    double? riderFromLat,
    double? riderFromLng,
    String? riderToAddress,
    double? riderToLat,
    double? riderToLng,
  }) async {
    var startAddress = riderFromAddress ?? '';
    var endAddress = riderToAddress ?? '';
    var startLat = riderFromLat;
    var startLng = riderFromLng;
    var endLat = riderToLat;
    var endLng = riderToLng;

    var pickupPoint = ride.fromAddress;
    var dropOffPoint = ride.toAddress;
    double? pickupLat;
    double? pickupLng;
    double? dropOffLat;
    double? dropOffLng;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final requestSnap = await _db
          .collection('ride_requests')
          .where('rideId', isEqualTo: ride.id)
          .where('riderId', isEqualTo: uid)
          .where('status', isEqualTo: 'accepted')
          .limit(1)
          .get();

      if (requestSnap.docs.isNotEmpty) {
        final d = requestSnap.docs.first.data();
        pickupPoint = d['pickupPoint'] as String? ?? pickupPoint;
        dropOffPoint = d['dropOffPoint'] as String? ?? dropOffPoint;

        if (startAddress.isEmpty) {
          startAddress = d['riderStartAddress'] as String? ?? '';
        }
        if (endAddress.isEmpty) {
          endAddress = d['riderEndAddress'] as String? ?? '';
        }

        if (d['pickupLatLng'] != null) {
          final m = d['pickupLatLng'] as Map<String, dynamic>;
          pickupLat = (m['latitude'] as num?)?.toDouble();
          pickupLng = (m['longitude'] as num?)?.toDouble();
        }
        if (d['dropOffLatLng'] != null) {
          final m = d['dropOffLatLng'] as Map<String, dynamic>;
          dropOffLat = (m['latitude'] as num?)?.toDouble();
          dropOffLng = (m['longitude'] as num?)?.toDouble();
        }
        if (startLat == null && d['riderStartLatLng'] != null) {
          final m = d['riderStartLatLng'] as Map<String, dynamic>;
          startLat = (m['latitude'] as num?)?.toDouble();
          startLng = (m['longitude'] as num?)?.toDouble();
        }
        if (endLat == null && d['riderEndLatLng'] != null) {
          final m = d['riderEndLatLng'] as Map<String, dynamic>;
          endLat = (m['latitude'] as num?)?.toDouble();
          endLng = (m['longitude'] as num?)?.toDouble();
        }
      } else {
        // If no accepted request, use driver's start/end as default
        // pickup/drop-off for visualization (matches original behavior).
        pickupPoint = ride.fromAddress;
        dropOffPoint = ride.toAddress;
      }
    }

    double? pinnedLat;
    double? pinnedLng;
    String? pinnedName;
    var driveDurationMinutes = 20;

    final rideDoc = await _db.collection('rides').doc(ride.id).get();
    if (rideDoc.exists) {
      final d = rideDoc.data();
      if (d?['pinnedLatLng'] != null) {
        final m = d!['pinnedLatLng'] as Map<String, dynamic>;
        pinnedLat = (m['latitude'] as num?)?.toDouble();
        pinnedLng = (m['longitude'] as num?)?.toDouble();
        pinnedName = d['pinnedName'] as String?;
      }
      if (d?['routeDurationMinutes'] != null) {
        driveDurationMinutes = (d!['routeDurationMinutes'] as num).toInt();
      }
    }

    return RiderJourney(
      pickupPoint: pickupPoint,
      dropOffPoint: dropOffPoint,
      riderStartAddress: startAddress,
      riderEndAddress: endAddress,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropOffLat: dropOffLat,
      dropOffLng: dropOffLng,
      riderStartLat: startLat,
      riderStartLng: startLng,
      riderEndLat: endLat,
      riderEndLng: endLng,
      pinnedLat: pinnedLat,
      pinnedLng: pinnedLng,
      pinnedName: pinnedName,
      driveDurationMinutes: driveDurationMinutes,
    );
  }

  @override
  Future<void> completeRide({
    required String rideId,
    required String paymentMethod,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final requestSnap = await _db
        .collection('ride_requests')
        .where('rideId', isEqualTo: rideId)
        .where('riderId', isEqualTo: uid)
        .limit(1)
        .get()
        .timeout(const Duration(seconds: 10));

    if (requestSnap.docs.isNotEmpty) {
      await requestSnap.docs.first.reference.update({
        'status': 'completed',
        'paymentMethod': paymentMethod,
        'completedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 5));
    }
  }

  @override
  Future<void> sendRideChatMessage({
    required String driverId,
    required String driverName,
    required String text,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    String senderName = '';
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      senderName = userDoc.data()?['fullName'] as String? ?? 'User';
    } catch (_) {}

    final ids = [uid, driverId]..sort();
    final chatId = ids.join('_');

    await _chatRepository.sendMessage(
      chatId,
      ChatMessage(
        id: '',
        senderId: uid,
        receiverId: driverId,
        text: text,
        timestamp: DateTime.now(),
      ),
      senderName,
      driverName,
    );
  }

  @override
  Future<void> ensureGroupChat({
    required String rideId,
    required String groupTitle,
    required DateTime rideDate,
    required List<String> participantIds,
    required Map<String, String> participantNames,
    required Map<String, String> participantPhotos,
  }) async {
    await _db.collection('chats').doc(rideId).set({
      'participants': FieldValue.arrayUnion(participantIds),
      'type': 'group',
      'groupTitle': groupTitle,
      'rideDate': Timestamp.fromDate(rideDate),
      'participantNames': participantNames,
      'participantPhotos': participantPhotos,
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
