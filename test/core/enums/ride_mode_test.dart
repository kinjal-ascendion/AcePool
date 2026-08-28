import 'package:acepool/core/enums/ride_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RideMode', () {
    test('has exactly the expected two values, in order', () {
      expect(RideMode.values, [RideMode.takeRide, RideMode.offerRide]);
    });

    test('takeRide has the expected name and index', () {
      expect(RideMode.takeRide.name, 'takeRide');
      expect(RideMode.takeRide.index, 0);
    });

    test('offerRide has the expected name and index', () {
      expect(RideMode.offerRide.name, 'offerRide');
      expect(RideMode.offerRide.index, 1);
    });

    test('values are distinguishable', () {
      expect(RideMode.takeRide, isNot(RideMode.offerRide));
    });
  });
}
