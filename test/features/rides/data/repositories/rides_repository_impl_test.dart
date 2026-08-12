import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:acepool/core/services/directions_service.dart';
import 'package:acepool/core/utils/ride_matcher.dart';
import 'package:acepool/features/chat/domain/entities/chat_message.dart';
import 'package:acepool/features/chat/domain/repositories/chat_repository.dart';
import 'package:acepool/features/rides/data/repositories/rides_repository_impl.dart';
import 'package:acepool/features/rides/domain/entities/ride_match.dart';

class MockChatRepository extends Mock implements ChatRepository {}

class MockDirectionsService extends Mock implements DirectionsService {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class _FakeChatMessage extends Fake implements ChatMessage {}

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;
  late MockChatRepository chatRepository;
  late MockDirectionsService directions;
  late RidesRepositoryImpl repository;

  const uid = 'test-uid';

  setUpAll(() {
    registerFallbackValue(_FakeChatMessage());
  });

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: uid, displayName: 'Test User'),
    );
    chatRepository = MockChatRepository();
    directions = MockDirectionsService();
    repository = RidesRepositoryImpl(
      chatRepository: chatRepository,
      db: firestore,
      firebaseAuth: auth,
      directions: directions,
    );

    when(() => chatRepository.sendMessage(any(), any(), any(), any()))
        .thenAnswer((_) async {});
  });

  CollectionReference<Map<String, dynamic>> users() => firestore.collection('users');
  CollectionReference<Map<String, dynamic>> rides() => firestore.collection('rides');
  CollectionReference<Map<String, dynamic>> rideRequests() =>
      firestore.collection('ride_requests');

  Future<DocumentReference<Map<String, dynamic>>> addRide({
    required String driverUid,
    String rideMode = 'offer',
    DateTime? date,
    String vehicleType = 'car',
    int seatCount = 4,
    int seatsFilled = 0,
    String fromAddress = 'Driver From',
    String toAddress = 'Driver To',
    double? fromLat,
    double? fromLng,
    double? toLat,
    double? toLng,
    double? routeDistanceKm,
    double? farePerSeat,
    int hour = 9,
    int minute = 0,
    String? status,
  }) {
    return rides().add({
      'uid': driverUid,
      'rideMode': rideMode,
      'date': Timestamp.fromDate(date ?? DateTime(2026, 6, 15)),
      'vehicleType': vehicleType,
      'seatCount': seatCount,
      'seatsFilled': seatsFilled,
      'fromAddress': fromAddress,
      'toAddress': toAddress,
      if (fromLat != null) 'fromLat': fromLat,
      if (fromLng != null) 'fromLng': fromLng,
      if (toLat != null) 'toLat': toLat,
      if (toLng != null) 'toLng': toLng,
      if (routeDistanceKm != null) 'routeDistanceKm': routeDistanceKm,
      'fare': {'farePerSeat': farePerSeat},
      'time': {'hour': hour, 'minute': minute},
      if (status != null) 'status': status,
    });
  }

  RideMatch buildRideMatch({
    String id = 'ride-1',
    String driverId = 'driver-1',
    double? fromLat,
    double? fromLng,
    double? toLat,
    double? toLng,
    TimeOfDay time = const TimeOfDay(hour: 9, minute: 0),
  }) {
    return RideMatch(
      id: id,
      driverId: driverId,
      driverName: 'Driver',
      date: DateTime(2026, 6, 15),
      time: time,
      fromAddress: 'Driver From',
      toAddress: 'Driver To',
      seatsFilled: 0,
      seatsTotal: 4,
      vehicleType: 'car',
      alreadyRequested: false,
      distanceKm: null,
      matchPercent: 0,
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
    );
  }

  group('findMatchingRides', () {
    final date = DateTime(2026, 6, 15);
    const time = TimeOfDay(hour: 9, minute: 0);

    test('returns empty list when no user is signed in', () async {
      final unauth = MockFirebaseAuth();
      final repo = RidesRepositoryImpl(
        chatRepository: chatRepository,
        db: firestore,
        firebaseAuth: unauth,
        directions: directions,
      );

      final result = await repo.findMatchingRides(
        fromAddress: 'A',
        toAddress: 'B',
        date: date,
        time: time,
        vehicleType: 'car',
      );

      expect(result, isEmpty);
    });

    test('excludes rides with a different vehicleType', () async {
      await users().doc(uid).set({});
      await addRide(
        driverUid: 'driver-1',
        vehicleType: 'bike',
        fromAddress: 'A',
        toAddress: 'B',
      );

      final result = await repository.findMatchingRides(
        fromAddress: 'A',
        toAddress: 'B',
        date: date,
        time: time,
        vehicleType: 'car',
      );

      expect(result, isEmpty);
    });

    test('excludes rides where seatsFilled >= seatCount (seat-full)', () async {
      await users().doc(uid).set({});
      await addRide(
        driverUid: 'driver-1',
        seatCount: 2,
        seatsFilled: 2,
        fromAddress: 'A',
        toAddress: 'B',
      );

      final result = await repository.findMatchingRides(
        fromAddress: 'A',
        toAddress: 'B',
        date: date,
        time: time,
        vehicleType: 'car',
      );

      expect(result, isEmpty);
    });

    test('excludes the current user\'s own ride', () async {
      await users().doc(uid).set({});
      await addRide(driverUid: uid, fromAddress: 'A', toAddress: 'B');

      final result = await repository.findMatchingRides(
        fromAddress: 'A',
        toAddress: 'B',
        date: date,
        time: time,
        vehicleType: 'car',
      );

      expect(result, isEmpty);
    });

    test('fuzzy-address match (no coordinates on either side) is included '
        'with a null distanceKm', () async {
      await users().doc(uid).set({});
      await users().doc('driver-1').set({'fullName': 'Jane Driver'});
      await addRide(driverUid: 'driver-1', fromAddress: 'Same Home', toAddress: 'Same Office');

      final result = await repository.findMatchingRides(
        fromAddress: 'Same Home',
        toAddress: 'Same Office',
        date: date,
        time: time,
        vehicleType: 'car',
      );

      expect(result, hasLength(1));
      expect(result.first.distanceKm, isNull);
      expect(result.first.driverName, 'Jane Driver');
      expect(result.first.matchPercent, 65);
    });

    test('endpoint-close match: no live directions call needed, ride is '
        'included', () async {
      await users().doc(uid).set({});
      await users().doc('driver-1').set({'fullName': 'Jane Driver'});
      // ~110m offset — well within the 2km "endpoints close" threshold, so
      // the repo should skip the live Directions call entirely.
      await addRide(
        driverUid: 'driver-1',
        fromLat: 12.001,
        fromLng: 77.0,
        toLat: 12.051,
        toLng: 77.05,
        routeDistanceKm: 8.0,
      );

      final result = await repository.findMatchingRides(
        fromAddress: 'Search From',
        toAddress: 'Search To',
        fromLat: 12.0,
        fromLng: 77.0,
        toLat: 12.05,
        toLng: 77.05,
        date: date,
        time: time,
        vehicleType: 'car',
      );

      expect(result, hasLength(1));
      expect(result.first.distanceKm, isNotNull);
      verifyNever(() => directions.fetchRouteDistanceKm(
            originLat: any(named: 'originLat'),
            originLng: any(named: 'originLng'),
            destLat: any(named: 'destLat'),
            destLng: any(named: 'destLng'),
            waypoints: any(named: 'waypoints'),
          ));
    });

    test('detour branch: ride endpoints beyond the 2km "close" threshold but '
        'within the (default 5km) match radius triggers a live Directions '
        'call and is still included as a match', () async {
      await users().doc(uid).set({});
      await users().doc('driver-1').set({'fullName': 'Jane Driver'});
      when(() => directions.fetchRouteDistanceKm(
            originLat: any(named: 'originLat'),
            originLng: any(named: 'originLng'),
            destLat: any(named: 'destLat'),
            destLng: any(named: 'destLng'),
            waypoints: any(named: 'waypoints'),
          )).thenAnswer((_) async => 9.0);
      // ~0.03 deg (~3.3km) offset: beyond the 2km "close" skip-threshold,
      // but within the default 5km match radius.
      await addRide(
        driverUid: 'driver-1',
        fromLat: 12.03,
        fromLng: 77.0,
        toLat: 12.08,
        toLng: 77.05,
        routeDistanceKm: 8.0,
      );

      final result = await repository.findMatchingRides(
        fromAddress: 'Search From',
        toAddress: 'Search To',
        fromLat: 12.0,
        fromLng: 77.0,
        toLat: 12.05,
        toLng: 77.05,
        date: date,
        time: time,
        vehicleType: 'car',
      );

      expect(result, hasLength(1));
      verify(() => directions.fetchRouteDistanceKm(
            originLat: 12.03,
            originLng: 77.0,
            destLat: 12.08,
            destLng: 77.05,
            waypoints: [
              [12.0, 77.0],
              [12.05, 77.05],
            ],
          )).called(1);
    });

    test('rides whose endpoints are beyond the match radius are excluded '
        'regardless of the live Directions result', () async {
      await users().doc(uid).set({});
      await users().doc('driver-1').set({'fullName': 'Jane Driver'});
      when(() => directions.fetchRouteDistanceKm(
            originLat: any(named: 'originLat'),
            originLng: any(named: 'originLng'),
            destLat: any(named: 'destLat'),
            destLng: any(named: 'destLng'),
            waypoints: any(named: 'waypoints'),
          )).thenAnswer((_) async => 1.0);
      // ~0.08 deg (~8.9km) offset: beyond the default 5km match radius.
      await addRide(
        driverUid: 'driver-1',
        fromLat: 12.08,
        fromLng: 77.0,
        toLat: 12.13,
        toLng: 77.05,
        routeDistanceKm: 8.0,
      );

      final result = await repository.findMatchingRides(
        fromAddress: 'Search From',
        toAddress: 'Search To',
        fromLat: 12.0,
        fromLng: 77.0,
        toLat: 12.05,
        toLng: 77.05,
        date: date,
        time: time,
        vehicleType: 'car',
      );

      expect(result, isEmpty);
    });

    test('skips the live Directions call when the ride has no '
        'routeDistanceKm stored', () async {
      await users().doc(uid).set({});
      await users().doc('driver-1').set({'fullName': 'Jane Driver'});
      await addRide(
        driverUid: 'driver-1',
        fromLat: 12.03,
        fromLng: 77.0,
        toLat: 12.08,
        toLng: 77.05,
        // no routeDistanceKm
      );

      await repository.findMatchingRides(
        fromAddress: 'Search From',
        toAddress: 'Search To',
        fromLat: 12.0,
        fromLng: 77.0,
        toLat: 12.05,
        toLng: 77.05,
        date: date,
        time: time,
        vehicleType: 'car',
      );

      verifyNever(() => directions.fetchRouteDistanceKm(
            originLat: any(named: 'originLat'),
            originLng: any(named: 'originLng'),
            destLat: any(named: 'destLat'),
            destLng: any(named: 'destLng'),
            waypoints: any(named: 'waypoints'),
          ));
    });

    test('marks alreadyRequested true only for rides the current user has '
        'an accepted request on', () async {
      await users().doc(uid).set({});
      await users().doc('driver-1').set({'fullName': 'Driver One'});
      await users().doc('driver-2').set({'fullName': 'Driver Two'});
      final requestedRide = await addRide(
        driverUid: 'driver-1',
        fromAddress: 'Same Home',
        toAddress: 'Same Office',
      );
      await addRide(
        driverUid: 'driver-2',
        fromAddress: 'Same Home',
        toAddress: 'Same Office',
      );
      await rideRequests().add({
        'rideId': requestedRide.id,
        'riderId': uid,
        'status': 'accepted',
      });

      final result = await repository.findMatchingRides(
        fromAddress: 'Same Home',
        toAddress: 'Same Office',
        date: date,
        time: time,
        vehicleType: 'car',
      );

      expect(result, hasLength(2));
      final requested = result.firstWhere((r) => r.id == requestedRide.id);
      final other = result.firstWhere((r) => r.id != requestedRide.id);
      expect(requested.alreadyRequested, isTrue);
      expect(other.alreadyRequested, isFalse);
    });

    test('sorts matches by distanceKm ascending with null-distance matches '
        'last', () async {
      await users().doc(uid).set({});
      await users().doc('driver-near').set({'fullName': 'Near'});
      await users().doc('driver-far').set({'fullName': 'Far'});
      await users().doc('driver-fuzzy').set({'fullName': 'Fuzzy'});

      // Far coordinate match (still within radius): ~0.03 deg offset.
      await addRide(
        driverUid: 'driver-far',
        fromAddress: 'Far From',
        toAddress: 'Far To',
        fromLat: 12.03,
        fromLng: 77.0,
        toLat: 12.08,
        toLng: 77.05,
      );
      // Near coordinate match: ~0.001 deg offset.
      await addRide(
        driverUid: 'driver-near',
        fromAddress: 'Near From',
        toAddress: 'Near To',
        fromLat: 12.001,
        fromLng: 77.0,
        toLat: 12.051,
        toLng: 77.05,
      );
      // Fuzzy address-only match: no coordinates -> null distanceKm.
      await addRide(
        driverUid: 'driver-fuzzy',
        fromAddress: 'Search From',
        toAddress: 'Search To',
      );

      final result = await repository.findMatchingRides(
        fromAddress: 'Search From',
        toAddress: 'Search To',
        fromLat: 12.0,
        fromLng: 77.0,
        toLat: 12.05,
        toLng: 77.05,
        date: date,
        time: time,
        vehicleType: 'car',
      );

      expect(result, hasLength(3));
      expect(result[0].driverName, 'Near');
      expect(result[1].driverName, 'Far');
      expect(result[2].driverName, 'Fuzzy');
      expect(result[2].distanceKm, isNull);
    });

    test('uses the searching user\'s routeMatchingRadius when set, instead '
        'of the 5km default', () async {
      await users().doc(uid).set({'routeMatchingRadius': 2.0});
      await users().doc('driver-1').set({'fullName': 'Driver'});
      when(() => directions.fetchRouteDistanceKm(
            originLat: any(named: 'originLat'),
            originLng: any(named: 'originLng'),
            destLat: any(named: 'destLat'),
            destLng: any(named: 'destLng'),
            waypoints: any(named: 'waypoints'),
          )).thenAnswer((_) async => 9.0);
      // ~3.3km offset: within default 5km radius but outside a 2km radius.
      await addRide(
        driverUid: 'driver-1',
        fromLat: 12.03,
        fromLng: 77.0,
        toLat: 12.08,
        toLng: 77.05,
        routeDistanceKm: 8.0,
      );

      final result = await repository.findMatchingRides(
        fromAddress: 'Search From',
        toAddress: 'Search To',
        fromLat: 12.0,
        fromLng: 77.0,
        toLat: 12.05,
        toLng: 77.05,
        date: date,
        time: time,
        vehicleType: 'car',
      );

      expect(result, isEmpty);
    });

    test('a driver profile fetch that throws falls back to blank name/photo/'
        'phone for that driver only, other candidates still resolve normally',
        () async {
      // Seed real data in a FakeFirebaseFirestore, then wrap it behind a
      // mocktail MockFirebaseFirestore so we can make just one driver's
      // `users/<driverId>` .get() throw, while every other call (including
      // the 'rides' and 'ride_requests' queries) passes through untouched.
      final realFirestore = FakeFirebaseFirestore();
      await realFirestore.collection('users').doc(uid).set({});
      await realFirestore
          .collection('users')
          .doc('driver-ok')
          .set({'fullName': 'OK Driver'});
      await realFirestore.collection('rides').add({
        'uid': 'driver-ok',
        'rideMode': 'offer',
        'date': Timestamp.fromDate(date),
        'vehicleType': 'car',
        'seatCount': 4,
        'seatsFilled': 0,
        'fromAddress': 'Same Home',
        'toAddress': 'Same Office',
        'fare': {'farePerSeat': null},
        'time': {'hour': 9, 'minute': 0},
      });
      await realFirestore.collection('rides').add({
        'uid': 'driver-fail',
        'rideMode': 'offer',
        'date': Timestamp.fromDate(date),
        'vehicleType': 'car',
        'seatCount': 4,
        'seatsFilled': 0,
        'fromAddress': 'Same Home',
        'toAddress': 'Same Office',
        'fare': {'farePerSeat': null},
        'time': {'hour': 9, 'minute': 0},
      });

      final mockFirestore = MockFirebaseFirestore();
      final usersCollection = MockCollectionReference();
      final failDoc = MockDocumentReference();
      when(() => mockFirestore.collection('rides'))
          .thenReturn(realFirestore.collection('rides'));
      when(() => mockFirestore.collection('ride_requests'))
          .thenReturn(realFirestore.collection('ride_requests'));
      when(() => mockFirestore.collection('users')).thenReturn(usersCollection);
      when(() => usersCollection.doc(uid))
          .thenReturn(realFirestore.collection('users').doc(uid));
      when(() => usersCollection.doc('driver-ok'))
          .thenReturn(realFirestore.collection('users').doc('driver-ok'));
      when(() => usersCollection.doc('driver-fail')).thenReturn(failDoc);
      when(() => failDoc.get()).thenThrow(Exception('boom'));

      final repo = RidesRepositoryImpl(
        chatRepository: chatRepository,
        db: mockFirestore,
        firebaseAuth: auth,
        directions: directions,
      );

      final result = await repo.findMatchingRides(
        fromAddress: 'Same Home',
        toAddress: 'Same Office',
        date: date,
        time: time,
        vehicleType: 'car',
      );

      expect(result, hasLength(2));
      final okMatch = result.firstWhere((r) => r.driverId == 'driver-ok');
      final failMatch = result.firstWhere((r) => r.driverId == 'driver-fail');
      expect(okMatch.driverName, 'OK Driver');
      expect(failMatch.driverName, '');
      expect(failMatch.driverPhotoUrl, isNull);
      expect(failMatch.driverPhone, isNull);
    });
  });

  group('requestRide', () {
    test('returns empty string when no user is signed in', () async {
      final unauth = MockFirebaseAuth();
      final repo = RidesRepositoryImpl(
        chatRepository: chatRepository,
        db: firestore,
        firebaseAuth: unauth,
        directions: directions,
      );
      final ride = buildRideMatch();

      final result = await repo.requestRide(
        ride: ride,
        riderFromAddress: 'Rider From',
        riderToAddress: 'Rider To',
        riderTime: const TimeOfDay(hour: 8, minute: 0),
      );

      expect(result, '');
    });

    test('endpoint match: rider coords close to ride endpoints uses the '
        "ride's own from/to as pickup/dropoff and increments seatsFilled",
        () async {
      await users().doc(uid).set({'fullName': 'Rider Name', 'profileImageUrl': 'photo.png'});
      final rideDoc = await addRide(
        driverUid: 'driver-1',
        fromLat: 12.0,
        fromLng: 77.0,
        toLat: 12.05,
        toLng: 77.05,
        seatsFilled: 1,
      );
      final ride = buildRideMatch(
        id: rideDoc.id,
        fromLat: 12.0,
        fromLng: 77.0,
        toLat: 12.05,
        toLng: 77.05,
      );

      final riderName = await repository.requestRide(
        ride: ride,
        riderFromAddress: 'Rider From',
        riderFromLat: 12.0005,
        riderFromLng: 77.0005,
        riderToAddress: 'Rider To',
        riderToLat: 12.0505,
        riderToLng: 77.0505,
        riderTime: const TimeOfDay(hour: 8, minute: 30),
        message: 'Hi there',
      );

      expect(riderName, 'Rider Name');

      final requestsSnap = await rideRequests().get();
      expect(requestsSnap.docs, hasLength(1));
      final data = requestsSnap.docs.first.data();
      expect(data['pickupPoint'], 'Driver From');
      expect(data['dropOffPoint'], 'Driver To');
      expect(data['pickupLatLng'], {'latitude': 12.0, 'longitude': 77.0});
      expect(data['dropOffLatLng'], {'latitude': 12.05, 'longitude': 77.05});
      expect(data['riderId'], uid);
      expect(data['riderName'], 'Rider Name');
      expect(data['message'], 'Hi there');
      expect(data['status'], 'accepted');
      expect(data['pickupTime'], {'hour': 8, 'minute': 30});
      expect(data['driverId'], 'driver-1');

      final updatedRide = await rides().doc(rideDoc.id).get();
      expect(updatedRide.data()!['seatsFilled'], 2);
    });

    test('detour match: rider coords far from ride endpoints projects the '
        'pickup/dropoff onto the ride route via RideMatcher.projectPointToSegment',
        () async {
      await users().doc(uid).set({'fullName': 'Rider Name'});
      final rideDoc = await addRide(
        driverUid: 'driver-1',
        fromLat: 12.0,
        fromLng: 77.0,
        toLat: 12.1,
        toLng: 77.1,
        seatsFilled: 0,
      );
      final ride = buildRideMatch(
        id: rideDoc.id,
        fromLat: 12.0,
        fromLng: 77.0,
        toLat: 12.1,
        toLng: 77.1,
      );

      // Rider from/to points are far from the ride's own endpoints (well
      // beyond the 2km endpoint-match threshold), so this should fall into
      // the detour-match / projection branch.
      const riderFromLat = 12.05;
      const riderFromLng = 77.2;
      const riderToLat = 12.06;
      const riderToLng = 77.21;

      final expectedPickup = RideMatcher.projectPointToSegment(
        12.0,
        77.0,
        12.1,
        77.1,
        riderFromLat,
        riderFromLng,
      );
      final expectedDropoff = RideMatcher.projectPointToSegment(
        12.0,
        77.0,
        12.1,
        77.1,
        riderToLat,
        riderToLng,
      );

      await repository.requestRide(
        ride: ride,
        riderFromAddress: 'Rider From',
        riderFromLat: riderFromLat,
        riderFromLng: riderFromLng,
        riderToAddress: 'Rider To',
        riderToLat: riderToLat,
        riderToLng: riderToLng,
        riderTime: const TimeOfDay(hour: 8, minute: 0),
      );

      final requestsSnap = await rideRequests().get();
      final data = requestsSnap.docs.first.data();
      expect(data['pickupPoint'], 'Rider From');
      expect(data['dropOffPoint'], 'Rider To');
      expect(data['pickupLatLng'], expectedPickup);
      expect(data['dropOffLatLng'], expectedDropoff);
    });

    test('when rider coordinates are entirely missing, pickup/dropoff '
        'lat/lng fall back to the (null) rider coordinates', () async {
      await users().doc(uid).set({'fullName': 'Rider Name'});
      final rideDoc = await addRide(
        driverUid: 'driver-1',
        fromLat: 12.0,
        fromLng: 77.0,
        toLat: 12.1,
        toLng: 77.1,
      );
      final ride = buildRideMatch(
        id: rideDoc.id,
        fromLat: 12.0,
        fromLng: 77.0,
        toLat: 12.1,
        toLng: 77.1,
      );

      await repository.requestRide(
        ride: ride,
        riderFromAddress: 'Rider From',
        riderToAddress: 'Rider To',
        riderTime: const TimeOfDay(hour: 8, minute: 0),
      );

      final requestsSnap = await rideRequests().get();
      final data = requestsSnap.docs.first.data();
      expect(data['pickupPoint'], 'Rider From');
      expect(data['pickupLatLng'], {'latitude': null, 'longitude': null});
      expect(data['riderStartLatLng'], isNull);
      expect(data['riderEndLatLng'], isNull);
    });
  });

  group('requestRideFromDetails', () {
    test('returns empty string when no user is signed in', () async {
      final unauth = MockFirebaseAuth();
      final repo = RidesRepositoryImpl(
        chatRepository: chatRepository,
        db: firestore,
        firebaseAuth: unauth,
        directions: directions,
      );
      final ride = buildRideMatch();

      final result = await repo.requestRideFromDetails(ride: ride);
      expect(result, '');
    });

    test('endpoint match uses the ride\'s own from/to; pickup time defaults '
        "to the RideMatch's own time field (not a separately supplied rider "
        'time)', () async {
      await users().doc(uid).set({'fullName': 'Rider Name'});
      final rideDoc = await addRide(
        driverUid: 'driver-1',
        fromLat: 12.0,
        fromLng: 77.0,
        toLat: 12.05,
        toLng: 77.05,
      );
      final ride = buildRideMatch(
        id: rideDoc.id,
        fromLat: 12.0,
        fromLng: 77.0,
        toLat: 12.05,
        toLng: 77.05,
        time: const TimeOfDay(hour: 7, minute: 15),
      );

      await repository.requestRideFromDetails(
        ride: ride,
        riderFromAddress: 'Rider From',
        riderFromLat: 12.0005,
        riderFromLng: 77.0005,
        riderToAddress: 'Rider To',
        riderToLat: 12.0505,
        riderToLng: 77.0505,
      );

      final requestsSnap = await rideRequests().get();
      final data = requestsSnap.docs.first.data();
      expect(data['pickupPoint'], 'Driver From');
      expect(data['dropOffPoint'], 'Driver To');
      expect(data['pickupTime'], {'hour': 7, 'minute': 15});

      final updatedRide = await rides().doc(rideDoc.id).get();
      expect(updatedRide.data()!['seatsFilled'], 1);
    });

    test('missing riderFromAddress/riderToAddress default to the ride\'s own '
        'addresses', () async {
      await users().doc(uid).set({'fullName': 'Rider Name'});
      final rideDoc = await addRide(driverUid: 'driver-1');
      final ride = buildRideMatch(id: rideDoc.id);

      await repository.requestRideFromDetails(ride: ride);

      final requestsSnap = await rideRequests().get();
      final data = requestsSnap.docs.first.data();
      expect(data['pickupPoint'], 'Driver From');
      expect(data['dropOffPoint'], 'Driver To');
      expect(data['riderStartAddress'], 'Driver From');
      expect(data['riderEndAddress'], 'Driver To');
    });

    test('detour match projects onto the route using rider coordinates',
        () async {
      await users().doc(uid).set({'fullName': 'Rider Name'});
      final rideDoc = await addRide(
        driverUid: 'driver-1',
        fromLat: 12.0,
        fromLng: 77.0,
        toLat: 12.1,
        toLng: 77.1,
      );
      final ride = buildRideMatch(
        id: rideDoc.id,
        fromLat: 12.0,
        fromLng: 77.0,
        toLat: 12.1,
        toLng: 77.1,
      );

      const riderFromLat = 12.05;
      const riderFromLng = 77.2;
      final expectedPickup = RideMatcher.projectPointToSegment(
        12.0,
        77.0,
        12.1,
        77.1,
        riderFromLat,
        riderFromLng,
      );

      await repository.requestRideFromDetails(
        ride: ride,
        riderFromAddress: 'Rider From',
        riderFromLat: riderFromLat,
        riderFromLng: riderFromLng,
        riderToAddress: 'Rider To',
        riderToLat: 12.06,
        riderToLng: 77.21,
      );

      final requestsSnap = await rideRequests().get();
      final data = requestsSnap.docs.first.data();
      expect(data['pickupPoint'], 'Rider From');
      expect(data['pickupLatLng'], expectedPickup);
    });
  });

  group('getAcceptedRiders', () {
    test('returns riders matching rideId and status, resolving employeeId '
        'from their user profile', () async {
      await rides().doc('ride-1').set({'seatsFilled': 1});
      await users().doc('rider-1').set({'employeeId': 'EMP-001'});
      await rideRequests().add({
        'rideId': 'ride-1',
        'riderId': 'rider-1',
        'riderName': 'Alice',
        'status': 'accepted',
        'pickupPoint': 'Somewhere',
        'pickupTime': {'hour': 9, 'minute': 30},
        'driverId': 'driver-1',
      });

      final result = await repository.getAcceptedRiders(rideId: 'ride-1');

      expect(result, hasLength(1));
      expect(result.first.riderId, 'rider-1');
      expect(result.first.riderName, 'Alice');
      expect(result.first.employeeId, 'EMP-001');
      expect(result.first.pickupTime, const TimeOfDay(hour: 9, minute: 30));
    });

    test('filters by driverId when provided', () async {
      await rides().doc('ride-1').set({'seatsFilled': 1});
      await rideRequests().add({
        'rideId': 'ride-1',
        'riderId': 'rider-1',
        'status': 'accepted',
        'driverId': 'driver-1',
      });
      await rideRequests().add({
        'rideId': 'ride-1',
        'riderId': 'rider-2',
        'status': 'accepted',
        'driverId': 'driver-2',
      });

      final result =
          await repository.getAcceptedRiders(rideId: 'ride-1', driverId: 'driver-1');

      expect(result, hasLength(1));
      expect(result.first.riderId, 'rider-1');
    });

    test('respects a non-default status filter', () async {
      await rideRequests().add({
        'rideId': 'ride-1',
        'riderId': 'rider-1',
        'status': 'pending',
      });
      await rideRequests().add({
        'rideId': 'ride-1',
        'riderId': 'rider-2',
        'status': 'accepted',
      });

      final result = await repository.getAcceptedRiders(rideId: 'ride-1', status: 'pending');

      expect(result, hasLength(1));
      expect(result.first.riderId, 'rider-1');
    });

    test('calls reconcileSeatsFilled (only for status == accepted), fixing '
        "a drifted seatsFilled count", () async {
      await rides().doc('ride-1').set({'seatsFilled': 5});
      await rideRequests().add({
        'rideId': 'ride-1',
        'riderId': 'rider-1',
        'status': 'accepted',
      });

      await repository.getAcceptedRiders(rideId: 'ride-1');

      final rideDoc = await rides().doc('ride-1').get();
      expect(rideDoc.data()!['seatsFilled'], 1);
    });

    test('does not reconcile seatsFilled for a non-accepted status query',
        () async {
      await rides().doc('ride-1').set({'seatsFilled': 5});
      await rideRequests().add({
        'rideId': 'ride-1',
        'riderId': 'rider-1',
        'status': 'pending',
      });

      await repository.getAcceptedRiders(rideId: 'ride-1', status: 'pending');

      final rideDoc = await rides().doc('ride-1').get();
      expect(rideDoc.data()!['seatsFilled'], 5);
    });

    test('parses pickupLatLng and dropOffLatLng maps when present', () async {
      await rides().doc('ride-1').set({'seatsFilled': 1});
      await rideRequests().add({
        'rideId': 'ride-1',
        'riderId': 'rider-1',
        'status': 'accepted',
        'pickupLatLng': {'latitude': 11.0, 'longitude': 22.0},
        'dropOffLatLng': {'latitude': 33.0, 'longitude': 44.0},
      });

      final result = await repository.getAcceptedRiders(rideId: 'ride-1');

      expect(result, hasLength(1));
      expect(result.first.pickupLat, 11.0);
      expect(result.first.pickupLng, 22.0);
      expect(result.first.dropOffLat, 33.0);
      expect(result.first.dropOffLng, 44.0);
    });
  });

  group('getOtherRiders', () {
    test('excludes the current signed-in user from the accepted riders list',
        () async {
      await users().doc('rider-2').set({'employeeId': 'EMP-002'});
      await rideRequests().add({
        'rideId': 'ride-1',
        'riderId': uid,
        'status': 'accepted',
      });
      await rideRequests().add({
        'rideId': 'ride-1',
        'riderId': 'rider-2',
        'riderName': 'Bob',
        'status': 'accepted',
      });

      final result = await repository.getOtherRiders('ride-1');

      expect(result, hasLength(1));
      expect(result.first.riderId, 'rider-2');
      expect(result.first.employeeId, 'EMP-002');
    });

    test('defaults employeeId to the placeholder when the user profile '
        'lookup finds nothing', () async {
      await rideRequests().add({
        'rideId': 'ride-1',
        'riderId': 'rider-2',
        'status': 'accepted',
      });

      final result = await repository.getOtherRiders('ride-1');

      expect(result.first.employeeId, 'AE2610002');
    });

    test('only considers requests with status == accepted', () async {
      await rideRequests().add({
        'rideId': 'ride-1',
        'riderId': 'rider-2',
        'status': 'pending',
      });

      final result = await repository.getOtherRiders('ride-1');

      expect(result, isEmpty);
    });

    test('parses the pickupLatLng map when present', () async {
      await rideRequests().add({
        'rideId': 'ride-1',
        'riderId': 'rider-2',
        'status': 'accepted',
        'pickupLatLng': {'latitude': 55.0, 'longitude': 66.0},
      });

      final result = await repository.getOtherRiders('ride-1');

      expect(result, hasLength(1));
      expect(result.first.pickupLat, 55.0);
      expect(result.first.pickupLng, 66.0);
    });
  });

  group('getRidersForCurrentDriver', () {
    test('returns empty when no user is signed in', () async {
      final unauth = MockFirebaseAuth();
      final repo = RidesRepositoryImpl(
        chatRepository: chatRepository,
        db: firestore,
        firebaseAuth: unauth,
        directions: directions,
      );

      final result = await repo.getRidersForCurrentDriver(rideId: 'ride-1');
      expect(result, isEmpty);
    });

    test('delegates to getAcceptedRiders scoped to the current driver uid',
        () async {
      await rides().doc('ride-1').set({'seatsFilled': 1});
      await rideRequests().add({
        'rideId': 'ride-1',
        'riderId': 'rider-1',
        'status': 'accepted',
        'driverId': uid,
      });
      await rideRequests().add({
        'rideId': 'ride-1',
        'riderId': 'rider-2',
        'status': 'accepted',
        'driverId': 'someone-else',
      });

      final result = await repository.getRidersForCurrentDriver(rideId: 'ride-1');

      expect(result, hasLength(1));
      expect(result.first.riderId, 'rider-1');
    });
  });

  group('cancelRiderRequest', () {
    test('sets the request status to rejected and decrements seatsFilled',
        () async {
      final requestDoc = await rideRequests().add({
        'rideId': 'ride-1',
        'riderId': 'rider-1',
        'status': 'accepted',
      });
      await rides().doc('ride-1').set({'seatsFilled': 2});

      await repository.cancelRiderRequest(requestId: requestDoc.id, rideId: 'ride-1');

      final updatedRequest = await rideRequests().doc(requestDoc.id).get();
      expect(updatedRequest.data()!['status'], 'rejected');

      final updatedRide = await rides().doc('ride-1').get();
      expect(updatedRide.data()!['seatsFilled'], 1);
    });

    test('does not decrement seatsFilled below zero', () async {
      final requestDoc = await rideRequests().add({
        'rideId': 'ride-1',
        'riderId': 'rider-1',
        'status': 'accepted',
      });
      await rides().doc('ride-1').set({'seatsFilled': 0});

      await repository.cancelRiderRequest(requestId: requestDoc.id, rideId: 'ride-1');

      final updatedRide = await rides().doc('ride-1').get();
      expect(updatedRide.data()!['seatsFilled'], 0);
    });
  });

  group('updateRideStatus', () {
    test('updates the ride document status field', () async {
      await rides().doc('ride-1').set({'status': 'upcoming'});

      await repository.updateRideStatus('ride-1', 'ongoing');

      final doc = await rides().doc('ride-1').get();
      expect(doc.data()!['status'], 'ongoing');
    });
  });

  group('cancelRide', () {
    test('marks the ride cancelled with a reason and cascades cancellation '
        'to all its ride_requests', () async {
      await rides().doc('ride-1').set({'status': 'upcoming'});
      final req1 = await rideRequests().add({'rideId': 'ride-1', 'status': 'accepted'});
      final req2 = await rideRequests().add({'rideId': 'ride-1', 'status': 'pending'});
      final unrelated = await rideRequests().add({'rideId': 'ride-2', 'status': 'accepted'});

      await repository.cancelRide('ride-1', reason: 'weather');

      final rideDoc = await rides().doc('ride-1').get();
      expect(rideDoc.data()!['status'], 'cancelled');
      expect(rideDoc.data()!['cancellationReason'], 'weather');
      expect(rideDoc.data()!['cancelledAt'], isNotNull);

      final r1 = await rideRequests().doc(req1.id).get();
      final r2 = await rideRequests().doc(req2.id).get();
      final r3 = await rideRequests().doc(unrelated.id).get();
      expect(r1.data()!['status'], 'cancelled');
      expect(r1.data()!['cancellationReason'], 'Driver cancelled: weather');
      expect(r2.data()!['status'], 'cancelled');
      expect(r3.data()!['status'], 'accepted');
    });
  });

  group('reconcileSeatsFilled', () {
    test('updates seatsFilled when it has drifted from the accepted count',
        () async {
      await rides().doc('ride-1').set({'seatsFilled': 3});

      await repository.reconcileSeatsFilled('ride-1', 1);

      final doc = await rides().doc('ride-1').get();
      expect(doc.data()!['seatsFilled'], 1);
    });

    test('does nothing when seatsFilled already matches', () async {
      await rides().doc('ride-1').set({'seatsFilled': 2});

      await repository.reconcileSeatsFilled('ride-1', 2);

      final doc = await rides().doc('ride-1').get();
      expect(doc.data()!['seatsFilled'], 2);
    });
  });

  group('isRideOwnedByCurrentUser', () {
    test('returns true when the ride uid matches the current user', () async {
      await rides().doc('ride-1').set({'uid': uid});
      expect(await repository.isRideOwnedByCurrentUser('ride-1'), isTrue);
    });

    test('returns false when the ride uid differs', () async {
      await rides().doc('ride-1').set({'uid': 'someone-else'});
      expect(await repository.isRideOwnedByCurrentUser('ride-1'), isFalse);
    });

    test('returns false when the ride document does not exist', () async {
      expect(await repository.isRideOwnedByCurrentUser('missing'), isFalse);
    });
  });

  group('watchRideNote / updateRideNote', () {
    test('watchRideNote emits null then subsequent note updates written by '
        'updateRideNote', () async {
      await rides().doc('ride-1').set({'note': null});

      final emitted = <String?>[];
      final sub = repository.watchRideNote('ride-1').listen(emitted.add);

      await Future<void>.delayed(Duration.zero);
      await repository.updateRideNote('ride-1', 'Waiting outside');
      await Future<void>.delayed(Duration.zero);

      expect(emitted, contains('Waiting outside'));
      await sub.cancel();
    });

    test('watchRideNote emits null for a non-existent ride document',
        () async {
      final emitted = <String?>[];
      final sub = repository.watchRideNote('missing').listen(emitted.add);
      await Future<void>.delayed(Duration.zero);

      expect(emitted, [null]);
      await sub.cancel();
    });
  });

  group('getRiderJourney', () {
    test('accepted-request-found branch: uses the request\'s stored pickup/'
        'dropoff points and rider addresses', () async {
      final ride = buildRideMatch(id: 'ride-1');
      await rideRequests().add({
        'rideId': 'ride-1',
        'riderId': uid,
        'status': 'accepted',
        'pickupPoint': 'Stored Pickup',
        'dropOffPoint': 'Stored Dropoff',
        'riderStartAddress': 'Stored Start',
        'riderEndAddress': 'Stored End',
        'pickupLatLng': {'latitude': 1.0, 'longitude': 2.0},
        'dropOffLatLng': {'latitude': 3.0, 'longitude': 4.0},
      });
      await rides().doc('ride-1').set({
        'pinnedLatLng': {'latitude': 5.0, 'longitude': 6.0},
        'pinnedName': 'Pinned Spot',
        'routeDurationMinutes': 42,
      });

      final journey = await repository.getRiderJourney(ride: ride);

      expect(journey.pickupPoint, 'Stored Pickup');
      expect(journey.dropOffPoint, 'Stored Dropoff');
      expect(journey.riderStartAddress, 'Stored Start');
      expect(journey.riderEndAddress, 'Stored End');
      expect(journey.pickupLat, 1.0);
      expect(journey.pickupLng, 2.0);
      expect(journey.dropOffLat, 3.0);
      expect(journey.dropOffLng, 4.0);
      expect(journey.pinnedLat, 5.0);
      expect(journey.pinnedLng, 6.0);
      expect(journey.pinnedName, 'Pinned Spot');
      expect(journey.driveDurationMinutes, 42);
    });

    test('not-found branch: falls back to the ride\'s own from/to addresses '
        'and the default 20-minute duration', () async {
      final ride = buildRideMatch(id: 'ride-2');
      await rides().doc('ride-2').set({});

      final journey = await repository.getRiderJourney(ride: ride);

      expect(journey.pickupPoint, ride.fromAddress);
      expect(journey.dropOffPoint, ride.toAddress);
      expect(journey.driveDurationMinutes, 20);
      expect(journey.pinnedLat, isNull);
    });

    test('passed-in rider addresses take precedence over the request\'s '
        'stored addresses when non-empty', () async {
      final ride = buildRideMatch(id: 'ride-3');
      await rideRequests().add({
        'rideId': 'ride-3',
        'riderId': uid,
        'status': 'accepted',
        'riderStartAddress': 'Stored Start',
        'riderEndAddress': 'Stored End',
      });
      await rides().doc('ride-3').set({});

      final journey = await repository.getRiderJourney(
        ride: ride,
        riderFromAddress: 'Passed Start',
        riderToAddress: 'Passed End',
      );

      expect(journey.riderStartAddress, 'Passed Start');
      expect(journey.riderEndAddress, 'Passed End');
    });

    test('accepted-request-found branch: falls back to the request\'s '
        'riderStartLatLng/riderEndLatLng maps when no rider lat/lng was '
        'passed in', () async {
      final ride = buildRideMatch(id: 'ride-4');
      await rideRequests().add({
        'rideId': 'ride-4',
        'riderId': uid,
        'status': 'accepted',
        'riderStartLatLng': {'latitude': 10.0, 'longitude': 20.0},
        'riderEndLatLng': {'latitude': 30.0, 'longitude': 40.0},
      });
      await rides().doc('ride-4').set({});

      final journey = await repository.getRiderJourney(ride: ride);

      expect(journey.riderStartLat, 10.0);
      expect(journey.riderStartLng, 20.0);
      expect(journey.riderEndLat, 30.0);
      expect(journey.riderEndLng, 40.0);
    });
  });

  group('completeRide', () {
    test('marks the current user\'s ride_request completed with the '
        'payment method', () async {
      final requestDoc = await rideRequests().add({
        'rideId': 'ride-1',
        'riderId': uid,
        'status': 'accepted',
      });

      await repository.completeRide(rideId: 'ride-1', paymentMethod: 'upi');

      final updated = await rideRequests().doc(requestDoc.id).get();
      expect(updated.data()!['status'], 'completed');
      expect(updated.data()!['paymentMethod'], 'upi');
    });

    test('does nothing (no error) when no matching request exists', () async {
      await expectLater(
        repository.completeRide(rideId: 'ride-missing', paymentMethod: 'upi'),
        completes,
      );
    });

    test('does nothing when no user is signed in', () async {
      final unauth = MockFirebaseAuth();
      final repo = RidesRepositoryImpl(
        chatRepository: chatRepository,
        db: firestore,
        firebaseAuth: unauth,
        directions: directions,
      );
      await expectLater(
        repo.completeRide(rideId: 'ride-1', paymentMethod: 'upi'),
        completes,
      );
    });
  });

  group('sendRideChatMessage', () {
    test('resolves the sender name and sends via ChatRepository with a '
        'deterministic sorted chat id', () async {
      await users().doc(uid).set({'fullName': 'Sender Name'});

      await repository.sendRideChatMessage(
        driverId: 'driver-1',
        driverName: 'Driver One',
        text: 'Hello',
      );

      final expectedChatId = ([uid, 'driver-1']..sort()).join('_');
      final captured = verify(() => chatRepository.sendMessage(
            expectedChatId,
            captureAny(),
            'Sender Name',
            'Driver One',
          )).captured;
      final message = captured.single as ChatMessage;
      expect(message.senderId, uid);
      expect(message.receiverId, 'driver-1');
      expect(message.text, 'Hello');
    });

    test('does nothing when no user is signed in', () async {
      final unauth = MockFirebaseAuth();
      final repo = RidesRepositoryImpl(
        chatRepository: chatRepository,
        db: firestore,
        firebaseAuth: unauth,
        directions: directions,
      );

      await repo.sendRideChatMessage(driverId: 'driver-1', driverName: 'Driver', text: 'Hi');

      verifyNever(() => chatRepository.sendMessage(any(), any(), any(), any()));
    });
  });

  group('ensureGroupChat', () {
    test('creates/merges the group chat document with the expected fields',
        () async {
      await repository.ensureGroupChat(
        rideId: 'ride-1',
        groupTitle: 'Trip Group',
        rideDate: DateTime(2026, 6, 15),
        participantIds: ['a', 'b'],
        participantNames: {'a': 'Alice', 'b': 'Bob'},
        participantPhotos: {'a': 'photoA'},
      );

      final doc = await firestore.collection('chats').doc('ride-1').get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['type'], 'group');
      expect(doc.data()!['groupTitle'], 'Trip Group');
      expect(doc.data()!['participants'], containsAll(['a', 'b']));
      expect(doc.data()!['participantNames'], {'a': 'Alice', 'b': 'Bob'});
    });

    test('merges with (does not overwrite) previously-set fields', () async {
      await firestore.collection('chats').doc('ride-1').set({'customField': 'keep-me'});

      await repository.ensureGroupChat(
        rideId: 'ride-1',
        groupTitle: 'Trip Group',
        rideDate: DateTime(2026, 6, 15),
        participantIds: ['a'],
        participantNames: const {},
        participantPhotos: const {},
      );

      final doc = await firestore.collection('chats').doc('ride-1').get();
      expect(doc.data()!['customField'], 'keep-me');
    });
  });
}
