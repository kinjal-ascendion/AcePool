import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:acepool/features/profile/data/repositories/ride_history_repository_impl.dart';

void main() {
  const uid = 'user1';

  FakeFirebaseFirestore buildDb() => FakeFirebaseFirestore();

  MockFirebaseAuth buildAuth({bool signedIn = true}) {
    if (!signedIn) return MockFirebaseAuth();
    return MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: uid));
  }

  group('getHistory', () {
    test('returns empty list when no user is signed in', () async {
      final db = buildDb();
      final auth = buildAuth(signedIn: false);
      final repo = RideHistoryRepositoryImpl(db: db, firebaseAuth: auth);

      final history = await repo.getHistory();

      expect(history, isEmpty);
    });

    test('returns empty list when there are no rides', () async {
      final db = buildDb();
      final auth = buildAuth();
      final repo = RideHistoryRepositoryImpl(db: db, firebaseAuth: auth);

      final history = await repo.getHistory();

      expect(history, isEmpty);
    });

    test('includes driver-side completed and cancelled rides', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('rides').doc('ride1').set({
        'uid': uid,
        'status': 'completed',
        'date': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'fromAddress': 'A',
        'toAddress': 'B',
      });
      await db.collection('rides').doc('ride2').set({
        'uid': uid,
        'status': 'cancelled',
        'date': Timestamp.fromDate(DateTime(2024, 1, 2)),
        'fromAddress': 'C',
        'toAddress': 'D',
      });
      // Ride with a status that should be excluded.
      await db.collection('rides').doc('ride3').set({
        'uid': uid,
        'status': 'active',
        'date': Timestamp.fromDate(DateTime(2024, 1, 3)),
      });
      final repo = RideHistoryRepositoryImpl(db: db, firebaseAuth: auth);

      final history = await repo.getHistory();

      expect(history, hasLength(2));
      expect(history.map((r) => r['id']), containsAll(['ride1', 'ride2']));
    });

    test('merges rider-side ride_requests with full ride details', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('rides').doc('ride1').set({
        'uid': 'otherDriver',
        'status': 'completed',
        'date': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'fromAddress': 'RideFrom',
        'toAddress': 'RideTo',
        'rideMode': 'offer',
      });
      await db.collection('ride_requests').doc('req1').set({
        'riderId': uid,
        'rideId': 'ride1',
        'status': 'completed',
        'pickupPoint': 'RequestPickup',
        'dropOffPoint': 'RequestDrop',
      });
      final repo = RideHistoryRepositoryImpl(db: db, firebaseAuth: auth);

      final history = await repo.getHistory();

      expect(history, hasLength(1));
      final entry = history.first;
      expect(entry['id'], 'ride1');
      expect(entry['status'], 'completed');
      expect(entry['rideMode'], 'find');
      expect(entry['fromAddress'], 'RequestPickup');
      expect(entry['toAddress'], 'RequestDrop');
    });

    test('falls back to ride fromAddress/toAddress when request has no pickup/dropoff', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('rides').doc('ride1').set({
        'uid': 'otherDriver',
        'status': 'completed',
        'date': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'fromAddress': 'RideFrom',
        'toAddress': 'RideTo',
      });
      await db.collection('ride_requests').doc('req1').set({
        'riderId': uid,
        'rideId': 'ride1',
        'status': 'cancelled',
      });
      final repo = RideHistoryRepositoryImpl(db: db, firebaseAuth: auth);

      final history = await repo.getHistory();

      expect(history, hasLength(1));
      expect(history.first['fromAddress'], 'RideFrom');
      expect(history.first['toAddress'], 'RideTo');
    });

    test('skips rider ride_request when referenced ride doc does not exist', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('ride_requests').doc('req1').set({
        'riderId': uid,
        'rideId': 'missingRide',
        'status': 'completed',
      });
      final repo = RideHistoryRepositoryImpl(db: db, firebaseAuth: auth);

      final history = await repo.getHistory();

      expect(history, isEmpty);
    });

    test('sorts combined driver and rider rides by date descending', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('rides').doc('rideOld').set({
        'uid': uid,
        'status': 'completed',
        'date': Timestamp.fromDate(DateTime(2024, 1, 1)),
      });
      await db.collection('rides').doc('rideNew').set({
        'uid': 'otherDriver',
        'status': 'completed',
        'date': Timestamp.fromDate(DateTime(2024, 6, 1)),
      });
      await db.collection('ride_requests').doc('req1').set({
        'riderId': uid,
        'rideId': 'rideNew',
        'status': 'completed',
      });
      final repo = RideHistoryRepositoryImpl(db: db, firebaseAuth: auth);

      final history = await repo.getHistory();

      expect(history, hasLength(2));
      expect(history[0]['id'], 'rideNew');
      expect(history[1]['id'], 'rideOld');
    });

    test('does not throw and returns list when date field is missing on some rides', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('rides').doc('ride1').set({
        'uid': uid,
        'status': 'completed',
      });
      final repo = RideHistoryRepositoryImpl(db: db, firebaseAuth: auth);

      final history = await repo.getHistory();

      expect(history, hasLength(1));
    });
  });
}
