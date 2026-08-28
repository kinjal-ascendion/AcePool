import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:acepool/features/profile/data/repositories/ratings_repository_impl.dart';

void main() {
  const uid = 'user1';

  FakeFirebaseFirestore buildDb() => FakeFirebaseFirestore();

  MockFirebaseAuth buildAuth({bool signedIn = true}) {
    if (!signedIn) return MockFirebaseAuth();
    return MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: uid));
  }

  group('getRatingsReceivedFromDrivers', () {
    test('returns zeroed summary when no user is signed in', () async {
      final db = buildDb();
      final auth = buildAuth(signedIn: false);
      final repo = RatingsRepositoryImpl(db: db, firebaseAuth: auth);

      final summary = await repo.getRatingsReceivedFromDrivers();

      expect(summary.averageRating, 0);
      expect(summary.totalReviews, 0);
      expect(summary.ratingCounts, isEmpty);
      expect(summary.rides, isEmpty);
    });

    test('aggregates driver ratings across multiple completed rides', () async {
      final db = buildDb();
      final auth = buildAuth();

      await db.collection('rides').doc('rideA').set({
        'status': 'completed',
        'date': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'time': {'hour': 9, 'minute': 0},
        'fromAddress': 'A-from',
        'toAddress': 'A-to',
      });
      await db.collection('rides').doc('rideB').set({
        'status': 'completed',
        'date': Timestamp.fromDate(DateTime(2024, 2, 1)),
        'time': {'hour': 10, 'minute': 30},
        'fromAddress': 'B-from',
        'toAddress': 'B-to',
      });

      await db.collection('ride_requests').doc('req1').set({
        'riderId': uid,
        'status': 'accepted',
        'driverRating': 5,
        'rideId': 'rideA',
      });
      await db.collection('ride_requests').doc('req2').set({
        'riderId': uid,
        'status': 'accepted',
        'driverRating': 3,
        'rideId': 'rideB',
      });

      final repo = RatingsRepositoryImpl(db: db, firebaseAuth: auth);
      final summary = await repo.getRatingsReceivedFromDrivers();

      expect(summary.totalReviews, 2);
      expect(summary.ratingCounts, {5: 1, 4: 0, 3: 1, 2: 0, 1: 0});
      expect(summary.averageRating, 4.0);
      expect(summary.rides, hasLength(2));
      final rideAEntry = summary.rides.firstWhere((r) => r.rideId == 'rideA');
      expect(rideAEntry.rating, 5.0);
      expect(rideAEntry.pickup, 'A-from');
      expect(rideAEntry.drop, 'A-to');
      expect(rideAEntry.reviews, 1);
    });

    test('skips requests with no driverRating', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('rides').doc('rideA').set({
        'status': 'completed',
        'date': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'time': {'hour': 9, 'minute': 0},
        'fromAddress': 'A-from',
        'toAddress': 'A-to',
      });
      await db.collection('ride_requests').doc('req1').set({
        'riderId': uid,
        'status': 'accepted',
        'rideId': 'rideA',
      });

      final repo = RatingsRepositoryImpl(db: db, firebaseAuth: auth);
      final summary = await repo.getRatingsReceivedFromDrivers();

      expect(summary.totalReviews, 0);
      expect(summary.rides, isEmpty);
    });

    test('skips requests whose ride doc does not exist', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('ride_requests').doc('req1').set({
        'riderId': uid,
        'status': 'accepted',
        'driverRating': 5,
        'rideId': 'missingRide',
      });

      final repo = RatingsRepositoryImpl(db: db, firebaseAuth: auth);
      final summary = await repo.getRatingsReceivedFromDrivers();

      expect(summary.totalReviews, 0);
      expect(summary.rides, isEmpty);
    });

    test('skips requests whose ride is not completed', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('rides').doc('rideA').set({
        'status': 'active',
        'date': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'time': {'hour': 9, 'minute': 0},
        'fromAddress': 'A-from',
        'toAddress': 'A-to',
      });
      await db.collection('ride_requests').doc('req1').set({
        'riderId': uid,
        'status': 'accepted',
        'driverRating': 5,
        'rideId': 'rideA',
      });

      final repo = RatingsRepositoryImpl(db: db, firebaseAuth: auth);
      final summary = await repo.getRatingsReceivedFromDrivers();

      expect(summary.totalReviews, 0);
      expect(summary.rides, isEmpty);
    });
  });

  group('getRatingsReceivedFromRiders', () {
    test('returns zeroed summary when no user is signed in', () async {
      final db = buildDb();
      final auth = buildAuth(signedIn: false);
      final repo = RatingsRepositoryImpl(db: db, firebaseAuth: auth);

      final summary = await repo.getRatingsReceivedFromRiders();

      expect(summary.averageRating, 0);
      expect(summary.totalReviews, 0);
      expect(summary.ratingCounts, isEmpty);
      expect(summary.rides, isEmpty);
    });

    test(
        'double-counts totals across multiple rated riders on the same ride '
        '(one outer iteration per rated request, each re-summing all riders)',
        () async {
      final db = buildDb();
      final auth = buildAuth();

      await db.collection('rides').doc('rideY').set({
        'status': 'completed',
      });

      await db.collection('ride_requests').doc('req1').set({
        'driverId': uid,
        'status': 'accepted',
        'riderRating': 5,
        'rideId': 'rideY',
        'rideDate': Timestamp.fromDate(DateTime(2024, 3, 1)),
        'rideTime': {'hour': 8, 'minute': 0},
        'rideFrom': 'Y-from',
        'rideTo': 'Y-to',
      });
      await db.collection('ride_requests').doc('req2').set({
        'driverId': uid,
        'status': 'accepted',
        'riderRating': 3,
        'rideId': 'rideY',
        'rideDate': Timestamp.fromDate(DateTime(2024, 3, 1)),
        'rideTime': {'hour': 8, 'minute': 0},
        'rideFrom': 'Y-from',
        'rideTo': 'Y-to',
      });

      final repo = RatingsRepositoryImpl(db: db, firebaseAuth: auth);
      final summary = await repo.getRatingsReceivedFromRiders();

      // Outer loop runs once per rated request (2 total). Each iteration
      // re-queries and re-sums BOTH riders' ratings on the ride, so totals
      // are doubled relative to the "true" 2-review case.
      expect(summary.totalReviews, 4);
      expect(summary.ratingCounts, {5: 2, 4: 0, 3: 2, 2: 0, 1: 0});
      expect(summary.averageRating, 4.0);
      expect(summary.rides, hasLength(2));
      for (final ride in summary.rides) {
        expect(ride.rideId, 'rideY');
        expect(ride.rating, 4.0);
        expect(ride.reviews, 2);
        expect(ride.pickup, 'Y-from');
        expect(ride.drop, 'Y-to');
      }
    });

    test('produces a single accurate entry when only one rider has rated', () async {
      final db = buildDb();
      final auth = buildAuth();

      await db.collection('rides').doc('rideZ').set({'status': 'completed'});
      await db.collection('ride_requests').doc('req1').set({
        'driverId': uid,
        'status': 'accepted',
        'riderRating': 4,
        'rideId': 'rideZ',
        'rideDate': Timestamp.fromDate(DateTime(2024, 4, 1)),
        'rideTime': {'hour': 7, 'minute': 15},
        'rideFrom': 'Z-from',
        'rideTo': 'Z-to',
      });

      final repo = RatingsRepositoryImpl(db: db, firebaseAuth: auth);
      final summary = await repo.getRatingsReceivedFromRiders();

      expect(summary.totalReviews, 1);
      expect(summary.ratingCounts, {5: 0, 4: 1, 3: 0, 2: 0, 1: 0});
      expect(summary.averageRating, 4.0);
      expect(summary.rides, hasLength(1));
      expect(summary.rides.first.rating, 4.0);
      expect(summary.rides.first.reviews, 1);
    });

    test('skips requests with no riderRating', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('rides').doc('rideZ').set({'status': 'completed'});
      await db.collection('ride_requests').doc('req1').set({
        'driverId': uid,
        'status': 'accepted',
        'rideId': 'rideZ',
      });

      final repo = RatingsRepositoryImpl(db: db, firebaseAuth: auth);
      final summary = await repo.getRatingsReceivedFromRiders();

      expect(summary.totalReviews, 0);
      expect(summary.rides, isEmpty);
    });

    test('skips requests whose ride doc does not exist', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('ride_requests').doc('req1').set({
        'driverId': uid,
        'status': 'accepted',
        'riderRating': 5,
        'rideId': 'missingRide',
      });

      final repo = RatingsRepositoryImpl(db: db, firebaseAuth: auth);
      final summary = await repo.getRatingsReceivedFromRiders();

      expect(summary.totalReviews, 0);
      expect(summary.rides, isEmpty);
    });

    test('skips requests whose ride is not completed', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('rides').doc('rideZ').set({'status': 'active'});
      await db.collection('ride_requests').doc('req1').set({
        'driverId': uid,
        'status': 'accepted',
        'riderRating': 5,
        'rideId': 'rideZ',
      });

      final repo = RatingsRepositoryImpl(db: db, firebaseAuth: auth);
      final summary = await repo.getRatingsReceivedFromRiders();

      expect(summary.totalReviews, 0);
      expect(summary.rides, isEmpty);
    });
  });

  group('getMyCompletedRidesToRate', () {
    test('returns empty list when no user is signed in', () async {
      final db = buildDb();
      final auth = buildAuth(signedIn: false);
      final repo = RatingsRepositoryImpl(db: db, firebaseAuth: auth);

      final rides = await repo.getMyCompletedRidesToRate();

      expect(rides, isEmpty);
    });

    test('returns rides for completed accepted requests', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('rides').doc('rideA').set({'status': 'completed'});
      await db.collection('ride_requests').doc('req1').set({
        'riderId': uid,
        'status': 'accepted',
        'rideId': 'rideA',
        'driverId': 'driverX',
        'rideDate': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'rideTime': {'hour': 6, 'minute': 45},
        'rideFrom': 'From',
        'rideTo': 'To',
        'riderRating': null,
      });

      final repo = RatingsRepositoryImpl(db: db, firebaseAuth: auth);
      final rides = await repo.getMyCompletedRidesToRate();

      expect(rides, hasLength(1));
      final ride = rides.first;
      expect(ride.requestId, 'req1');
      expect(ride.rideId, 'rideA');
      expect(ride.driverId, 'driverX');
      expect(ride.pickup, 'From');
      expect(ride.drop, 'To');
      expect(ride.riderRating, isNull);
    });

    test('includes riderRating when already set', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('rides').doc('rideA').set({'status': 'completed'});
      await db.collection('ride_requests').doc('req1').set({
        'riderId': uid,
        'status': 'accepted',
        'rideId': 'rideA',
        'driverId': 'driverX',
        'rideDate': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'rideTime': {'hour': 6, 'minute': 45},
        'rideFrom': 'From',
        'rideTo': 'To',
        'riderRating': 5,
      });

      final repo = RatingsRepositoryImpl(db: db, firebaseAuth: auth);
      final rides = await repo.getMyCompletedRidesToRate();

      expect(rides.first.riderRating, 5);
    });

    test('skips requests whose ride doc does not exist', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('ride_requests').doc('req1').set({
        'riderId': uid,
        'status': 'accepted',
        'rideId': 'missingRide',
        'driverId': 'driverX',
        'rideDate': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'rideTime': {'hour': 6, 'minute': 45},
        'rideFrom': 'From',
        'rideTo': 'To',
      });

      final repo = RatingsRepositoryImpl(db: db, firebaseAuth: auth);
      final rides = await repo.getMyCompletedRidesToRate();

      expect(rides, isEmpty);
    });

    test('skips requests whose ride is not completed', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('rides').doc('rideA').set({'status': 'active'});
      await db.collection('ride_requests').doc('req1').set({
        'riderId': uid,
        'status': 'accepted',
        'rideId': 'rideA',
        'driverId': 'driverX',
        'rideDate': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'rideTime': {'hour': 6, 'minute': 45},
        'rideFrom': 'From',
        'rideTo': 'To',
      });

      final repo = RatingsRepositoryImpl(db: db, firebaseAuth: auth);
      final rides = await repo.getMyCompletedRidesToRate();

      expect(rides, isEmpty);
    });
  });

  group('submitRiderRating', () {
    test('updates riderRating and sets riderRatedAt', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('ride_requests').doc('req1').set({'status': 'accepted'});

      final repo = RatingsRepositoryImpl(db: db, firebaseAuth: auth);
      await repo.submitRiderRating(requestId: 'req1', rating: 4);

      final doc = await db.collection('ride_requests').doc('req1').get();
      expect(doc.data()!['riderRating'], 4);
      expect(doc.data()!['riderRatedAt'], isNotNull);
    });
  });

  group('getRidersToReview', () {
    test('returns riders with employeeId from users collection', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('users').doc('rider1').set({'employeeId': 'EMP1'});
      await db.collection('ride_requests').doc('req1').set({
        'rideId': 'rideA',
        'status': 'accepted',
        'riderId': 'rider1',
        'riderName': 'Rider One',
        'pickupPoint': 'Pickup',
        'dropOffPoint': 'Dropoff',
        'driverRating': null,
      });

      final repo = RatingsRepositoryImpl(db: db, firebaseAuth: auth);
      final riders = await repo.getRidersToReview('rideA');

      expect(riders, hasLength(1));
      final rider = riders.first;
      expect(rider.requestId, 'req1');
      expect(rider.riderId, 'rider1');
      expect(rider.riderName, 'Rider One');
      expect(rider.employeeId, 'EMP1');
      expect(rider.pickupPoint, 'Pickup');
      expect(rider.dropOffPoint, 'Dropoff');
      expect(rider.driverRating, isNull);
    });

    test('defaults employeeId, pickupPoint, dropOffPoint when missing', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('ride_requests').doc('req1').set({
        'rideId': 'rideA',
        'status': 'accepted',
        'riderId': 'riderMissing',
        'riderName': 'Rider Two',
      });

      final repo = RatingsRepositoryImpl(db: db, firebaseAuth: auth);
      final riders = await repo.getRidersToReview('rideA');

      expect(riders, hasLength(1));
      expect(riders.first.employeeId, '');
      expect(riders.first.pickupPoint, '');
      expect(riders.first.dropOffPoint, '');
    });

    test('only returns riders for the given rideId with accepted status', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('ride_requests').doc('req1').set({
        'rideId': 'rideOther',
        'status': 'accepted',
        'riderId': 'riderX',
        'riderName': 'X',
      });

      final repo = RatingsRepositoryImpl(db: db, firebaseAuth: auth);
      final riders = await repo.getRidersToReview('rideA');

      expect(riders, isEmpty);
    });
  });

  group('submitDriverRating', () {
    test('updates driverRating and sets driverRatedAt', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('ride_requests').doc('req1').set({'status': 'accepted'});

      final repo = RatingsRepositoryImpl(db: db, firebaseAuth: auth);
      await repo.submitDriverRating(requestId: 'req1', rating: 5);

      final doc = await db.collection('ride_requests').doc('req1').get();
      expect(doc.data()!['driverRating'], 5);
      expect(doc.data()!['driverRatedAt'], isNotNull);
    });
  });

  group('getMyCompletedRidesAsDriver', () {
    test('returns empty list when no user is signed in', () async {
      final db = buildDb();
      final auth = buildAuth(signedIn: false);
      final repo = RatingsRepositoryImpl(db: db, firebaseAuth: auth);

      final rides = await repo.getMyCompletedRidesAsDriver();

      expect(rides, isEmpty);
    });

    test('counts ratedRiders and totalRiders, and sets driverRating flag', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('rides').doc('rideA').set({
        'uid': uid,
        'status': 'completed',
        'date': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'time': {'hour': 9, 'minute': 0},
        'fromAddress': 'From',
        'toAddress': 'To',
      });
      await db.collection('ride_requests').doc('req1').set({
        'rideId': 'rideA',
        'status': 'accepted',
        'driverRating': 5,
      });
      await db.collection('ride_requests').doc('req2').set({
        'rideId': 'rideA',
        'status': 'accepted',
        'driverRating': null,
      });

      final repo = RatingsRepositoryImpl(db: db, firebaseAuth: auth);
      final rides = await repo.getMyCompletedRidesAsDriver();

      expect(rides, hasLength(1));
      final ride = rides.first;
      expect(ride.rideId, 'rideA');
      expect(ride.driverId, uid);
      expect(ride.totalRiders, 2);
      expect(ride.ratedRiders, 1);
      expect(ride.driverRating, 1);
      expect(ride.pickup, 'From');
      expect(ride.drop, 'To');
    });

    test('driverRating is null when no riders have been rated', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('rides').doc('rideA').set({
        'uid': uid,
        'status': 'completed',
        'date': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'time': {'hour': 9, 'minute': 0},
        'fromAddress': 'From',
        'toAddress': 'To',
      });
      await db.collection('ride_requests').doc('req1').set({
        'rideId': 'rideA',
        'status': 'accepted',
      });

      final repo = RatingsRepositoryImpl(db: db, firebaseAuth: auth);
      final rides = await repo.getMyCompletedRidesAsDriver();

      expect(rides.first.ratedRiders, 0);
      expect(rides.first.totalRiders, 1);
      expect(rides.first.driverRating, isNull);
    });

    test('only includes rides owned by uid with completed status', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('rides').doc('rideOther').set({
        'uid': 'otherUser',
        'status': 'completed',
        'date': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'time': {'hour': 9, 'minute': 0},
        'fromAddress': 'From',
        'toAddress': 'To',
      });
      await db.collection('rides').doc('rideIncomplete').set({
        'uid': uid,
        'status': 'active',
        'date': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'time': {'hour': 9, 'minute': 0},
        'fromAddress': 'From',
        'toAddress': 'To',
      });

      final repo = RatingsRepositoryImpl(db: db, firebaseAuth: auth);
      final rides = await repo.getMyCompletedRidesAsDriver();

      expect(rides, isEmpty);
    });
  });
}
