import 'package:acepool/features/profile/domain/entities/vehicle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Vehicle', () {
    test('constructor assigns all fields', () {
      const vehicle = Vehicle(
        id: 'v1',
        type: 'four_wheeler',
        number: 'AB123',
        brand: 'Honda',
        model: 'City',
        seats: 4,
        isDefault: true,
      );

      expect(vehicle.id, 'v1');
      expect(vehicle.type, 'four_wheeler');
      expect(vehicle.number, 'AB123');
      expect(vehicle.brand, 'Honda');
      expect(vehicle.model, 'City');
      expect(vehicle.seats, 4);
      expect(vehicle.isDefault, isTrue);
    });

    group('isFourWheeler', () {
      test('true when type is four_wheeler', () {
        const vehicle = Vehicle(
          id: 'v1',
          type: 'four_wheeler',
          number: 'AB123',
          brand: 'Honda',
          model: 'City',
          seats: 4,
          isDefault: false,
        );
        expect(vehicle.isFourWheeler, isTrue);
      });

      test('false when type is two_wheeler', () {
        const vehicle = Vehicle(
          id: 'v1',
          type: 'two_wheeler',
          number: 'AB123',
          brand: 'Honda',
          model: 'Activa',
          seats: 2,
          isDefault: false,
        );
        expect(vehicle.isFourWheeler, isFalse);
      });
    });

    group('displayName', () {
      test('joins brand and model with a space', () {
        const vehicle = Vehicle(
          id: 'v1',
          type: 'four_wheeler',
          number: 'AB123',
          brand: 'Honda',
          model: 'City',
          seats: 4,
          isDefault: false,
        );
        expect(vehicle.displayName, 'Honda City');
      });

      test('omits empty brand', () {
        const vehicle = Vehicle(
          id: 'v1',
          type: 'four_wheeler',
          number: 'AB123',
          brand: '',
          model: 'City',
          seats: 4,
          isDefault: false,
        );
        expect(vehicle.displayName, 'City');
      });

      test('omits empty model', () {
        const vehicle = Vehicle(
          id: 'v1',
          type: 'four_wheeler',
          number: 'AB123',
          brand: 'Honda',
          model: '',
          seats: 4,
          isDefault: false,
        );
        expect(vehicle.displayName, 'Honda');
      });

      test('is empty string when both brand and model are empty', () {
        const vehicle = Vehicle(
          id: 'v1',
          type: 'four_wheeler',
          number: 'AB123',
          brand: '',
          model: '',
          seats: 4,
          isDefault: false,
        );
        expect(vehicle.displayName, '');
      });
    });
  });
}
