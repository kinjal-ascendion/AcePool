import 'package:acepool/features/home/domain/entities/picked_location.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PickedLocation', () {
    test('stores address with null lat/lng by default', () {
      const location = PickedLocation(address: '123 Main St');

      expect(location.address, '123 Main St');
      expect(location.lat, isNull);
      expect(location.lng, isNull);
    });

    test('stores address with lat/lng when provided', () {
      const location = PickedLocation(
        address: '123 Main St',
        lat: 12.34,
        lng: 56.78,
      );

      expect(location.lat, 12.34);
      expect(location.lng, 56.78);
    });

    test('supports value equality', () {
      const a = PickedLocation(address: 'A', lat: 1, lng: 2);
      const b = PickedLocation(address: 'A', lat: 1, lng: 2);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('differs when address differs', () {
      const a = PickedLocation(address: 'A');
      const b = PickedLocation(address: 'B');

      expect(a, isNot(b));
    });

    test('differs when lat/lng differ', () {
      const a = PickedLocation(address: 'A', lat: 1, lng: 2);
      const b = PickedLocation(address: 'A', lat: 1, lng: 3);

      expect(a, isNot(b));
    });
  });
}
