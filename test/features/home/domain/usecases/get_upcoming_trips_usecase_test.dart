import 'package:acepool/features/home/domain/entities/upcoming_trip.dart';
import 'package:acepool/features/home/domain/repositories/home_repository.dart';
import 'package:acepool/features/home/domain/usecases/get_upcoming_trips_usecase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockHomeRepository extends Mock implements HomeRepository {}

void main() {
  late MockHomeRepository repository;
  late GetUpcomingTripsUseCase useCase;

  setUp(() {
    repository = MockHomeRepository();
    useCase = GetUpcomingTripsUseCase(repository);
  });

  group('GetUpcomingTripsUseCase', () {
    test('returns the repository result', () async {
      final trips = [
        UpcomingTrip(
          id: 't1',
          date: DateTime(2026, 1, 1),
          time: const TimeOfDay(hour: 9, minute: 0),
          fromAddress: 'A',
          toAddress: 'B',
          seatsFilled: 0,
          seatsTotal: 4,
        ),
      ];
      when(() => repository.getUpcomingTrips()).thenAnswer((_) async => trips);

      final result = await useCase();

      expect(result, trips);
      verify(() => repository.getUpcomingTrips()).called(1);
    });

    test('returns empty list when repository returns empty', () async {
      when(() => repository.getUpcomingTrips()).thenAnswer((_) async => []);

      final result = await useCase();

      expect(result, isEmpty);
    });

    test('propagates exceptions thrown by the repository', () async {
      when(() => repository.getUpcomingTrips()).thenThrow(Exception('failed'));

      expect(() => useCase(), throwsA(isA<Exception>()));
    });
  });
}
