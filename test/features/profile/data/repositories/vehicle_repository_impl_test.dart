import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:acepool/features/profile/data/repositories/vehicle_repository_impl.dart';

void main() {
  const uid = 'user1';

  FakeFirebaseFirestore buildDb() => FakeFirebaseFirestore();

  MockFirebaseAuth buildAuth() =>
      MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: uid));

  group('watchVehicles', () {
    test('emits empty list when there are no vehicles', () async {
      final db = buildDb();
      final auth = buildAuth();
      final repo = VehicleRepositoryImpl(db: db, firebaseAuth: auth);

      final vehicles = await repo.watchVehicles().first;

      expect(vehicles, isEmpty);
    });

    test('maps stored vehicle fields', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db
          .collection('users')
          .doc(uid)
          .collection('vehicles')
          .doc('v1')
          .set({
        'type': 'two_wheeler',
        'number': 'AB123',
        'brand': 'Honda',
        'model': 'Activa',
        'seats': 2,
        'isDefault': true,
      });
      final repo = VehicleRepositoryImpl(db: db, firebaseAuth: auth);

      final vehicles = await repo.watchVehicles().first;

      expect(vehicles, hasLength(1));
      expect(vehicles.first.id, 'v1');
      expect(vehicles.first.type, 'two_wheeler');
      expect(vehicles.first.number, 'AB123');
      expect(vehicles.first.brand, 'Honda');
      expect(vehicles.first.model, 'Activa');
      expect(vehicles.first.seats, 2);
      expect(vehicles.first.isDefault, isTrue);
    });

    test('applies defaults for missing fields', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('users').doc(uid).collection('vehicles').doc('v1').set({});
      final repo = VehicleRepositoryImpl(db: db, firebaseAuth: auth);

      final vehicles = await repo.watchVehicles().first;

      expect(vehicles.first.type, 'four_wheeler');
      expect(vehicles.first.number, '');
      expect(vehicles.first.brand, '');
      expect(vehicles.first.model, '');
      expect(vehicles.first.seats, 0);
      expect(vehicles.first.isDefault, isFalse);
    });

    test('emits updated list when a vehicle is added', () async {
      final db = buildDb();
      final auth = buildAuth();
      final repo = VehicleRepositoryImpl(db: db, firebaseAuth: auth);

      final future = repo.watchVehicles().take(2).toList();
      await Future<void>.delayed(Duration.zero);
      await db.collection('users').doc(uid).collection('vehicles').doc('v1').set({
        'type': 'four_wheeler',
        'number': 'X1',
        'brand': 'B',
        'model': 'M',
        'seats': 4,
        'isDefault': false,
      });

      final events = await future;
      expect(events[0], isEmpty);
      expect(events[1], hasLength(1));
    });
  });

  group('deleteVehicle', () {
    test('removes the vehicle doc', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('users').doc(uid).collection('vehicles').doc('v1').set({
        'type': 'four_wheeler',
      });
      final repo = VehicleRepositoryImpl(db: db, firebaseAuth: auth);

      await repo.deleteVehicle('v1');

      final doc =
          await db.collection('users').doc(uid).collection('vehicles').doc('v1').get();
      expect(doc.exists, isFalse);
    });
  });

  group('addVehicle', () {
    test('adds vehicle with provided fields when isDefault is false', () async {
      final db = buildDb();
      final auth = buildAuth();
      final repo = VehicleRepositoryImpl(db: db, firebaseAuth: auth);

      await repo.addVehicle(
        type: 'four_wheeler',
        number: 'AB123',
        brand: 'Honda',
        model: 'City',
        seats: 4,
        isDefault: false,
      );

      final snapshot =
          await db.collection('users').doc(uid).collection('vehicles').get();
      expect(snapshot.docs, hasLength(1));
      final data = snapshot.docs.first.data();
      expect(data['type'], 'four_wheeler');
      expect(data['number'], 'AB123');
      expect(data['brand'], 'Honda');
      expect(data['model'], 'City');
      expect(data['seats'], 4);
      expect(data['isDefault'], isFalse);
    });

    test('does not touch existing vehicles when isDefault is false', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('users').doc(uid).collection('vehicles').doc('existing').set({
        'type': 'four_wheeler',
        'isDefault': true,
      });
      final repo = VehicleRepositoryImpl(db: db, firebaseAuth: auth);

      await repo.addVehicle(
        type: 'two_wheeler',
        number: 'X1',
        brand: 'B',
        model: 'M',
        seats: 2,
        isDefault: false,
      );

      final existingDoc = await db
          .collection('users')
          .doc(uid)
          .collection('vehicles')
          .doc('existing')
          .get();
      expect(existingDoc.data()!['isDefault'], isTrue);
    });

    test('unsets isDefault on existing vehicles when adding a new default', () async {
      final db = buildDb();
      final auth = buildAuth();
      await db.collection('users').doc(uid).collection('vehicles').doc('existing1').set({
        'type': 'four_wheeler',
        'isDefault': true,
      });
      await db.collection('users').doc(uid).collection('vehicles').doc('existing2').set({
        'type': 'two_wheeler',
        'isDefault': false,
      });
      final repo = VehicleRepositoryImpl(db: db, firebaseAuth: auth);

      await repo.addVehicle(
        type: 'four_wheeler',
        number: 'NEW',
        brand: 'B',
        model: 'M',
        seats: 4,
        isDefault: true,
      );

      final vehiclesRef = db.collection('users').doc(uid).collection('vehicles');
      final existing1 = await vehiclesRef.doc('existing1').get();
      final existing2 = await vehiclesRef.doc('existing2').get();
      expect(existing1.data()!['isDefault'], isFalse);
      expect(existing2.data()!['isDefault'], isFalse);

      final all = await vehiclesRef.get();
      expect(all.docs, hasLength(3));
      final newDoc = all.docs.firstWhere((d) => d.data()['number'] == 'NEW');
      expect(newDoc.data()['isDefault'], isTrue);
    });
  });
}
