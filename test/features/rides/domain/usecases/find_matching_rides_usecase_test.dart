import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:acepool/features/rides/domain/entities/ride_match.dart';
import 'package:acepool/features/rides/domain/repositories/rides_repository.dart';
import 'package:acepool/features/rides/domain/usecases/find_matching_rides_usecase.dart';

class MockRidesRepository extends Mock implements RidesRepository {}

void main() {
  late MockRidesRepository repository;
  late FindMatchingRidesUseCase useCase;

  setUpAll(() {
    registerFallbackValue(const TimeOfDay(hour: 0, minute: 0));
  });

  setUp(() {
    repository = MockRidesRepository();
    useCase = FindMatchingRidesUseCase(repository);
  });

  final date = DateTime(2026, 1, 1);
  const time = TimeOfDay(hour: 10, minute: 0);

  group('FindMatchingRidesUseCase', () {
    test('forwards all parameters to the repository', () async {
      when(() => repository.findMatchingRides(
            fromAddress: any(named: 'fromAddress'),
            toAddress: any(named: 'toAddress'),
            fromLat: any(named: 'fromLat'),
            fromLng: any(named: 'fromLng'),
            toLat: any(named: 'toLat'),
            toLng: any(named: 'toLng'),
            date: any(named: 'date'),
            time: any(named: 'time'),
            vehicleType: any(named: 'vehicleType'),
          )).thenAnswer((_) async => <RideMatch>[]);

      await useCase(
        fromAddress: 'Home',
        toAddress: 'Office',
        fromLat: 1.1,
        fromLng: 2.2,
        toLat: 3.3,
        toLng: 4.4,
        date: date,
        time: time,
        vehicleType: 'car',
      );

      verify(() => repository.findMatchingRides(
            fromAddress: 'Home',
            toAddress: 'Office',
            fromLat: 1.1,
            fromLng: 2.2,
            toLat: 3.3,
            toLng: 4.4,
            date: date,
            time: time,
            vehicleType: 'car',
          )).called(1);
    });

    test('forwards null optional lat/lng values as-is', () async {
      when(() => repository.findMatchingRides(
            fromAddress: any(named: 'fromAddress'),
            toAddress: any(named: 'toAddress'),
            fromLat: any(named: 'fromLat'),
            fromLng: any(named: 'fromLng'),
            toLat: any(named: 'toLat'),
            toLng: any(named: 'toLng'),
            date: any(named: 'date'),
            time: any(named: 'time'),
            vehicleType: any(named: 'vehicleType'),
          )).thenAnswer((_) async => <RideMatch>[]);

      await useCase(
        fromAddress: 'Home',
        toAddress: 'Office',
        date: date,
        time: time,
        vehicleType: 'bike',
      );

      verify(() => repository.findMatchingRides(
            fromAddress: 'Home',
            toAddress: 'Office',
            fromLat: null,
            fromLng: null,
            toLat: null,
            toLng: null,
            date: date,
            time: time,
            vehicleType: 'bike',
          )).called(1);
    });

    test('returns the list produced by the repository', () async {
      final match = RideMatch(
        id: 'ride-1',
        driverId: 'driver-1',
        driverName: 'Driver',
        date: date,
        time: time,
        fromAddress: 'Home',
        toAddress: 'Office',
        seatsFilled: 1,
        seatsTotal: 4,
        vehicleType: 'car',
        alreadyRequested: false,
        distanceKm: 1.0,
        matchPercent: 90,
      );
      when(() => repository.findMatchingRides(
            fromAddress: any(named: 'fromAddress'),
            toAddress: any(named: 'toAddress'),
            fromLat: any(named: 'fromLat'),
            fromLng: any(named: 'fromLng'),
            toLat: any(named: 'toLat'),
            toLng: any(named: 'toLng'),
            date: any(named: 'date'),
            time: any(named: 'time'),
            vehicleType: any(named: 'vehicleType'),
          )).thenAnswer((_) async => [match]);

      final result = await useCase(
        fromAddress: 'Home',
        toAddress: 'Office',
        date: date,
        time: time,
        vehicleType: 'car',
      );

      expect(result, [match]);
    });

    test('propagates exceptions thrown by the repository', () async {
      when(() => repository.findMatchingRides(
            fromAddress: any(named: 'fromAddress'),
            toAddress: any(named: 'toAddress'),
            fromLat: any(named: 'fromLat'),
            fromLng: any(named: 'fromLng'),
            toLat: any(named: 'toLat'),
            toLng: any(named: 'toLng'),
            date: any(named: 'date'),
            time: any(named: 'time'),
            vehicleType: any(named: 'vehicleType'),
          )).thenThrow(Exception('boom'));

      expect(
        () => useCase(
          fromAddress: 'Home',
          toAddress: 'Office',
          date: date,
          time: time,
          vehicleType: 'car',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
