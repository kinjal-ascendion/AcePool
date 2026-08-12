import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:acepool/features/rides/domain/entities/ride_match.dart';
import 'package:acepool/features/rides/domain/entities/ride_rider.dart';
import 'package:acepool/features/rides/domain/repositories/rides_repository.dart';
import 'package:acepool/features/rides/presentation/bloc/ride_details_bloc.dart';

class MockRidesRepository extends Mock implements RidesRepository {}

class _FakeRideMatch extends Fake implements RideMatch {}

void main() {
  late MockRidesRepository repository;

  setUpAll(() {
    registerFallbackValue(_FakeRideMatch());
  });

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
    alreadyRequested: false,
    distanceKm: 1.0,
    matchPercent: 90,
  );

  final requestedRide = RideMatch(
    id: 'ride-2',
    driverId: 'driver-2',
    driverName: 'Driver 2',
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

  final alreadyRequestedRide = RideMatch(
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

  const otherRider = RideRider(
    requestId: 'req-1',
    riderId: 'rider-x',
    riderName: 'X',
    employeeId: 'EMP1',
    pickupPoint: 'Somewhere',
    pickupTime: TimeOfDay(hour: 9, minute: 0),
  );

  setUp(() {
    repository = MockRidesRepository();
  });

  group('RideDetailsEvent equality', () {
    test(
      'RideDetailsStarted supports value equality based on props (uses the '
      'same RideMatch instance since RideMatch is not Equatable)',
      () {
        final event = RideDetailsStarted(ride: ride, riderFromAddress: 'Rider Home');
        expect(event, RideDetailsStarted(ride: ride, riderFromAddress: 'Rider Home'));
        expect(event.props, [ride, 'Rider Home', null, null, null, null, null]);
        expect(
          event,
          isNot(RideDetailsStarted(ride: ride, riderFromAddress: 'Other')),
        );
      },
    );

    test('RideDetailsSubmitted supports value equality based on props', () {
      expect(const RideDetailsSubmitted('hello'), const RideDetailsSubmitted('hello'));
      expect(const RideDetailsSubmitted('hello').props, ['hello']);
      expect(
        const RideDetailsSubmitted('hello'),
        isNot(const RideDetailsSubmitted('bye')),
      );
    });
  });

  group('RideDetailsBloc', () {
    test('initial state is RideDetailsState()', () {
      expect(
        RideDetailsBloc(ridesRepository: repository).state,
        const RideDetailsState(),
      );
    });

    blocTest<RideDetailsBloc, RideDetailsState>(
      'RideDetailsStarted loads other riders and sets justRequested from '
      'ride.alreadyRequested (false)',
      setUp: () {
        when(() => repository.getOtherRiders('ride-1'))
            .thenAnswer((_) async => [otherRider]);
      },
      build: () => RideDetailsBloc(ridesRepository: repository),
      act: (bloc) => bloc.add(RideDetailsStarted(ride: ride)),
      expect: () => [
        const RideDetailsState(
          ridersStatus: RideDetailsRidersStatus.loading,
          justRequested: false,
        ),
        const RideDetailsState(
          ridersStatus: RideDetailsRidersStatus.loaded,
          riders: [otherRider],
          justRequested: false,
        ),
      ],
    );

    blocTest<RideDetailsBloc, RideDetailsState>(
      'RideDetailsStarted sets justRequested true when ride.alreadyRequested '
      'is true',
      setUp: () {
        when(() => repository.getOtherRiders('ride-2'))
            .thenAnswer((_) async => []);
      },
      build: () => RideDetailsBloc(ridesRepository: repository),
      act: (bloc) => bloc.add(RideDetailsStarted(ride: requestedRide)),
      expect: () => [
        const RideDetailsState(
          ridersStatus: RideDetailsRidersStatus.loading,
          justRequested: true,
        ),
        const RideDetailsState(
          ridersStatus: RideDetailsRidersStatus.loaded,
          justRequested: true,
        ),
      ],
    );

    blocTest<RideDetailsBloc, RideDetailsState>(
      'RideDetailsStarted emits error status when getOtherRiders throws',
      setUp: () {
        when(() => repository.getOtherRiders('ride-1'))
            .thenThrow(Exception('boom'));
      },
      build: () => RideDetailsBloc(ridesRepository: repository),
      act: (bloc) => bloc.add(RideDetailsStarted(ride: ride)),
      expect: () => [
        const RideDetailsState(
          ridersStatus: RideDetailsRidersStatus.loading,
          justRequested: false,
        ),
        isA<RideDetailsState>()
            .having((s) => s.ridersStatus, 'ridersStatus', RideDetailsRidersStatus.error)
            .having((s) => s.ridersError, 'ridersError', isA<Exception>()),
      ],
    );

    blocTest<RideDetailsBloc, RideDetailsState>(
      'RideDetailsSubmitted (not yet requested) requests the ride, sends no '
      'chat message when text is empty, and reloads riders',
      setUp: () {
        when(() => repository.getOtherRiders('ride-1')).thenAnswer((_) async => []);
        when(() => repository.requestRideFromDetails(
              ride: ride,
              riderFromAddress: null,
              riderFromLat: null,
              riderFromLng: null,
              riderToAddress: null,
              riderToLat: null,
              riderToLng: null,
              message: '',
            )).thenAnswer((_) async => 'Rider Name');
      },
      build: () => RideDetailsBloc(ridesRepository: repository),
      act: (bloc) async {
        bloc.add(RideDetailsStarted(ride: ride));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const RideDetailsSubmitted(''));
      },
      skip: 2,
      expect: () => [
        isA<RideDetailsState>()
            .having((s) => s.submitting, 'submitting', true)
            .having((s) => s.snackbarMessage, 'snackbarMessage', isNull),
        isA<RideDetailsState>()
            .having((s) => s.submitting, 'submitting', false)
            .having((s) => s.justRequested, 'justRequested', true),
      ],
      verify: (_) {
        verifyNever(() => repository.sendRideChatMessage(
              driverId: any(named: 'driverId'),
              driverName: any(named: 'driverName'),
              text: any(named: 'text'),
            ));
      },
    );

    blocTest<RideDetailsBloc, RideDetailsState>(
      'RideDetailsSubmitted (not yet requested) with a message also sends a '
      'chat message after requesting',
      setUp: () {
        when(() => repository.getOtherRiders('ride-1')).thenAnswer((_) async => []);
        when(() => repository.requestRideFromDetails(
              ride: ride,
              riderFromAddress: null,
              riderFromLat: null,
              riderFromLng: null,
              riderToAddress: null,
              riderToLat: null,
              riderToLng: null,
              message: 'Hello driver',
            )).thenAnswer((_) async => 'Rider Name');
        when(() => repository.sendRideChatMessage(
              driverId: 'driver-1',
              driverName: 'Driver',
              text: 'Hello driver',
            )).thenAnswer((_) async {});
      },
      build: () => RideDetailsBloc(ridesRepository: repository),
      act: (bloc) async {
        bloc.add(RideDetailsStarted(ride: ride));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const RideDetailsSubmitted('Hello driver'));
      },
      skip: 2,
      expect: () => [
        isA<RideDetailsState>().having((s) => s.submitting, 'submitting', true),
        isA<RideDetailsState>()
            .having((s) => s.submitting, 'submitting', false)
            .having((s) => s.justRequested, 'justRequested', true),
      ],
      verify: (_) {
        verify(() => repository.sendRideChatMessage(
              driverId: 'driver-1',
              driverName: 'Driver',
              text: 'Hello driver',
            )).called(1);
      },
    );

    blocTest<RideDetailsBloc, RideDetailsState>(
      'RideDetailsSubmitted (not yet requested) emits a failure snackbar '
      'when the repository throws',
      setUp: () {
        when(() => repository.getOtherRiders('ride-1')).thenAnswer((_) async => []);
        when(() => repository.requestRideFromDetails(
              ride: ride,
              riderFromAddress: null,
              riderFromLat: null,
              riderFromLng: null,
              riderToAddress: null,
              riderToLat: null,
              riderToLng: null,
              message: '',
            )).thenThrow(Exception('failed'));
      },
      build: () => RideDetailsBloc(ridesRepository: repository),
      act: (bloc) async {
        bloc.add(RideDetailsStarted(ride: ride));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const RideDetailsSubmitted(''));
      },
      skip: 2,
      expect: () => [
        isA<RideDetailsState>().having((s) => s.submitting, 'submitting', true),
        isA<RideDetailsState>()
            .having((s) => s.submitting, 'submitting', false)
            .having(
              (s) => s.snackbarMessage,
              'snackbarMessage',
              contains('Could not request ride'),
            ),
      ],
    );

    blocTest<RideDetailsBloc, RideDetailsState>(
      'RideDetailsSubmitted with empty message and justRequested true is a '
      'no-op (does not send a message, does not call the repository)',
      build: () => RideDetailsBloc(ridesRepository: repository),
      seed: () => const RideDetailsState(justRequested: true),
      act: (bloc) => bloc.add(const RideDetailsSubmitted('')),
      expect: () => [],
      verify: (_) {
        verifyNever(() => repository.sendRideChatMessage(
              driverId: any(named: 'driverId'),
              driverName: any(named: 'driverName'),
              text: any(named: 'text'),
            ));
      },
    );

    blocTest<RideDetailsBloc, RideDetailsState>(
      'RideDetailsSubmitted while already submitting is a no-op',
      build: () => RideDetailsBloc(ridesRepository: repository),
      seed: () => const RideDetailsState(submitting: true),
      act: (bloc) => bloc.add(const RideDetailsSubmitted('hello')),
      expect: () => [],
    );

    blocTest<RideDetailsBloc, RideDetailsState>(
      'RideDetailsSubmitted (justRequested true) with text sends a chat '
      'message and clears the message field',
      setUp: () {
        when(() => repository.getOtherRiders('ride-1')).thenAnswer((_) async => []);
        when(() => repository.sendRideChatMessage(
              driverId: 'driver-1',
              driverName: 'Driver',
              text: 'Thanks!',
            )).thenAnswer((_) async {});
      },
      build: () => RideDetailsBloc(ridesRepository: repository),
      act: (bloc) async {
        bloc.add(RideDetailsStarted(ride: alreadyRequestedRide));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const RideDetailsSubmitted('Thanks!'));
      },
      skip: 2,
      expect: () => [
        isA<RideDetailsState>().having((s) => s.submitting, 'submitting', true),
        isA<RideDetailsState>()
            .having((s) => s.submitting, 'submitting', false)
            .having((s) => s.snackbarMessage, 'snackbarMessage', 'Message sent to driver')
            .having((s) => s.clearMessageTextTick, 'clearMessageTextTick', 1),
      ],
      verify: (_) {
        verify(() => repository.sendRideChatMessage(
              driverId: 'driver-1',
              driverName: 'Driver',
              text: 'Thanks!',
            )).called(1);
        verifyNever(() => repository.requestRideFromDetails(
              ride: any(named: 'ride'),
              message: any(named: 'message'),
            ));
      },
    );

    blocTest<RideDetailsBloc, RideDetailsState>(
      'RideDetailsSubmitted (justRequested true) emits failure snackbar when '
      'sendRideChatMessage throws',
      setUp: () {
        when(() => repository.getOtherRiders('ride-2')).thenAnswer((_) async => []);
        when(() => repository.sendRideChatMessage(
              driverId: 'driver-2',
              driverName: 'Driver 2',
              text: 'Hi',
            )).thenThrow(Exception('chat down'));
      },
      build: () => RideDetailsBloc(ridesRepository: repository),
      act: (bloc) async {
        bloc.add(RideDetailsStarted(ride: requestedRide));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const RideDetailsSubmitted('Hi'));
      },
      skip: 2,
      expect: () => [
        isA<RideDetailsState>().having((s) => s.submitting, 'submitting', true),
        isA<RideDetailsState>()
            .having((s) => s.submitting, 'submitting', false)
            .having(
              (s) => s.snackbarMessage,
              'snackbarMessage',
              contains('Failed to send message'),
            ),
      ],
    );
  });
}
