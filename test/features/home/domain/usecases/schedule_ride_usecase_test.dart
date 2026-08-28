import 'package:acepool/features/home/domain/repositories/home_repository.dart';
import 'package:acepool/features/home/domain/usecases/schedule_ride_usecase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockHomeRepository extends Mock implements HomeRepository {}

void main() {
  late MockHomeRepository repository;
  late ScheduleRideUseCase useCase;

  setUpAll(() {
    registerFallbackValue(DateTime(2026, 1, 1));
    registerFallbackValue(const TimeOfDay(hour: 0, minute: 0));
  });

  setUp(() {
    repository = MockHomeRepository();
    useCase = ScheduleRideUseCase(repository);
  });

  group('ScheduleRideUseCase', () {
    test('forwards all args to repository.scheduleRide', () async {
      when(() => repository.scheduleRide(
            rideMode: any(named: 'rideMode'),
            vehicleType: any(named: 'vehicleType'),
            fromAddress: any(named: 'fromAddress'),
            toAddress: any(named: 'toAddress'),
            fromLat: any(named: 'fromLat'),
            fromLng: any(named: 'fromLng'),
            toLat: any(named: 'toLat'),
            toLng: any(named: 'toLng'),
            date: any(named: 'date'),
            time: any(named: 'time'),
            seatCount: any(named: 'seatCount'),
            routeDistanceKm: any(named: 'routeDistanceKm'),
            routeDurationMinutes: any(named: 'routeDurationMinutes'),
            fare: any(named: 'fare'),
          )).thenAnswer((_) async {});

      final date = DateTime(2026, 3, 1);
      const time = TimeOfDay(hour: 10, minute: 30);
      final fare = {'ratePerKm': 5.0};

      await useCase(
        rideMode: 'offer',
        vehicleType: 'car',
        fromAddress: 'A',
        toAddress: 'B',
        fromLat: 1.0,
        fromLng: 2.0,
        toLat: 3.0,
        toLng: 4.0,
        date: date,
        time: time,
        seatCount: 3,
        routeDistanceKm: 10.0,
        routeDurationMinutes: 15,
        fare: fare,
      );

      verify(() => repository.scheduleRide(
            rideMode: 'offer',
            vehicleType: 'car',
            fromAddress: 'A',
            toAddress: 'B',
            fromLat: 1.0,
            fromLng: 2.0,
            toLat: 3.0,
            toLng: 4.0,
            date: date,
            time: time,
            seatCount: 3,
            routeDistanceKm: 10.0,
            routeDurationMinutes: 15,
            fare: fare,
          )).called(1);
    });

    test('propagates exceptions thrown by the repository', () async {
      when(() => repository.scheduleRide(
            rideMode: any(named: 'rideMode'),
            vehicleType: any(named: 'vehicleType'),
            fromAddress: any(named: 'fromAddress'),
            toAddress: any(named: 'toAddress'),
            fromLat: any(named: 'fromLat'),
            fromLng: any(named: 'fromLng'),
            toLat: any(named: 'toLat'),
            toLng: any(named: 'toLng'),
            date: any(named: 'date'),
            time: any(named: 'time'),
            seatCount: any(named: 'seatCount'),
            routeDistanceKm: any(named: 'routeDistanceKm'),
            routeDurationMinutes: any(named: 'routeDurationMinutes'),
            fare: any(named: 'fare'),
          )).thenThrow(Exception('failed'));

      expect(
        () => useCase(
          rideMode: 'offer',
          vehicleType: 'car',
          fromAddress: 'A',
          toAddress: 'B',
          date: DateTime(2026, 3, 1),
          time: const TimeOfDay(hour: 10, minute: 30),
          seatCount: 3,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
