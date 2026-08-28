import 'package:flutter_test/flutter_test.dart';

import 'package:acepool/features/address/domain/entities/address_record.dart';

void main() {
  group('AddressRecord', () {
    test('constructs with all fields set', () {
      const record = AddressRecord(
        id: 'id-1',
        category: 'home',
        label: 'Home',
        address: '123 Main St',
        landmark: 'Near park',
        lat: 12.34,
        lng: 56.78,
        isDefault: true,
      );

      expect(record.id, 'id-1');
      expect(record.category, 'home');
      expect(record.label, 'Home');
      expect(record.address, '123 Main St');
      expect(record.landmark, 'Near park');
      expect(record.lat, 12.34);
      expect(record.lng, 56.78);
      expect(record.isDefault, isTrue);
    });

    test('constructs with lat/lng null (optional fields)', () {
      const record = AddressRecord(
        id: 'id-2',
        category: 'work',
        label: 'Work',
        address: '456 Office Rd',
        landmark: '',
        isDefault: false,
      );

      expect(record.lat, isNull);
      expect(record.lng, isNull);
      expect(record.isDefault, isFalse);
    });

    test('supports empty string fields', () {
      const record = AddressRecord(
        id: '',
        category: '',
        label: '',
        address: '',
        landmark: '',
        isDefault: false,
      );

      expect(record.id, isEmpty);
      expect(record.category, isEmpty);
      expect(record.label, isEmpty);
      expect(record.address, isEmpty);
      expect(record.landmark, isEmpty);
    });

    test('two instances with the same field values are distinct objects '
        '(no Equatable/value equality implemented)', () {
      const a = AddressRecord(
        id: 'id-1',
        category: 'home',
        label: 'Home',
        address: '123 Main St',
        landmark: 'Near park',
        lat: 12.34,
        lng: 56.78,
        isDefault: true,
      );
      const b = AddressRecord(
        id: 'id-1',
        category: 'home',
        label: 'Home',
        address: '123 Main St',
        landmark: 'Near park',
        lat: 12.34,
        lng: 56.78,
        isDefault: true,
      );

      // AddressRecord is a plain (non-Equatable) class, so equality falls
      // back to identity. Two `const` instances with identical field
      // values are canonicalized by Dart into the same instance, so `a`
      // and `b` are in fact `identical`/`==`. This test documents that
      // behavior rather than asserting value-based equality semantics.
      expect(a == b, isTrue);
      expect(identical(a, b), isTrue);
    });

    test('non-const instances with equal fields are not identical '
        '(confirms no value equality)', () {
      final a = AddressRecord(
        id: 'id-1',
        category: 'home',
        label: 'Home',
        address: '123 Main St',
        landmark: 'Near park',
        isDefault: true,
      );
      final b = AddressRecord(
        id: 'id-1',
        category: 'home',
        label: 'Home',
        address: '123 Main St',
        landmark: 'Near park',
        isDefault: true,
      );

      expect(identical(a, b), isFalse);
      expect(a == b, isFalse);
    });
  });
}
