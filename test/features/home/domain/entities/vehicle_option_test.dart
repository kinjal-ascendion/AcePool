import 'package:acepool/features/home/domain/entities/vehicle_option.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VehicleOption', () {
    test('stores id, label, and type', () {
      const option = VehicleOption(id: 'v1', label: 'Honda Activa', type: 'two_wheeler');

      expect(option.id, 'v1');
      expect(option.label, 'Honda Activa');
      expect(option.type, 'two_wheeler');
    });

    test('supports value equality', () {
      const a = VehicleOption(id: 'v1', label: 'Honda Activa', type: 'two_wheeler');
      const b = VehicleOption(id: 'v1', label: 'Honda Activa', type: 'two_wheeler');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('differs when any field differs', () {
      const a = VehicleOption(id: 'v1', label: 'Honda Activa', type: 'two_wheeler');
      const b = VehicleOption(id: 'v2', label: 'Honda Activa', type: 'two_wheeler');

      expect(a, isNot(b));
    });
  });
}
