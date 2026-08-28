import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:acepool/features/rides/domain/entities/ride_match.dart';
import 'package:acepool/features/rides/domain/entities/rider_journey.dart';
import 'package:acepool/features/rides/domain/repositories/rides_repository.dart';
import 'package:acepool/features/rides/presentation/bloc/track_route_bloc.dart';

class MockRidesRepository extends Mock implements RidesRepository {}

void main() {
  late MockRidesRepository repository;

  final ride = RideMatch(
    id: 'ride-1',
    driverId: 'driver-1',
    driverName: 'Driver',
    date: DateTime(2026, 1, 1),
    time: const TimeOfDay(hour: 10, minute: 0),
    fromAddress: 'Home',
    toAddress: 'Office',
    seatsFilled: 1,
    seatsTotal: 4,
    vehicleType: 'car',
    alreadyRequested: true,
    distanceKm: 1.0,
    matchPercent: 90,
  );

  const journey = RiderJourney(
    pickupPoint: 'Pickup',
    dropOffPoint: 'Dropoff',
    riderStartAddress: 'Start',
    riderEndAddress: 'End',
    driveDurationMinutes: 15,
  );

  setUp(() {
    repository = MockRidesRepository();
  });

  group('TrackRouteEvent equality', () {
    test(
      'supports value equality based on props (uses the same RideMatch '
      'instance since RideMatch is not Equatable)',
      () {
        final event = TrackRouteStarted(ride: ride, riderFromAddress: 'Rider Home');
        expect(event, TrackRouteStarted(ride: ride, riderFromAddress: 'Rider Home'));
        expect(event.props, [ride, 'Rider Home', null, null, null, null, null]);
        expect(
          event,
          isNot(TrackRouteStarted(ride: ride, riderFromAddress: 'Other')),
        );
      },
    );
  });

  group('TrackRouteState equality', () {
    test(
      'supports value equality based on props (uses the same RiderJourney '
      'instance since RiderJourney is not Equatable)',
      () {
        expect(const TrackRouteState(), const TrackRouteState());
        expect(const TrackRouteState().props, [TrackRouteStatus.initial, null, null]);
        expect(
          const TrackRouteState(status: TrackRouteStatus.loaded, journey: journey),
          const TrackRouteState(status: TrackRouteStatus.loaded, journey: journey),
        );
        expect(
          const TrackRouteState(status: TrackRouteStatus.loaded, journey: journey),
          isNot(const TrackRouteState()),
        );
      },
    );
  });

  group('TrackRouteBloc', () {
    test('initial state is TrackRouteState()', () {
      expect(TrackRouteBloc(ridesRepository: repository).state, const TrackRouteState());
    });

    blocTest<TrackRouteBloc, TrackRouteState>(
      'TrackRouteStarted forwards the ride and rider fields, then emits the '
      'resolved journey',
      setUp: () {
        when(() => repository.getRiderJourney(
              ride: ride,
              riderFromAddress: 'Rider Home',
              riderFromLat: 1.1,
              riderFromLng: 2.2,
              riderToAddress: 'Rider Office',
              riderToLat: 3.3,
              riderToLng: 4.4,
            )).thenAnswer((_) async => journey);
      },
      build: () => TrackRouteBloc(ridesRepository: repository),
      act: (bloc) => bloc.add(TrackRouteStarted(
        ride: ride,
        riderFromAddress: 'Rider Home',
        riderFromLat: 1.1,
        riderFromLng: 2.2,
        riderToAddress: 'Rider Office',
        riderToLat: 3.3,
        riderToLng: 4.4,
      )),
      expect: () => [
        const TrackRouteState(status: TrackRouteStatus.loading),
        const TrackRouteState(status: TrackRouteStatus.loaded, journey: journey),
      ],
      verify: (_) {
        verify(() => repository.getRiderJourney(
              ride: ride,
              riderFromAddress: 'Rider Home',
              riderFromLat: 1.1,
              riderFromLng: 2.2,
              riderToAddress: 'Rider Office',
              riderToLat: 3.3,
              riderToLng: 4.4,
            )).called(1);
      },
    );

    blocTest<TrackRouteBloc, TrackRouteState>(
      'TrackRouteStarted with no rider fields forwards nulls',
      setUp: () {
        when(() => repository.getRiderJourney(
              ride: ride,
              riderFromAddress: null,
              riderFromLat: null,
              riderFromLng: null,
              riderToAddress: null,
              riderToLat: null,
              riderToLng: null,
            )).thenAnswer((_) async => journey);
      },
      build: () => TrackRouteBloc(ridesRepository: repository),
      act: (bloc) => bloc.add(TrackRouteStarted(ride: ride)),
      expect: () => [
        const TrackRouteState(status: TrackRouteStatus.loading),
        const TrackRouteState(status: TrackRouteStatus.loaded, journey: journey),
      ],
    );

    blocTest<TrackRouteBloc, TrackRouteState>(
      'TrackRouteStarted emits an error state with the exception message '
      'when the repository throws',
      setUp: () {
        when(() => repository.getRiderJourney(
              ride: ride,
              riderFromAddress: null,
              riderFromLat: null,
              riderFromLng: null,
              riderToAddress: null,
              riderToLat: null,
              riderToLng: null,
            )).thenThrow(Exception('journey lookup failed'));
      },
      build: () => TrackRouteBloc(ridesRepository: repository),
      act: (bloc) => bloc.add(TrackRouteStarted(ride: ride)),
      expect: () => [
        const TrackRouteState(status: TrackRouteStatus.loading),
        isA<TrackRouteState>()
            .having((s) => s.status, 'status', TrackRouteStatus.error)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              contains('journey lookup failed'),
            ),
      ],
    );
  });
}
