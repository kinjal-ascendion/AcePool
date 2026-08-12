import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:acepool/core/services/directions_service.dart';
import 'package:acepool/features/trips/data/repositories/trips_repository_impl.dart';
import 'package:acepool/features/trips/domain/entities/available_ride.dart';

class MockDirectionsService extends Mock implements DirectionsService {}

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;
  late MockDirectionsService directions;
  late TripsRepositoryImpl repository;

  const uid = 'test-uid';

  setUpAll(() {
    registerFallbackValue(<List<double>>[]);
  });

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: uid));
    directions = MockDirectionsService();
    repository = TripsRepositoryImpl(
      db: firestore,
      firebaseAuth: auth,
      directions: directions,
    );
  });

  DateTime tomorrow() => DateTime.now().add(const Duration(days: 1));
  DateTime yesterday() => DateTime.now().subtract(const Duration(days: 1));

  Future<void> addRide(String id, Map<String, dynamic> data) =>
      firestore.collection('rides').doc(id).set(data);

  Future<void> addUser(String id, Map<String, dynamic> data) =>
      firestore.collection('users').doc(id).set(data);

  Future<void> addRideRequest(String id, Map<String, dynamic> data) =>
      firestore.collection('ride_requests').doc(id).set(data);

  Map<String, dynamic> baseRide({
    required String ownerUid,
    required String rideMode,
    DateTime? date,
    int seatCount = 4,
    int? seatsFilled,
    String fromAddress = 'Home',
    String toAddress = 'Office',
    double? fromLat,
    double? fromLng,
    double? toLat,
    double? toLng,
    double? routeDistanceKm,
    String vehicleType = 'car',
    Map<String, dynamic>? fare,
    String status = 'upcoming',
  }) {
    return {
      'uid': ownerUid,
      'rideMode': rideMode,
      'date': Timestamp.fromDate(date ?? tomorrow()),
      'time': {'hour': 9, 'minute': 0},
      'fromAddress': fromAddress,
      'toAddress': toAddress,
      if (fromLat != null) 'fromLat': fromLat,
      if (fromLng != null) 'fromLng': fromLng,
      if (toLat != null) 'toLat': toLat,
      if (toLng != null) 'toLng': toLng,
      'seatCount': seatCount,
      if (seatsFilled != null) 'seatsFilled': seatsFilled,
      if (routeDistanceKm != null) 'routeDistanceKm': routeDistanceKm,
      'vehicleType': vehicleType,
      if (fare != null) 'fare': fare,
      'status': status,
    };
  }

  group('getTrips', () {
    test('returns empty list when no user is signed in', () async {
      auth = MockFirebaseAuth(signedIn: false);
      repository = TripsRepositoryImpl(
        db: firestore,
        firebaseAuth: auth,
        directions: directions,
      );

      final result = await repository.getTrips('offer');
      expect(result, isEmpty);
    });

    test('filters by rideMode and excludes rides not owned by current user',
        () async {
      await addRide(
        'r1',
        baseRide(ownerUid: uid, rideMode: 'offer'),
      );
      await addRide(
        'r2',
        baseRide(ownerUid: uid, rideMode: 'find'),
      );
      await addRide(
        'r3',
        baseRide(ownerUid: 'other-uid', rideMode: 'offer'),
      );

      final result = await repository.getTrips('offer');

      expect(result, hasLength(1));
      expect(result.first.id, 'r1');
    });

    test('excludes completed and cancelled rides', () async {
      await addRide(
        'r1',
        baseRide(ownerUid: uid, rideMode: 'offer', status: 'completed'),
      );
      await addRide(
        'r2',
        baseRide(ownerUid: uid, rideMode: 'offer', status: 'cancelled'),
      );
      await addRide(
        'r3',
        baseRide(ownerUid: uid, rideMode: 'offer', status: 'upcoming'),
      );

      final result = await repository.getTrips('offer');

      expect(result, hasLength(1));
      expect(result.first.id, 'r3');
    });

    test('excludes rides dated before today', () async {
      await addRide(
        'past',
        baseRide(ownerUid: uid, rideMode: 'offer', date: yesterday()),
      );
      await addRide(
        'future',
        baseRide(ownerUid: uid, rideMode: 'offer', date: tomorrow()),
      );

      final result = await repository.getTrips('offer');

      expect(result.map((t) => t.id), ['future']);
    });

    test('maps fields, defaulting seatsFilled to 0 and status to upcoming',
        () async {
      await addRide('r1', {
        'uid': uid,
        'rideMode': 'offer',
        'date': Timestamp.fromDate(tomorrow()),
        'time': {'hour': 8, 'minute': 30},
        'fromAddress': 'Home',
        'toAddress': 'Office',
        'seatCount': 4,
      });

      final result = await repository.getTrips('offer');

      expect(result, hasLength(1));
      final trip = result.first;
      expect(trip.seatsFilled, 0);
      expect(trip.status, 'upcoming');
      expect(trip.seatsTotal, 4);
      expect(trip.time, const TimeOfDay(hour: 8, minute: 30));
    });

    test('falls back to fromLatLng/toLatLng maps when flat lat/lng missing',
        () async {
      await addRide('r1', {
        'uid': uid,
        'rideMode': 'offer',
        'date': Timestamp.fromDate(tomorrow()),
        'time': {'hour': 8, 'minute': 30},
        'fromAddress': 'Home',
        'toAddress': 'Office',
        'fromLatLng': {'latitude': 1.5, 'longitude': 2.5},
        'toLatLng': {'latitude': 3.5, 'longitude': 4.5},
        'seatCount': 4,
      });

      final result = await repository.getTrips('offer');

      expect(result.first.fromLat, 1.5);
      expect(result.first.fromLng, 2.5);
      expect(result.first.toLat, 3.5);
      expect(result.first.toLng, 4.5);
    });

    test('prefers flat lat/lng fields over the nested LatLng maps', () async {
      await addRide('r1', {
        'uid': uid,
        'rideMode': 'offer',
        'date': Timestamp.fromDate(tomorrow()),
        'time': {'hour': 8, 'minute': 30},
        'fromAddress': 'Home',
        'toAddress': 'Office',
        'fromLat': 9.9,
        'fromLng': 8.8,
        'fromLatLng': {'latitude': 1.5, 'longitude': 2.5},
        'seatCount': 4,
      });

      final result = await repository.getTrips('offer');

      expect(result.first.fromLat, 9.9);
      expect(result.first.fromLng, 8.8);
    });
  });

  group('getAvailableRides', () {
    test('returns empty list when no user is signed in', () async {
      auth = MockFirebaseAuth(signedIn: false);
      repository = TripsRepositoryImpl(
        db: firestore,
        firebaseAuth: auth,
        directions: directions,
      );

      final result = await repository.getAvailableRides(
        fromAddress: 'Home',
        toAddress: 'Office',
      );
      expect(result, isEmpty);
    });

    test('returns empty list when fromAddress is blank', () async {
      final result = await repository.getAvailableRides(
        fromAddress: '   ',
        toAddress: 'Office',
      );
      expect(result, isEmpty);
    });

    test('returns empty list when toAddress is null', () async {
      final result = await repository.getAvailableRides(fromAddress: 'Home');
      expect(result, isEmpty);
    });

    test('excludes rides owned by the current user', () async {
      await addRide(
        'mine',
        baseRide(
          ownerUid: uid,
          rideMode: 'offer',
          fromAddress: 'Home',
          toAddress: 'Office',
        ),
      );

      final result = await repository.getAvailableRides(
        fromAddress: 'Home',
        toAddress: 'Office',
      );

      expect(result, isEmpty);
    });

    test('excludes rides that are not in offer mode', () async {
      await addRide(
        'r1',
        baseRide(ownerUid: 'other', rideMode: 'find'),
      );

      final result = await repository.getAvailableRides(
        fromAddress: 'Home',
        toAddress: 'Office',
      );

      expect(result, isEmpty);
    });

    test('excludes rides whose seats are already full', () async {
      await addRide(
        'r1',
        baseRide(
          ownerUid: 'other',
          rideMode: 'offer',
          seatCount: 4,
          seatsFilled: 4,
          fromAddress: 'Home',
          toAddress: 'Office',
        ),
      );

      final result = await repository.getAvailableRides(
        fromAddress: 'Home',
        toAddress: 'Office',
      );

      expect(result, isEmpty);
    });

    test(
        'includes a ride whose endpoints are close to the user\'s commute '
        'points (endpoint-close branch), without calling DirectionsService',
        () async {
      await addUser(uid, {});
      await addRide(
        'r1',
        baseRide(
          ownerUid: 'driver1',
          rideMode: 'offer',
          fromAddress: 'Ride Home',
          toAddress: 'Ride Office',
          fromLat: 28.6139,
          fromLng: 77.2090,
          toLat: 28.7041,
          toLng: 77.1025,
          routeDistanceKm: 12.0,
        ),
      );
      await addUser('driver1', {
        'fullName': 'Driver One',
        'profileImageUrl': 'photo.png',
        'phone': '12345',
      });

      final result = await repository.getAvailableRides(
        fromAddress: 'User Home',
        toAddress: 'User Office',
        fromLat: 28.6140,
        fromLng: 77.2091,
        toLat: 28.7042,
        toLng: 77.1026,
      );

      expect(result, hasLength(1));
      final ride = result.first;
      expect(ride.id, 'r1');
      expect(ride.driverName, 'Driver One');
      expect(ride.driverPhotoUrl, 'photo.png');
      expect(ride.driverPhone, '12345');
      expect(ride.defaultPickupPoint, 'User Home');
      verifyNever(() => directions.fetchRouteDistanceKm(
            originLat: any(named: 'originLat'),
            originLng: any(named: 'originLng'),
            destLat: any(named: 'destLat'),
            destLng: any(named: 'destLng'),
            waypoints: any(named: 'waypoints'),
          ));
    });

    test(
        'falls back to nested fromLatLng/toLatLng maps and fare.farePerSeat '
        'when flat fromLat/fromLng/toLat/toLng fields are absent, and the '
        'ride still matches and is included', () async {
      await addUser(uid, {});
      // Same coordinates as the "endpoint-close" case above, but expressed
      // as nested fromLatLng/toLatLng maps (no flat fromLat/fromLng/toLat/
      // toLng fields) plus a fare map, to exercise the `rideFromLat ?? ...`
      // fallback-to-nested-map branches and the fare.farePerSeat parsing.
      await addRide('r1', {
        'uid': 'driver1',
        'rideMode': 'offer',
        'date': Timestamp.fromDate(tomorrow()),
        'time': {'hour': 9, 'minute': 0},
        'fromAddress': 'Ride Home',
        'toAddress': 'Ride Office',
        'fromLatLng': {'latitude': 28.6139, 'longitude': 77.2090},
        'toLatLng': {'latitude': 28.7041, 'longitude': 77.1025},
        'routeDistanceKm': 12.0,
        'seatCount': 4,
        'vehicleType': 'car',
        'fare': {'farePerSeat': 150.0},
        'status': 'upcoming',
      });
      await addUser('driver1', {
        'fullName': 'Driver One',
        'profileImageUrl': 'photo.png',
        'phone': '12345',
      });

      final result = await repository.getAvailableRides(
        fromAddress: 'User Home',
        toAddress: 'User Office',
        fromLat: 28.6140,
        fromLng: 77.2091,
        toLat: 28.7042,
        toLng: 77.1026,
      );

      expect(result, hasLength(1));
      final ride = result.first;
      expect(ride.id, 'r1');
      expect(ride.fromLat, 28.6139);
      expect(ride.fromLng, 77.2090);
      expect(ride.toLat, 28.7041);
      expect(ride.toLng, 77.1025);
      expect(ride.farePerSeat, 150.0);
    });

    test(
        'when endpoints are far apart, calls DirectionsService for the live '
        'detour distance but still excludes the ride from results (isMatch '
        'requires close endpoints)', () async {
      await addUser(uid, {});
      await addRide(
        'r1',
        baseRide(
          ownerUid: 'driver1',
          rideMode: 'offer',
          fromAddress: 'Ride Home',
          toAddress: 'Ride Office',
          fromLat: 19.0760,
          fromLng: 72.8777,
          toLat: 19.2183,
          toLng: 72.9781,
          routeDistanceKm: 15.0,
        ),
      );
      when(() => directions.fetchRouteDistanceKm(
            originLat: any(named: 'originLat'),
            originLng: any(named: 'originLng'),
            destLat: any(named: 'destLat'),
            destLng: any(named: 'destLng'),
            waypoints: any(named: 'waypoints'),
          )).thenAnswer((_) async => 18.0);

      final result = await repository.getAvailableRides(
        fromAddress: 'User Home',
        toAddress: 'User Office',
        fromLat: 28.6140,
        fromLng: 77.2091,
        toLat: 28.7042,
        toLng: 77.1026,
      );

      expect(result, isEmpty);
      verify(() => directions.fetchRouteDistanceKm(
            originLat: any(named: 'originLat'),
            originLng: any(named: 'originLng'),
            destLat: any(named: 'destLat'),
            destLng: any(named: 'destLng'),
            waypoints: any(named: 'waypoints'),
          )).called(1);
    });

    test(
        'when DirectionsService returns null, still excludes the far-apart '
        'ride without throwing', () async {
      await addUser(uid, {});
      await addRide(
        'r1',
        baseRide(
          ownerUid: 'driver1',
          rideMode: 'offer',
          fromLat: 19.0760,
          fromLng: 72.8777,
          toLat: 19.2183,
          toLng: 72.9781,
          routeDistanceKm: 15.0,
        ),
      );
      when(() => directions.fetchRouteDistanceKm(
            originLat: any(named: 'originLat'),
            originLng: any(named: 'originLng'),
            destLat: any(named: 'destLat'),
            destLng: any(named: 'destLng'),
            waypoints: any(named: 'waypoints'),
          )).thenAnswer((_) async => null);

      final result = await repository.getAvailableRides(
        fromAddress: 'User Home',
        toAddress: 'User Office',
        fromLat: 28.6140,
        fromLng: 77.2091,
        toLat: 28.7042,
        toLng: 77.1026,
      );

      expect(result, isEmpty);
    });

    test('driver name defaults to "Driver" when the user doc has no fullName',
        () async {
      await addUser(uid, {});
      await addRide(
        'r1',
        baseRide(
          ownerUid: 'driver1',
          rideMode: 'offer',
          fromLat: 28.6139,
          fromLng: 77.2090,
          toLat: 28.7041,
          toLng: 77.1025,
          routeDistanceKm: 12.0,
        ),
      );
      // No driver1 user doc created at all.

      final result = await repository.getAvailableRides(
        fromAddress: 'User Home',
        toAddress: 'User Office',
        fromLat: 28.6140,
        fromLng: 77.2091,
        toLat: 28.7042,
        toLng: 77.1026,
      );

      expect(result, hasLength(1));
      expect(result.first.driverName, 'Driver');
      expect(result.first.driverPhotoUrl, '');
      expect(result.first.driverPhone, '');
    });

    test('marks alreadyRequested true when an accepted ride_request exists',
        () async {
      await addUser(uid, {});
      await addRide(
        'r1',
        baseRide(
          ownerUid: 'driver1',
          rideMode: 'offer',
          fromLat: 28.6139,
          fromLng: 77.2090,
          toLat: 28.7041,
          toLng: 77.1025,
          routeDistanceKm: 12.0,
        ),
      );
      await addRideRequest('req1', {
        'riderId': uid,
        'status': 'accepted',
        'rideId': 'r1',
      });

      final result = await repository.getAvailableRides(
        fromAddress: 'User Home',
        toAddress: 'User Office',
        fromLat: 28.6140,
        fromLng: 77.2091,
        toLat: 28.7042,
        toLng: 77.1026,
      );

      expect(result, hasLength(1));
      expect(result.first.alreadyRequested, isTrue);
    });

    test('sorts results by matchPercent descending', () async {
      await addUser(uid, {});
      // Ride A: essentially exact match -> ~100%.
      await addRide(
        'rideA',
        baseRide(
          ownerUid: 'driverA',
          rideMode: 'offer',
          fromLat: 28.6140,
          fromLng: 77.2091,
          toLat: 28.7042,
          toLng: 77.1026,
          routeDistanceKm: 12.0,
        ),
      );
      // Ride B: still within radius but further from user's points -> lower %.
      await addRide(
        'rideB',
        baseRide(
          ownerUid: 'driverB',
          rideMode: 'offer',
          fromLat: 28.6400,
          fromLng: 77.2300,
          toLat: 28.7300,
          toLng: 77.1300,
          routeDistanceKm: 12.0,
        ),
      );

      final result = await repository.getAvailableRides(
        fromAddress: 'User Home',
        toAddress: 'User Office',
        fromLat: 28.6140,
        fromLng: 77.2091,
        toLat: 28.7042,
        toLng: 77.1026,
      );

      expect(result, hasLength(2));
      expect(result.first.id, 'rideA');
      expect(result.first.matchPercent,
          greaterThanOrEqualTo(result.last.matchPercent));
    });

    test('uses routeMatchingRadius from the user doc when present', () async {
      // A tight 1km radius should exclude a ride whose endpoints are ~3km
      // away, even though the default 5km radius would have included it.
      await addUser(uid, {'routeMatchingRadius': 1.0});
      await addRide(
        'r1',
        baseRide(
          ownerUid: 'driver1',
          rideMode: 'offer',
          fromLat: 28.6400,
          fromLng: 77.2300,
          toLat: 28.7300,
          toLng: 77.1300,
          routeDistanceKm: 12.0,
        ),
      );
      when(() => directions.fetchRouteDistanceKm(
            originLat: any(named: 'originLat'),
            originLng: any(named: 'originLng'),
            destLat: any(named: 'destLat'),
            destLng: any(named: 'destLng'),
            waypoints: any(named: 'waypoints'),
          )).thenAnswer((_) async => null);

      final result = await repository.getAvailableRides(
        fromAddress: 'User Home',
        toAddress: 'User Office',
        fromLat: 28.6140,
        fromLng: 77.2091,
        toLat: 28.7042,
        toLng: 77.1026,
      );

      expect(result, isEmpty);
    });
  });

  group('getRideRequests', () {
    test('returns empty list when no user is signed in', () async {
      auth = MockFirebaseAuth(signedIn: false);
      repository = TripsRepositoryImpl(
        db: firestore,
        firebaseAuth: auth,
        directions: directions,
      );

      final result = await repository.getRideRequests();
      expect(result, isEmpty);
    });

    test('excludes completed and cancelled requests', () async {
      await addRide('ride1', baseRide(ownerUid: 'driver1', rideMode: 'offer'));
      await addRideRequest('req1', {
        'riderId': uid,
        'status': 'completed',
        'rideId': 'ride1',
        'rideDate': Timestamp.fromDate(tomorrow()),
        'rideTime': {'hour': 9, 'minute': 0},
        'rideFrom': 'Home',
        'rideTo': 'Office',
        'driverId': 'driver1',
      });
      await addRideRequest('req2', {
        'riderId': uid,
        'status': 'cancelled',
        'rideId': 'ride1',
        'rideDate': Timestamp.fromDate(tomorrow()),
        'rideTime': {'hour': 9, 'minute': 0},
        'rideFrom': 'Home',
        'rideTo': 'Office',
        'driverId': 'driver1',
      });
      await addRideRequest('req3', {
        'riderId': uid,
        'status': 'accepted',
        'rideId': 'ride1',
        'rideDate': Timestamp.fromDate(tomorrow()),
        'rideTime': {'hour': 9, 'minute': 0},
        'rideFrom': 'Home',
        'rideTo': 'Office',
        'driverId': 'driver1',
      });

      final result = await repository.getRideRequests();

      expect(result, hasLength(1));
      expect(result.first.id, 'req3');
    });

    test('skips a request whose ride no longer exists', () async {
      await addRideRequest('req1', {
        'riderId': uid,
        'status': 'accepted',
        'rideId': 'missing-ride',
        'rideDate': Timestamp.fromDate(tomorrow()),
        'rideTime': {'hour': 9, 'minute': 0},
        'rideFrom': 'Home',
        'rideTo': 'Office',
        'driverId': 'driver1',
      });

      final result = await repository.getRideRequests();

      expect(result, isEmpty);
    });

    test('falls back to driver profile lookup when driverName is missing',
        () async {
      await addRide('ride1', baseRide(ownerUid: 'driver1', rideMode: 'offer'));
      await addUser('driver1', {
        'profileImageUrl': 'photo.png',
        'phone': '999',
      });
      await addRideRequest('req1', {
        'riderId': uid,
        'status': 'accepted',
        'rideId': 'ride1',
        'rideDate': Timestamp.fromDate(tomorrow()),
        'rideTime': {'hour': 9, 'minute': 0},
        'rideFrom': 'Home',
        'rideTo': 'Office',
        'driverId': 'driver1',
      });

      final result = await repository.getRideRequests();

      expect(result, hasLength(1));
      expect(result.first.driverName, 'Driver');
      expect(result.first.driverPhotoUrl, 'photo.png');
      expect(result.first.driverPhone, '999');
    });

    test('uses stored driverName when present and non-empty', () async {
      await addRide('ride1', baseRide(ownerUid: 'driver1', rideMode: 'offer'));
      await addRideRequest('req1', {
        'riderId': uid,
        'status': 'pending',
        'rideId': 'ride1',
        'rideDate': Timestamp.fromDate(tomorrow()),
        'rideTime': {'hour': 9, 'minute': 0},
        'rideFrom': 'Home',
        'rideTo': 'Office',
        'driverId': 'driver1',
        'driverName': 'Stored Driver',
      });

      final result = await repository.getRideRequests();

      expect(result.first.driverName, 'Stored Driver');
    });

    test('defaults status to pending and seats/fare fields when missing',
        () async {
      await addRide('ride1', {
        'uid': 'driver1',
        'rideMode': 'offer',
        'date': Timestamp.fromDate(tomorrow()),
        'time': {'hour': 9, 'minute': 0},
        'fromAddress': 'Home',
        'toAddress': 'Office',
        'seatCount': 4,
      });
      await addRideRequest('req1', {
        'riderId': uid,
        'rideId': 'ride1',
        'rideDate': Timestamp.fromDate(tomorrow()),
        'rideTime': {'hour': 9, 'minute': 0},
        'rideFrom': 'Home',
        'rideTo': 'Office',
        'driverId': 'driver1',
      });

      final result = await repository.getRideRequests();

      expect(result, hasLength(1));
      final request = result.first;
      expect(request.status, 'pending');
      expect(request.seatsFilled, 0);
      expect(request.seatsTotal, 4);
      expect(request.vehicleType, 'car');
      expect(request.farePerSeat, isNull);
    });
  });

  group('cancelOfferedRide', () {
    test('sets ride status/reason and cascades cancellation to requests',
        () async {
      await addRide('trip1', baseRide(ownerUid: uid, rideMode: 'offer'));
      await addRideRequest('req1', {
        'rideId': 'trip1',
        'status': 'accepted',
      });
      await addRideRequest('req2', {
        'rideId': 'trip1',
        'status': 'pending',
      });
      await addRideRequest('req3', {
        'rideId': 'other-trip',
        'status': 'accepted',
      });

      await repository.cancelOfferedRide('trip1', reason: 'Car trouble');

      final rideDoc = await firestore.collection('rides').doc('trip1').get();
      expect(rideDoc.data()!['status'], 'cancelled');
      expect(rideDoc.data()!['cancellationReason'], 'Car trouble');
      expect(rideDoc.data()!['cancelledAt'], isNotNull);

      final req1 = await firestore.collection('ride_requests').doc('req1').get();
      expect(req1.data()!['status'], 'cancelled');
      expect(req1.data()!['cancellationReason'], 'Driver cancelled: Car trouble');

      final req2 = await firestore.collection('ride_requests').doc('req2').get();
      expect(req2.data()!['status'], 'cancelled');

      final req3 = await firestore.collection('ride_requests').doc('req3').get();
      expect(req3.data()!['status'], 'accepted');
    });

    test('completes without error when there are no matching requests',
        () async {
      await addRide('trip1', baseRide(ownerUid: uid, rideMode: 'offer'));

      await expectLater(
        repository.cancelOfferedRide('trip1', reason: 'No riders'),
        completes,
      );
    });
  });

  group('updateTripStatus', () {
    test('updates only the status field', () async {
      await addRide('trip1', baseRide(ownerUid: uid, rideMode: 'offer'));

      await repository.updateTripStatus('trip1', 'completed');

      final doc = await firestore.collection('rides').doc('trip1').get();
      expect(doc.data()!['status'], 'completed');
    });
  });

  group('requestAvailableRide', () {
    AvailableRide buildRide({
      double? fromLat,
      double? fromLng,
      double? toLat,
      double? toLng,
      double? userFromLat,
      double? userFromLng,
      double? userToLat,
      double? userToLng,
    }) {
      return AvailableRide(
        id: 'ride1',
        driverId: 'driver1',
        driverName: 'Driver One',
        date: DateTime(2024, 1, 5),
        time: const TimeOfDay(hour: 9, minute: 0),
        fromAddress: 'Ride From',
        toAddress: 'Ride To',
        fromLat: fromLat,
        fromLng: fromLng,
        toLat: toLat,
        toLng: toLng,
        seatsFilled: 1,
        seatsTotal: 4,
        vehicleType: 'car',
        alreadyRequested: false,
        matchPercent: 90,
        defaultPickupPoint: 'Ride From',
        distanceKm: 0.5,
        userFromAddress: 'User From',
        userToAddress: 'User To',
        userFromLat: userFromLat,
        userFromLng: userFromLng,
        userToLat: userToLat,
        userToLng: userToLng,
      );
    }

    test('returns empty string and writes nothing when no user is signed in',
        () async {
      auth = MockFirebaseAuth(signedIn: false);
      repository = TripsRepositoryImpl(
        db: firestore,
        firebaseAuth: auth,
        directions: directions,
      );

      final result = await repository.requestAvailableRide(
        ride: buildRide(),
      );

      expect(result, '');
      final requests = await firestore.collection('ride_requests').get();
      expect(requests.docs, isEmpty);
    });

    test(
        'endpoint match: uses ride\'s own from/to as pickup/dropoff and '
        'increments seatsFilled', () async {
      await addUser(uid, {'fullName': 'Rider Name', 'profileImageUrl': 'r.png'});
      await addRide('ride1', {
        'uid': 'driver1',
        'rideMode': 'offer',
        'date': Timestamp.fromDate(tomorrow()),
        'time': {'hour': 9, 'minute': 0},
        'fromAddress': 'Ride From',
        'toAddress': 'Ride To',
        'seatCount': 4,
        'seatsFilled': 1,
      });

      final ride = buildRide(
        fromLat: 28.6139,
        fromLng: 77.2090,
        toLat: 28.7041,
        toLng: 77.1025,
        userFromLat: 28.6140,
        userFromLng: 77.2091,
        userToLat: 28.7042,
        userToLng: 77.1026,
      );

      final riderName = await repository.requestAvailableRide(ride: ride);

      expect(riderName, 'Rider Name');

      final requests = await firestore.collection('ride_requests').get();
      expect(requests.docs, hasLength(1));
      final data = requests.docs.first.data();
      expect(data['pickupPoint'], 'Ride From');
      expect(data['dropOffPoint'], 'Ride To');
      expect(data['pickupLatLng'], {'latitude': 28.6139, 'longitude': 77.2090});
      expect(data['dropOffLatLng'], {'latitude': 28.7041, 'longitude': 77.1025});
      expect(data['status'], 'accepted');
      expect(data['riderId'], uid);
      expect(data['driverId'], 'driver1');

      final rideDoc = await firestore.collection('rides').doc('ride1').get();
      expect(rideDoc.data()!['seatsFilled'], 2);
    });

    test(
        'detour match: uses generic pickup/dropoff labels and projects the '
        'point onto the ride segment when ride coords are available',
        () async {
      await addUser(uid, {'fullName': 'Rider Name'});
      await addRide('ride1', {
        'uid': 'driver1',
        'rideMode': 'offer',
        'date': Timestamp.fromDate(tomorrow()),
        'time': {'hour': 9, 'minute': 0},
        'fromAddress': 'Ride From',
        'toAddress': 'Ride To',
        'seatCount': 4,
        'seatsFilled': 0,
      });

      // Far apart from ride's own endpoints -> not an endpoint match.
      final ride = buildRide(
        fromLat: 28.6139,
        fromLng: 77.2090,
        toLat: 28.7041,
        toLng: 77.1025,
        userFromLat: 10.0,
        userFromLng: 10.0,
        userToLat: 11.0,
        userToLng: 11.0,
      );

      await repository.requestAvailableRide(ride: ride);

      final requests = await firestore.collection('ride_requests').get();
      final data = requests.docs.first.data();
      expect(data['pickupPoint'], 'Pick Up Point');
      expect(data['dropOffPoint'], 'Drop Point');
      expect(data['pickupLatLng'], isNotNull);
      expect(data['dropOffLatLng'], isNotNull);
    });

    test(
        'detour match without ride coords falls back to the user\'s own '
        'from/to coordinates', () async {
      await addUser(uid, {'fullName': 'Rider Name'});
      await addRide('ride1', {
        'uid': 'driver1',
        'rideMode': 'offer',
        'date': Timestamp.fromDate(tomorrow()),
        'time': {'hour': 9, 'minute': 0},
        'fromAddress': 'Ride From',
        'toAddress': 'Ride To',
        'seatCount': 4,
        'seatsFilled': 0,
      });

      final ride = buildRide(
        userFromLat: 10.0,
        userFromLng: 10.0,
        userToLat: 11.0,
        userToLng: 11.0,
      );

      await repository.requestAvailableRide(ride: ride);

      final requests = await firestore.collection('ride_requests').get();
      final data = requests.docs.first.data();
      expect(data['pickupLatLng'], {'latitude': 10.0, 'longitude': 10.0});
      expect(data['dropOffLatLng'], {'latitude': 11.0, 'longitude': 11.0});
    });

    test('uses empty riderName when the user doc has no fullName', () async {
      await addUser(uid, {});
      await addRide('ride1', {
        'uid': 'driver1',
        'rideMode': 'offer',
        'date': Timestamp.fromDate(tomorrow()),
        'time': {'hour': 9, 'minute': 0},
        'fromAddress': 'Ride From',
        'toAddress': 'Ride To',
        'seatCount': 4,
        'seatsFilled': 0,
      });

      final riderName = await repository.requestAvailableRide(
        ride: buildRide(),
      );

      expect(riderName, '');
    });
  });

  group('cancelRideRequest', () {
    test('cancels the request and decrements seatsFilled on the ride',
        () async {
      await addRide('ride1', {
        'uid': 'driver1',
        'rideMode': 'offer',
        'date': Timestamp.fromDate(tomorrow()),
        'time': {'hour': 9, 'minute': 0},
        'fromAddress': 'Home',
        'toAddress': 'Office',
        'seatCount': 4,
        'seatsFilled': 2,
      });
      await addRideRequest('req1', {
        'riderId': uid,
        'rideId': 'ride1',
        'status': 'accepted',
      });

      await repository.cancelRideRequest(
        requestId: 'req1',
        rideId: 'ride1',
        reason: 'Change of plans',
      );

      final req = await firestore.collection('ride_requests').doc('req1').get();
      expect(req.data()!['status'], 'cancelled');
      expect(req.data()!['cancellationReason'], 'Change of plans');
      expect(req.data()!['cancelledAt'], isNotNull);

      final ride = await firestore.collection('rides').doc('ride1').get();
      expect(ride.data()!['seatsFilled'], 1);
    });
  });

  group('getDriverProfileStats', () {
    test('returns placeholder defaults when the driver doc does not exist',
        () async {
      final stats = await repository.getDriverProfileStats('unknown-driver');

      expect(stats.employeeId, 'ASC 2001922');
      expect(stats.completedRidesCount, 30);
      expect(stats.rating, 4.72);
      expect(stats.ratingCount, 15);
    });

    test('returns stored field values when present', () async {
      await addUser('driver1', {
        'employeeId': 'ASC 5555555',
        'completedRidesCount': 200,
        'rating': 4.5,
        'ratingCount': 80,
      });

      final stats = await repository.getDriverProfileStats('driver1');

      expect(stats.employeeId, 'ASC 5555555');
      expect(stats.completedRidesCount, 200);
      expect(stats.rating, 4.5);
      expect(stats.ratingCount, 80);
    });

    test('applies field-level defaults when the doc has only some fields',
        () async {
      await addUser('driver1', {'rating': 3.9});

      final stats = await repository.getDriverProfileStats('driver1');

      expect(stats.employeeId, 'ASC 2001922');
      expect(stats.completedRidesCount, 30);
      expect(stats.rating, 3.9);
      expect(stats.ratingCount, 15);
    });
  });
}
