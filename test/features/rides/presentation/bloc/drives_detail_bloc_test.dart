import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:acepool/features/home/domain/entities/upcoming_trip.dart';
import 'package:acepool/features/rides/domain/entities/ride_rider.dart';
import 'package:acepool/features/rides/domain/repositories/rides_repository.dart';
import 'package:acepool/features/rides/presentation/bloc/drives_detail_bloc.dart';

class MockRidesRepository extends Mock implements RidesRepository {}

void main() {
  late MockRidesRepository repository;

  final trip = UpcomingTrip(
    id: 'trip-1',
    date: DateTime(2026, 1, 1),
    time: const TimeOfDay(hour: 10, minute: 0),
    fromAddress: 'Home',
    toAddress: 'Office',
    seatsFilled: 1,
    seatsTotal: 4,
  );

  const rider = RideRider(
    requestId: 'req-1',
    riderId: 'rider-1',
    riderName: 'Alice',
    employeeId: 'EMP1',
    pickupPoint: 'Main St',
    pickupTime: TimeOfDay(hour: 9, minute: 0),
  );

  setUp(() {
    repository = MockRidesRepository();
  });

  group('DrivesDetailEvent equality', () {
    test(
      'DrivesDetailStarted supports value equality based on props (trip is '
      'Equatable)',
      () {
        final tripCopy = UpcomingTrip(
          id: 'trip-1',
          date: DateTime(2026, 1, 1),
          time: const TimeOfDay(hour: 10, minute: 0),
          fromAddress: 'Home',
          toAddress: 'Office',
          seatsFilled: 1,
          seatsTotal: 4,
        );
        expect(DrivesDetailStarted(trip), DrivesDetailStarted(tripCopy));
        expect(DrivesDetailStarted(trip).props, [trip]);
        expect(
          DrivesDetailStarted(trip),
          isNot(DrivesDetailStarted(UpcomingTrip(
            id: 'other-trip',
            date: DateTime(2026, 1, 1),
            time: const TimeOfDay(hour: 10, minute: 0),
            fromAddress: 'Home',
            toAddress: 'Office',
            seatsFilled: 1,
            seatsTotal: 4,
          ))),
        );
      },
    );

    test('DrivesDetailReloadRequested supports value equality', () {
      expect(const DrivesDetailReloadRequested(), const DrivesDetailReloadRequested());
    });

    test(
      'DrivesDetailStatusChangeRequested supports value equality based on '
      'props',
      () {
        expect(
          const DrivesDetailStatusChangeRequested('completed'),
          const DrivesDetailStatusChangeRequested('completed'),
        );
        expect(
          const DrivesDetailStatusChangeRequested('completed').props,
          ['completed'],
        );
        expect(
          const DrivesDetailStatusChangeRequested('completed'),
          isNot(const DrivesDetailStatusChangeRequested('cancelled')),
        );
      },
    );
  });

  group('DrivesDetailBloc', () {
    test('initial state is DrivesDetailState()', () {
      expect(
        DrivesDetailBloc(ridesRepository: repository).state,
        const DrivesDetailState(),
      );
    });

    blocTest<DrivesDetailBloc, DrivesDetailState>(
      'DrivesDetailStarted loads riders and emits loading then loaded',
      setUp: () {
        when(() => repository.getRidersForCurrentDriver(rideId: 'trip-1'))
            .thenAnswer((_) async => [rider]);
      },
      build: () => DrivesDetailBloc(ridesRepository: repository),
      act: (bloc) => bloc.add(DrivesDetailStarted(trip)),
      expect: () => [
        DrivesDetailState(
          currentTrip: trip,
          ridersStatus: DrivesDetailRidersStatus.loading,
        ),
        DrivesDetailState(
          currentTrip: trip,
          ridersStatus: DrivesDetailRidersStatus.loaded,
          riders: const [rider],
        ),
      ],
      verify: (_) {
        verify(() => repository.getRidersForCurrentDriver(rideId: 'trip-1')).called(1);
      },
    );

    blocTest<DrivesDetailBloc, DrivesDetailState>(
      'DrivesDetailStarted emits error status when repository throws',
      setUp: () {
        when(() => repository.getRidersForCurrentDriver(rideId: 'trip-1'))
            .thenThrow(Exception('load failed'));
      },
      build: () => DrivesDetailBloc(ridesRepository: repository),
      act: (bloc) => bloc.add(DrivesDetailStarted(trip)),
      expect: () => [
        DrivesDetailState(
          currentTrip: trip,
          ridersStatus: DrivesDetailRidersStatus.loading,
        ),
        isA<DrivesDetailState>()
            .having((s) => s.ridersStatus, 'ridersStatus', DrivesDetailRidersStatus.error)
            .having((s) => s.ridersError, 'ridersError', isA<Exception>()),
      ],
    );

    blocTest<DrivesDetailBloc, DrivesDetailState>(
      'DrivesDetailReloadRequested reloads riders for the current trip',
      setUp: () {
        when(() => repository.getRidersForCurrentDriver(rideId: 'trip-1'))
            .thenAnswer((_) async => [rider]);
      },
      build: () => DrivesDetailBloc(ridesRepository: repository),
      seed: () => DrivesDetailState(
        currentTrip: trip,
        ridersStatus: DrivesDetailRidersStatus.loaded,
      ),
      act: (bloc) => bloc.add(const DrivesDetailReloadRequested()),
      expect: () => [
        DrivesDetailState(
          currentTrip: trip,
          ridersStatus: DrivesDetailRidersStatus.loading,
        ),
        DrivesDetailState(
          currentTrip: trip,
          ridersStatus: DrivesDetailRidersStatus.loaded,
          riders: const [rider],
        ),
      ],
    );

    blocTest<DrivesDetailBloc, DrivesDetailState>(
      'DrivesDetailStatusChangeRequested updates status and bumps tick on '
      'success',
      setUp: () {
        when(() => repository.updateRideStatus('trip-1', 'completed'))
            .thenAnswer((_) async {});
      },
      build: () => DrivesDetailBloc(ridesRepository: repository),
      seed: () => DrivesDetailState(currentTrip: trip),
      act: (bloc) => bloc.add(const DrivesDetailStatusChangeRequested('completed')),
      expect: () => [
        isA<DrivesDetailState>()
            .having((s) => s.currentTrip?.status, 'status', 'completed')
            .having((s) => s.statusUpdateTick, 'tick', 1)
            .having((s) => s.lastUpdatedStatus, 'lastUpdatedStatus', 'completed'),
      ],
      verify: (_) {
        verify(() => repository.updateRideStatus('trip-1', 'completed')).called(1);
      },
    );

    blocTest<DrivesDetailBloc, DrivesDetailState>(
      'DrivesDetailStatusChangeRequested emits a snackbar message on failure',
      setUp: () {
        when(() => repository.updateRideStatus('trip-1', 'cancelled'))
            .thenThrow(Exception('nope'));
      },
      build: () => DrivesDetailBloc(ridesRepository: repository),
      seed: () => DrivesDetailState(currentTrip: trip),
      act: (bloc) => bloc.add(const DrivesDetailStatusChangeRequested('cancelled')),
      expect: () => [
        isA<DrivesDetailState>().having(
          (s) => s.snackbarMessage,
          'snackbarMessage',
          contains('Failed to update trip'),
        ),
      ],
    );
  });
}
