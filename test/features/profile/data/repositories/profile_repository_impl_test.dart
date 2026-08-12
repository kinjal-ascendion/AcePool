import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:acepool/features/profile/data/repositories/profile_repository_impl.dart';

void main() {
  const uid = 'user1';

  FakeFirebaseFirestore buildDb() => FakeFirebaseFirestore();

  MockFirebaseAuth buildAuth({bool signedIn = true, String? displayName}) {
    if (!signedIn) {
      return MockFirebaseAuth();
    }
    return MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: uid, displayName: displayName),
    );
  }

  group('watchProfile', () {
    test('emits empty stream when no user is signed in', () async {
      final db = buildDb();
      final auth = buildAuth(signedIn: false);
      final repo = ProfileRepositoryImpl(db: db, firebaseAuth: auth);

      final events = await repo.watchProfile().toList();

      expect(events, isEmpty);
    });

    test('maps fields with defaults when doc has no data', () async {
      final db = buildDb();
      final auth = buildAuth();
      final repo = ProfileRepositoryImpl(db: db, firebaseAuth: auth);

      final summary = await repo.watchProfile().first;

      expect(summary.fullName, '');
      expect(summary.employeeId, '');
      expect(summary.phone, isNull);
      expect(summary.licenceVerified, isNull);
      expect(summary.licenceNumber, isNull);
      expect(summary.travelPreference, isNull);
      expect(summary.hasVehicles, isFalse);
    });

    test('maps all fields from an existing doc', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('users').doc(uid).set({
        'fullName': 'Jane Doe',
        'employeeId': 'E1',
        'phone': '123',
        'licenceVerified': true,
        'licenceNumber': 'LIC1',
        'travelPreference': 'drive',
        'hasVehicles': true,
      });
      final repo = ProfileRepositoryImpl(db: db, firebaseAuth: auth);

      final summary = await repo.watchProfile().first;

      expect(summary.fullName, 'Jane Doe');
      expect(summary.employeeId, 'E1');
      expect(summary.phone, '123');
      expect(summary.licenceVerified, isTrue);
      expect(summary.licenceNumber, 'LIC1');
      expect(summary.travelPreference, 'drive');
      expect(summary.hasVehicles, isTrue);
    });

    test('falls back to snake_case travel_preference when camelCase missing', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('users').doc(uid).set({
        'fullName': 'Jane',
        'employeeId': 'E1',
        'travel_preference': 'ride',
      });
      final repo = ProfileRepositoryImpl(db: db, firebaseAuth: auth);

      final summary = await repo.watchProfile().first;

      expect(summary.travelPreference, 'ride');
    });

    test('prefers camelCase travelPreference over snake_case when both present', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('users').doc(uid).set({
        'fullName': 'Jane',
        'employeeId': 'E1',
        'travelPreference': 'drive',
        'travel_preference': 'ride',
      });
      final repo = ProfileRepositoryImpl(db: db, firebaseAuth: auth);

      final summary = await repo.watchProfile().first;

      expect(summary.travelPreference, 'drive');
    });

    test('emits new value when doc updates', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('users').doc(uid).set({'fullName': 'First', 'employeeId': 'E1'});
      final repo = ProfileRepositoryImpl(db: db, firebaseAuth: auth);

      final future = repo.watchProfile().take(2).toList();
      await Future<void>.delayed(Duration.zero);
      await db.collection('users').doc(uid).update({'fullName': 'Second'});

      final events = await future;
      expect(events[0].fullName, 'First');
      expect(events[1].fullName, 'Second');
    });
  });

  group('updateProfile', () {
    test('updates firestore fields and syncs display name when changed', () async {
      final db = buildDb();
      final auth = buildAuth(displayName: 'Old Name');
      await db.collection('users').doc(uid).set({'fullName': 'Old Name'});
      final repo = ProfileRepositoryImpl(db: db, firebaseAuth: auth);

      await repo.updateProfile(fullName: 'New Name', phone: '999', email: 'a@b.com');

      final doc = await db.collection('users').doc(uid).get();
      expect(doc.data()!['fullName'], 'New Name');
      expect(doc.data()!['phone'], '999');
      expect(doc.data()!['email'], 'a@b.com');
      expect(auth.currentUser!.displayName, 'New Name');
    });

    test('does not sync display name when fullName is unchanged', () async {
      final db = buildDb();
      final auth = buildAuth(displayName: 'Same Name');
      await db.collection('users').doc(uid).set({'fullName': 'Same Name'});
      final repo = ProfileRepositoryImpl(db: db, firebaseAuth: auth);

      await repo.updateProfile(fullName: 'Same Name', phone: '999', email: 'a@b.com');

      expect(auth.currentUser!.displayName, 'Same Name');
    });

    test('sets licenceVerified and licenceNumber when licenceVerified is true', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('users').doc(uid).set({'fullName': 'Jane'});
      final repo = ProfileRepositoryImpl(db: db, firebaseAuth: auth);

      await repo.updateProfile(
        fullName: 'Jane',
        phone: '999',
        email: 'a@b.com',
        licenceVerified: true,
        licenceNumber: 'LIC9',
      );

      final doc = await db.collection('users').doc(uid).get();
      expect(doc.data()!['licenceVerified'], isTrue);
      expect(doc.data()!['licenceNumber'], 'LIC9');
    });

    test('does not set licence fields when licenceVerified is false', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('users').doc(uid).set({'fullName': 'Jane'});
      final repo = ProfileRepositoryImpl(db: db, firebaseAuth: auth);

      await repo.updateProfile(
        fullName: 'Jane',
        phone: '999',
        email: 'a@b.com',
        licenceVerified: false,
        licenceNumber: 'LIC9',
      );

      final doc = await db.collection('users').doc(uid).get();
      expect(doc.data()!.containsKey('licenceVerified'), isFalse);
      expect(doc.data()!.containsKey('licenceNumber'), isFalse);
    });

    test('does not set licenceNumber when licenceVerified true but licenceNumber null', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('users').doc(uid).set({'fullName': 'Jane'});
      final repo = ProfileRepositoryImpl(db: db, firebaseAuth: auth);

      await repo.updateProfile(
        fullName: 'Jane',
        phone: '999',
        email: 'a@b.com',
        licenceVerified: true,
      );

      final doc = await db.collection('users').doc(uid).get();
      expect(doc.data()!['licenceVerified'], isTrue);
      expect(doc.data()!.containsKey('licenceNumber'), isFalse);
    });
  });

  group('getRouteMatchingRadius', () {
    test('returns 0.0 when doc does not exist', () async {
      final db = buildDb();
      final auth = buildAuth();
      final repo = ProfileRepositoryImpl(db: db, firebaseAuth: auth);

      final radius = await repo.getRouteMatchingRadius();

      expect(radius, 0.0);
    });

    test('returns 0.0 when doc exists but has no radius field', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('users').doc(uid).set({'fullName': 'Jane'});
      final repo = ProfileRepositoryImpl(db: db, firebaseAuth: auth);

      final radius = await repo.getRouteMatchingRadius();

      expect(radius, 0.0);
    });

    test('returns stored radius as a double', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('users').doc(uid).set({'routeMatchingRadius': 5});
      final repo = ProfileRepositoryImpl(db: db, firebaseAuth: auth);

      final radius = await repo.getRouteMatchingRadius();

      expect(radius, 5.0);
    });
  });

  group('saveRouteMatchingRadius', () {
    test('merges radius into existing doc without overwriting other fields', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('users').doc(uid).set({'fullName': 'Jane'});
      final repo = ProfileRepositoryImpl(db: db, firebaseAuth: auth);

      await repo.saveRouteMatchingRadius(7.5);

      final doc = await db.collection('users').doc(uid).get();
      expect(doc.data()!['routeMatchingRadius'], 7.5);
      expect(doc.data()!['fullName'], 'Jane');
    });

    test('creates doc when it does not exist', () async {
      final db = buildDb();
      final auth = buildAuth();
      final repo = ProfileRepositoryImpl(db: db, firebaseAuth: auth);

      await repo.saveRouteMatchingRadius(3.0);

      final doc = await db.collection('users').doc(uid).get();
      expect(doc.data()!['routeMatchingRadius'], 3.0);
    });
  });

  group('logout', () {
    test('calls auth.signOut and clears currentUser', () async {
      final db = buildDb();
      final auth = buildAuth();
      final repo = ProfileRepositoryImpl(db: db, firebaseAuth: auth);

      expect(auth.currentUser, isNotNull);

      await repo.logout();

      expect(auth.currentUser, isNull);
    });
  });

  group('savePaymentDetails', () {
    test('does nothing when no user is signed in', () async {
      final db = buildDb();
      final auth = buildAuth(signedIn: false);
      final repo = ProfileRepositoryImpl(db: db, firebaseAuth: auth);

      await repo.savePaymentDetails(method: 'UPI', upiId: 'a@upi', upiPhone: '999');

      final doc = await db.collection('users').doc(uid).get();
      expect(doc.exists, isFalse);
    });

    test('updates payment fields when user is signed in', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('users').doc(uid).set({'fullName': 'Jane'});
      final repo = ProfileRepositoryImpl(db: db, firebaseAuth: auth);

      await repo.savePaymentDetails(method: 'CARD', upiId: 'a@upi', upiPhone: '999');

      final doc = await db.collection('users').doc(uid).get();
      expect(doc.data()!['paymentMethod'], 'CARD');
      expect(doc.data()!['upiId'], 'a@upi');
      expect(doc.data()!['upiPhone'], '999');
    });
  });

  group('getPaymentDetails', () {
    test('returns defaults when no user is signed in', () async {
      final db = buildDb();
      final auth = buildAuth(signedIn: false);
      final repo = ProfileRepositoryImpl(db: db, firebaseAuth: auth);

      final result = await repo.getPaymentDetails();

      expect(result.method, 'UPI');
      expect(result.upiId, '');
      expect(result.upiPhone, '');
    });

    test('returns defaults when doc has no payment fields', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('users').doc(uid).set({'fullName': 'Jane'});
      final repo = ProfileRepositoryImpl(db: db, firebaseAuth: auth);

      final result = await repo.getPaymentDetails();

      expect(result.method, 'UPI');
      expect(result.upiId, '');
      expect(result.upiPhone, '');
    });

    test('returns stored payment fields', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('users').doc(uid).set({
        'paymentMethod': 'CARD',
        'upiId': 'a@upi',
        'upiPhone': '999',
      });
      final repo = ProfileRepositoryImpl(db: db, firebaseAuth: auth);

      final result = await repo.getPaymentDetails();

      expect(result.method, 'CARD');
      expect(result.upiId, 'a@upi');
      expect(result.upiPhone, '999');
    });
  });
}
