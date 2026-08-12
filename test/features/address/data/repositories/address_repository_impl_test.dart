import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:acepool/features/address/data/repositories/address_repository_impl.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;
  late AddressRepositoryImpl repository;

  const uid = 'test-uid';

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: uid));
    repository = AddressRepositoryImpl(db: firestore, firebaseAuth: auth);
  });

  CollectionReference<Map<String, dynamic>> addressesRef() =>
      firestore.collection('users').doc(uid).collection('addresses');

  group('getAddresses', () {
    test('returns empty list when there are no addresses', () async {
      final result = await repository.getAddresses();
      expect(result, isEmpty);
    });

    test('maps documents to AddressRecord with all fields populated',
        () async {
      await addressesRef().add({
        'category': 'home',
        'label': 'Home',
        'address': '123 Main St',
        'landmark': 'Near park',
        'lat': 12.34,
        'lng': 56.78,
        'isDefault': true,
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
      });

      final result = await repository.getAddresses();

      expect(result, hasLength(1));
      final record = result.first;
      expect(record.category, 'home');
      expect(record.label, 'Home');
      expect(record.address, '123 Main St');
      expect(record.landmark, 'Near park');
      expect(record.lat, 12.34);
      expect(record.lng, 56.78);
      expect(record.isDefault, isTrue);
    });

    test('defaults missing string fields to empty string and isDefault to '
        'false, lat/lng to null', () async {
      await addressesRef().add(<String, dynamic>{
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
      });

      final result = await repository.getAddresses();

      expect(result, hasLength(1));
      final record = result.first;
      expect(record.category, '');
      expect(record.label, '');
      expect(record.address, '');
      expect(record.landmark, '');
      expect(record.lat, isNull);
      expect(record.lng, isNull);
      expect(record.isDefault, isFalse);
    });

    test('converts integer lat/lng (num) to double', () async {
      await addressesRef().add({
        'category': 'work',
        'label': 'Work',
        'address': 'Office',
        'landmark': '',
        'lat': 10,
        'lng': 20,
        'isDefault': false,
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
      });

      final result = await repository.getAddresses();

      expect(result.first.lat, 10.0);
      expect(result.first.lng, 20.0);
    });

    test('sorts results by createdAt ascending', () async {
      await addressesRef().add({
        'category': 'home',
        'label': 'Second',
        'address': 'B',
        'landmark': '',
        'isDefault': false,
        'createdAt': Timestamp.fromDate(DateTime(2024, 2, 1)),
      });
      await addressesRef().add({
        'category': 'home',
        'label': 'First',
        'address': 'A',
        'landmark': '',
        'isDefault': false,
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
      });
      await addressesRef().add({
        'category': 'home',
        'label': 'Third',
        'address': 'C',
        'landmark': '',
        'isDefault': false,
        'createdAt': Timestamp.fromDate(DateTime(2024, 3, 1)),
      });

      final result = await repository.getAddresses();

      expect(result.map((r) => r.label).toList(), ['First', 'Second', 'Third']);
    });

    test('treats documents with null createdAt as equal in sort order '
        '(comparator returns 0)', () async {
      await addressesRef().add({
        'category': 'home',
        'label': 'NoDate1',
        'address': 'A',
        'landmark': '',
        'isDefault': false,
      });
      await addressesRef().add({
        'category': 'home',
        'label': 'NoDate2',
        'address': 'B',
        'landmark': '',
        'isDefault': false,
      });

      final result = await repository.getAddresses();

      expect(result, hasLength(2));
      expect(
        result.map((r) => r.label).toSet(),
        {'NoDate1', 'NoDate2'},
      );
    });
  });

  group('saveAddress - create (isEdit: false)', () {
    test('lowercases the category before saving', () async {
      await repository.saveAddress(
        isEdit: false,
        category: 'HoMe',
        label: 'Home',
        address: '123 Main St',
        landmark: 'Near park',
      );

      final snapshot = await addressesRef().get();
      expect(snapshot.docs, hasLength(1));
      expect(snapshot.docs.first.data()['category'], 'home');
    });

    test('marks the first address in a category as isDefault true',
        () async {
      await repository.saveAddress(
        isEdit: false,
        category: 'home',
        label: 'Home',
        address: '123 Main St',
        landmark: 'Near park',
      );

      final snapshot = await addressesRef().get();
      expect(snapshot.docs.first.data()['isDefault'], isTrue);
    });

    test('marks subsequent addresses in the same category as isDefault '
        'false', () async {
      await repository.saveAddress(
        isEdit: false,
        category: 'home',
        label: 'Home 1',
        address: 'A',
        landmark: '',
      );
      await repository.saveAddress(
        isEdit: false,
        category: 'home',
        label: 'Home 2',
        address: 'B',
        landmark: '',
      );

      final snapshot = await addressesRef().get();
      expect(snapshot.docs, hasLength(2));

      final byLabel = {
        for (final doc in snapshot.docs) doc.data()['label']: doc.data(),
      };
      expect(byLabel['Home 1']!['isDefault'], isTrue);
      expect(byLabel['Home 2']!['isDefault'], isFalse);
    });

    test('first address in a new (different) category is also isDefault '
        'true, independent of other categories', () async {
      await repository.saveAddress(
        isEdit: false,
        category: 'home',
        label: 'Home',
        address: 'A',
        landmark: '',
      );
      await repository.saveAddress(
        isEdit: false,
        category: 'work',
        label: 'Work',
        address: 'B',
        landmark: '',
      );

      final snapshot = await addressesRef().get();
      final byLabel = {
        for (final doc in snapshot.docs) doc.data()['label']: doc.data(),
      };
      expect(byLabel['Home']!['isDefault'], isTrue);
      expect(byLabel['Work']!['isDefault'], isTrue);
    });

    test('sets lat/lng and createdAt on create', () async {
      await repository.saveAddress(
        isEdit: false,
        category: 'home',
        label: 'Home',
        address: 'A',
        landmark: '',
        lat: 1.1,
        lng: 2.2,
      );

      final snapshot = await addressesRef().get();
      final data = snapshot.docs.first.data();
      expect(data['lat'], 1.1);
      expect(data['lng'], 2.2);
      expect(data['createdAt'], isNotNull);
    });
  });

  group('saveAddress - edit (isEdit: true)', () {
    test('updates the existing document fields without touching isDefault',
        () async {
      final docRef = await addressesRef().add({
        'category': 'home',
        'label': 'Home',
        'address': 'Old address',
        'landmark': 'Old landmark',
        'lat': 1.0,
        'lng': 2.0,
        'isDefault': true,
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
      });

      await repository.saveAddress(
        isEdit: true,
        docId: docRef.id,
        category: 'Home',
        label: 'Home Updated',
        address: 'New address',
        landmark: 'New landmark',
        lat: 3.0,
        lng: 4.0,
      );

      final updated = await addressesRef().doc(docRef.id).get();
      final data = updated.data()!;
      expect(data['category'], 'home');
      expect(data['label'], 'Home Updated');
      expect(data['address'], 'New address');
      expect(data['landmark'], 'New landmark');
      expect(data['lat'], 3.0);
      expect(data['lng'], 4.0);
      // isDefault field is not part of the edit payload, so the
      // previously-set value should remain untouched.
      expect(data['isDefault'], isTrue);
    });

    test('does not query existing docs for isFirstInCategory when editing',
        () async {
      // Seed an existing doc for the category so that, if the
      // implementation incorrectly ran the "first in category" check
      // during edit, it would find this doc and behave differently.
      await addressesRef().add({
        'category': 'home',
        'label': 'Existing',
        'address': 'X',
        'landmark': '',
        'isDefault': true,
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
      });
      final docRef = await addressesRef().add({
        'category': 'home',
        'label': 'ToEdit',
        'address': 'Y',
        'landmark': '',
        'isDefault': false,
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 2)),
      });

      await repository.saveAddress(
        isEdit: true,
        docId: docRef.id,
        category: 'home',
        label: 'Edited',
        address: 'Z',
        landmark: '',
      );

      final updated = await addressesRef().doc(docRef.id).get();
      // isDefault should be untouched (false), not set to true, since
      // the edit branch never writes isDefault.
      expect(updated.data()!['isDefault'], isFalse);
    });
  });

  group('deleteAddress', () {
    test('deletes the document', () async {
      final docRef = await addressesRef().add({
        'category': 'home',
        'label': 'Home',
        'address': 'A',
        'landmark': '',
        'isDefault': true,
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
      });

      await repository.deleteAddress(
        docId: docRef.id,
        category: 'home',
        wasDefault: true,
      );

      final snapshot = await addressesRef().doc(docRef.id).get();
      expect(snapshot.exists, isFalse);
    });

    test('when wasDefault is false, does not touch other docs in the '
        'category', () async {
      final docToDelete = await addressesRef().add({
        'category': 'home',
        'label': 'ToDelete',
        'address': 'A',
        'landmark': '',
        'isDefault': false,
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
      });
      final otherDoc = await addressesRef().add({
        'category': 'home',
        'label': 'Other',
        'address': 'B',
        'landmark': '',
        'isDefault': true,
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 2)),
      });

      await repository.deleteAddress(
        docId: docToDelete.id,
        category: 'home',
        wasDefault: false,
      );

      final other = await addressesRef().doc(otherDoc.id).get();
      expect(other.data()!['isDefault'], isTrue);
    });

    test('when wasDefault is true and another address exists in the '
        'category, promotes it to default', () async {
      final docToDelete = await addressesRef().add({
        'category': 'home',
        'label': 'ToDelete',
        'address': 'A',
        'landmark': '',
        'isDefault': true,
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
      });
      final otherDoc = await addressesRef().add({
        'category': 'home',
        'label': 'Other',
        'address': 'B',
        'landmark': '',
        'isDefault': false,
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 2)),
      });

      await repository.deleteAddress(
        docId: docToDelete.id,
        category: 'home',
        wasDefault: true,
      );

      final other = await addressesRef().doc(otherDoc.id).get();
      expect(other.data()!['isDefault'], isTrue);
    });

    test('when wasDefault is true and no remaining address exists in the '
        'category, does nothing further (no error)', () async {
      final docToDelete = await addressesRef().add({
        'category': 'home',
        'label': 'OnlyOne',
        'address': 'A',
        'landmark': '',
        'isDefault': true,
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
      });

      await repository.deleteAddress(
        docId: docToDelete.id,
        category: 'home',
        wasDefault: true,
      );

      final snapshot = await addressesRef().get();
      expect(snapshot.docs, isEmpty);
    });

    test('promotion only considers docs in the same category', () async {
      final docToDelete = await addressesRef().add({
        'category': 'home',
        'label': 'HomeDefault',
        'address': 'A',
        'landmark': '',
        'isDefault': true,
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
      });
      final workDoc = await addressesRef().add({
        'category': 'work',
        'label': 'Work',
        'address': 'B',
        'landmark': '',
        'isDefault': false,
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 2)),
      });

      await repository.deleteAddress(
        docId: docToDelete.id,
        category: 'home',
        wasDefault: true,
      );

      final work = await addressesRef().doc(workDoc.id).get();
      // The 'work' category doc must not be promoted since it's a
      // different category than the deleted 'home' address.
      expect(work.data()!['isDefault'], isFalse);
    });
  });
}
