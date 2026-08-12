import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:acepool/features/rides/domain/entities/ride_match.dart';
import 'package:acepool/features/rides/domain/repositories/rides_repository.dart';
import 'package:acepool/features/rides/domain/usecases/find_matching_rides_usecase.dart';
import 'package:acepool/features/rides/presentation/bloc/find_ride_results_bloc.dart';

class MockRidesRepository extends Mock implements RidesRepository {}

void main() {
  late MockRidesRepository repository;
  late FindMatchingRidesUseCase useCase;

  final date = DateTime(2026, 1, 1);
  const time = TimeOfDay(hour: 10, minute: 0);

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

  setUpAll(() {
    registerFallbackValue(const TimeOfDay(hour: 0, minute: 0));
  });

  setUp(() {
    repository = MockRidesRepository();
    useCase = FindMatchingRidesUseCase(repository);
  });

  void stubRepository({List<RideMatch>? results, Object? error}) {
    if (error != null) {
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
          )).thenThrow(error);
    } else {
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
          )).thenAnswer((_) async => results ?? []);
    }
  }

  group('FindRideResultsEvent equality', () {
    test('FindRideResultsRequested supports value equality based on props', () {
      final event = FindRideResultsRequested(
        fromAddress: 'Home',
        toAddress: 'Office',
        fromLat: 1.1,
        fromLng: 2.2,
        toLat: 3.3,
        toLng: 4.4,
        date: date,
        time: time,
        vehicleType: 'car',
        currentLat: 5.5,
        currentLng: 6.6,
      );
      expect(
        event,
        FindRideResultsRequested(
          fromAddress: 'Home',
          toAddress: 'Office',
          fromLat: 1.1,
          fromLng: 2.2,
          toLat: 3.3,
          toLng: 4.4,
          date: date,
          time: time,
          vehicleType: 'car',
          currentLat: 5.5,
          currentLng: 6.6,
        ),
      );
      expect(event.props, [
        'Home',
        'Office',
        1.1,
        2.2,
        3.3,
        4.4,
        date,
        time,
        'car',
        5.5,
        6.6,
      ]);
      expect(
        event,
        isNot(FindRideResultsRequested(
          fromAddress: 'Other',
          toAddress: 'Office',
          date: date,
          time: time,
          vehicleType: 'car',
        )),
      );
    });

    test('FindRideResultsRefreshed supports value equality', () {
      expect(const FindRideResultsRefreshed(), const FindRideResultsRefreshed());
    });
  });

  group('FindRideResultsState equality', () {
    test(
      'supports value equality based on props (results list holds identical '
      'RideMatch instances)',
      () {
        expect(const FindRideResultsState(), const FindRideResultsState());
        expect(const FindRideResultsState().props, [
          FindRideResultsStatus.initial,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          const <RideMatch>[],
        ]);
        expect(
          FindRideResultsState(status: FindRideResultsStatus.loaded, results: [match]),
          FindRideResultsState(status: FindRideResultsStatus.loaded, results: [match]),
        );
        expect(
          FindRideResultsState(status: FindRideResultsStatus.loaded, results: [match]),
          isNot(const FindRideResultsState()),
        );
      },
    );
  });

  group('FindRideResultsBloc', () {
    test('initial state is FindRideResultsState()', () {
      expect(
        FindRideResultsBloc(findMatchingRides: useCase).state,
        const FindRideResultsState(),
      );
    });

    blocTest<FindRideResultsBloc, FindRideResultsState>(
      'FindRideResultsRequested stores search params, loads, then emits '
      'results',
      setUp: () => stubRepository(results: [match]),
      build: () => FindRideResultsBloc(findMatchingRides: useCase),
      act: (bloc) => bloc.add(FindRideResultsRequested(
        fromAddress: 'Home',
        toAddress: 'Office',
        fromLat: 1.1,
        fromLng: 2.2,
        toLat: 3.3,
        toLng: 4.4,
        date: date,
        time: time,
        vehicleType: 'car',
        currentLat: 5.5,
        currentLng: 6.6,
      )),
      expect: () => [
        FindRideResultsState(
          status: FindRideResultsStatus.loading,
          fromAddress: 'Home',
          toAddress: 'Office',
          fromLat: 1.1,
          fromLng: 2.2,
          toLat: 3.3,
          toLng: 4.4,
          date: date,
          time: time,
          vehicleType: 'car',
          currentLat: 5.5,
          currentLng: 6.6,
        ),
        FindRideResultsState(
          status: FindRideResultsStatus.loaded,
          fromAddress: 'Home',
          toAddress: 'Office',
          fromLat: 1.1,
          fromLng: 2.2,
          toLat: 3.3,
          toLng: 4.4,
          date: date,
          time: time,
          vehicleType: 'car',
          currentLat: 5.5,
          currentLng: 6.6,
          results: [match],
        ),
      ],
    );

    blocTest<FindRideResultsBloc, FindRideResultsState>(
      'FindRideResultsRequested renders an empty result list (not an error '
      'state) when the use case throws',
      setUp: () => stubRepository(error: Exception('network down')),
      build: () => FindRideResultsBloc(findMatchingRides: useCase),
      act: (bloc) => bloc.add(FindRideResultsRequested(
        fromAddress: 'Home',
        toAddress: 'Office',
        date: date,
        time: time,
        vehicleType: 'car',
      )),
      expect: () => [
        isA<FindRideResultsState>()
            .having((s) => s.status, 'status', FindRideResultsStatus.loading),
        isA<FindRideResultsState>()
            .having((s) => s.status, 'status', FindRideResultsStatus.loaded)
            .having((s) => s.results, 'results', isEmpty),
      ],
    );

    blocTest<FindRideResultsBloc, FindRideResultsState>(
      'FindRideResultsRefreshed re-fetches using previously stored search '
      'params',
      setUp: () => stubRepository(results: [match]),
      build: () => FindRideResultsBloc(findMatchingRides: useCase),
      seed: () => FindRideResultsState(
        fromAddress: 'Home',
        toAddress: 'Office',
        date: date,
        time: time,
        vehicleType: 'car',
      ),
      act: (bloc) => bloc.add(const FindRideResultsRefreshed()),
      expect: () => [
        isA<FindRideResultsState>()
            .having((s) => s.status, 'status', FindRideResultsStatus.loading),
        isA<FindRideResultsState>()
            .having((s) => s.status, 'status', FindRideResultsStatus.loaded)
            .having((s) => s.results, 'results', [match]),
      ],
      verify: (_) {
        verify(() => repository.findMatchingRides(
              fromAddress: 'Home',
              toAddress: 'Office',
              fromLat: null,
              fromLng: null,
              toLat: null,
              toLng: null,
              date: date,
              time: time,
              vehicleType: 'car',
            )).called(1);
      },
    );
  });
}
