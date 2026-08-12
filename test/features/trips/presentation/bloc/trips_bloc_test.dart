import 'package:acepool/features/home/domain/entities/upcoming_trip.dart';
import 'package:acepool/features/trips/domain/entities/available_ride.dart';
import 'package:acepool/features/trips/domain/entities/requested_ride.dart';
import 'package:acepool/features/trips/domain/repositories/trips_repository.dart';
import 'package:acepool/features/trips/presentation/bloc/trips_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTripsRepository extends Mock implements TripsRepository {}

void main() {
  late MockTripsRepository repository;

  final drive = UpcomingTrip(
    id: 'trip1',
    date: DateTime(2024, 1, 5),
    time: const TimeOfDay(hour: 9, minute: 0),
    fromAddress: 'Home',
    toAddress: 'Office',
    seatsFilled: 1,
    seatsTotal: 4,
  );

  final availableRide = AvailableRide(
    id: 'ride1',
    driverId: 'driver1',
    driverName: 'Driver One',
    date: DateTime(2024, 1, 5),
    time: const TimeOfDay(hour: 9, minute: 0),
    fromAddress: 'Ride Home',
    toAddress: 'Ride Office',
    seatsFilled: 1,
    seatsTotal: 4,
    vehicleType: 'car',
    alreadyRequested: false,
    matchPercent: 90,
    defaultPickupPoint: 'Ride Home',
    distanceKm: 1.2,
  );

  final requestedRide = RequestedRide(
    id: 'req1',
    rideId: 'ride1',
    driverId: 'driver1',
    driverName: 'Driver One',
    driverPhotoUrl: '',
    date: DateTime(2024, 1, 5),
    time: const TimeOfDay(hour: 9, minute: 0),
    fromAddress: 'Ride Home',
    toAddress: 'Ride Office',
    riderStartAddress: 'Rider Home',
    riderEndAddress: 'Rider Office',
    seatsFilled: 1,
    seatsTotal: 4,
    status: 'accepted',
    vehicleType: 'car',
    matchPercent: 90,
  );

  setUp(() {
    repository = MockTripsRepository();
  });

  group('TripsEvent equality', () {
    test('TripsDrivesRequested supports value equality', () {
      expect(const TripsDrivesRequested(), const TripsDrivesRequested());
    });

    test('TripsAvailableRidesRequested supports value equality based on props', () {
      const event = TripsAvailableRidesRequested(
        fromAddress: 'Home',
        toAddress: 'Office',
        fromLat: 1.0,
        fromLng: 2.0,
        toLat: 3.0,
        toLng: 4.0,
      );
      expect(
        event,
        const TripsAvailableRidesRequested(
          fromAddress: 'Home',
          toAddress: 'Office',
          fromLat: 1.0,
          fromLng: 2.0,
          toLat: 3.0,
          toLng: 4.0,
        ),
      );
      expect(event.props, ['Home', 'Office', 1.0, 2.0, 3.0, 4.0]);
      expect(
        event,
        isNot(const TripsAvailableRidesRequested(fromAddress: 'Other')),
      );
    });

    test('TripsRequestedRidesRequested supports value equality based on props', () {
      const event = TripsRequestedRidesRequested(
        homeFromAddress: 'Home',
        homeToAddress: 'Office',
        homeFromLat: 1.0,
        homeFromLng: 2.0,
        homeToLat: 3.0,
        homeToLng: 4.0,
      );
      expect(
        event,
        const TripsRequestedRidesRequested(
          homeFromAddress: 'Home',
          homeToAddress: 'Office',
          homeFromLat: 1.0,
          homeFromLng: 2.0,
          homeToLat: 3.0,
          homeToLng: 4.0,
        ),
      );
      expect(event.props, ['Home', 'Office', 1.0, 2.0, 3.0, 4.0]);
      expect(
        event,
        isNot(const TripsRequestedRidesRequested(homeFromAddress: 'Other')),
      );
    });
  });

  group('TripsBloc', () {
    test('initial state has initial statuses and empty lists', () {
      final bloc = TripsBloc(tripsRepository: repository);
      expect(bloc.state, const TripsState());
      expect(bloc.state.drivesStatus, TripsSectionStatus.initial);
      expect(bloc.state.availableRidesStatus, TripsSectionStatus.initial);
      expect(bloc.state.requestedRidesStatus, TripsSectionStatus.initial);
      expect(bloc.state.drives, isEmpty);
      expect(bloc.state.availableRides, isEmpty);
      expect(bloc.state.requestedRides, isEmpty);
      expect(bloc.state.hasCommuteLocation, isFalse);
    });

    blocTest<TripsBloc, TripsState>(
      'TripsDrivesRequested emits loading then loaded with drives from '
      'getTrips("offer")',
      setUp: () {
        when(() => repository.getTrips('offer'))
            .thenAnswer((_) async => [drive]);
      },
      build: () => TripsBloc(tripsRepository: repository),
      act: (bloc) => bloc.add(const TripsDrivesRequested()),
      expect: () => [
        const TripsState(drivesStatus: TripsSectionStatus.loading),
        TripsState(
          drivesStatus: TripsSectionStatus.loaded,
          drives: [drive],
        ),
      ],
      verify: (_) {
        verify(() => repository.getTrips('offer')).called(1);
      },
    );

    blocTest<TripsBloc, TripsState>(
      'TripsAvailableRidesRequested emits loading then loaded with rides and '
      'hasCommuteLocation true when both addresses are non-blank',
      setUp: () {
        when(() => repository.getAvailableRides(
              fromAddress: any(named: 'fromAddress'),
              toAddress: any(named: 'toAddress'),
              fromLat: any(named: 'fromLat'),
              fromLng: any(named: 'fromLng'),
              toLat: any(named: 'toLat'),
              toLng: any(named: 'toLng'),
            )).thenAnswer((_) async => [availableRide]);
      },
      build: () => TripsBloc(tripsRepository: repository),
      act: (bloc) => bloc.add(const TripsAvailableRidesRequested(
        fromAddress: 'Home',
        toAddress: 'Office',
        fromLat: 1.0,
        fromLng: 2.0,
        toLat: 3.0,
        toLng: 4.0,
      )),
      expect: () => [
        const TripsState(availableRidesStatus: TripsSectionStatus.loading),
        TripsState(
          availableRidesStatus: TripsSectionStatus.loaded,
          availableRides: [availableRide],
          hasCommuteLocation: true,
        ),
      ],
      verify: (_) {
        verify(() => repository.getAvailableRides(
              fromAddress: 'Home',
              toAddress: 'Office',
              fromLat: 1.0,
              fromLng: 2.0,
              toLat: 3.0,
              toLng: 4.0,
            )).called(1);
      },
    );

    blocTest<TripsBloc, TripsState>(
      'TripsAvailableRidesRequested emits hasCommuteLocation false when '
      'fromAddress is blank',
      setUp: () {
        when(() => repository.getAvailableRides(
              fromAddress: any(named: 'fromAddress'),
              toAddress: any(named: 'toAddress'),
              fromLat: any(named: 'fromLat'),
              fromLng: any(named: 'fromLng'),
              toLat: any(named: 'toLat'),
              toLng: any(named: 'toLng'),
            )).thenAnswer((_) async => []);
      },
      build: () => TripsBloc(tripsRepository: repository),
      act: (bloc) => bloc.add(const TripsAvailableRidesRequested(
        fromAddress: '   ',
        toAddress: 'Office',
      )),
      expect: () => [
        const TripsState(availableRidesStatus: TripsSectionStatus.loading),
        const TripsState(
          availableRidesStatus: TripsSectionStatus.loaded,
          availableRides: [],
          hasCommuteLocation: false,
        ),
      ],
    );

    blocTest<TripsBloc, TripsState>(
      'TripsAvailableRidesRequested emits hasCommuteLocation false when '
      'toAddress is null',
      setUp: () {
        when(() => repository.getAvailableRides(
              fromAddress: any(named: 'fromAddress'),
              toAddress: any(named: 'toAddress'),
              fromLat: any(named: 'fromLat'),
              fromLng: any(named: 'fromLng'),
              toLat: any(named: 'toLat'),
              toLng: any(named: 'toLng'),
            )).thenAnswer((_) async => []);
      },
      build: () => TripsBloc(tripsRepository: repository),
      act: (bloc) => bloc.add(const TripsAvailableRidesRequested(
        fromAddress: 'Home',
      )),
      expect: () => [
        const TripsState(availableRidesStatus: TripsSectionStatus.loading),
        const TripsState(
          availableRidesStatus: TripsSectionStatus.loaded,
          availableRides: [],
          hasCommuteLocation: false,
        ),
      ],
    );

    blocTest<TripsBloc, TripsState>(
      'TripsRequestedRidesRequested emits loading then loaded with requests '
      'from getRideRequests',
      setUp: () {
        when(() => repository.getRideRequests(
              homeFromAddress: any(named: 'homeFromAddress'),
              homeToAddress: any(named: 'homeToAddress'),
              homeFromLat: any(named: 'homeFromLat'),
              homeFromLng: any(named: 'homeFromLng'),
              homeToLat: any(named: 'homeToLat'),
              homeToLng: any(named: 'homeToLng'),
            )).thenAnswer((_) async => [requestedRide]);
      },
      build: () => TripsBloc(tripsRepository: repository),
      act: (bloc) => bloc.add(const TripsRequestedRidesRequested(
        homeFromAddress: 'Home',
        homeToAddress: 'Office',
      )),
      expect: () => [
        const TripsState(requestedRidesStatus: TripsSectionStatus.loading),
        TripsState(
          requestedRidesStatus: TripsSectionStatus.loaded,
          requestedRides: [requestedRide],
        ),
      ],
      verify: (_) {
        verify(() => repository.getRideRequests(
              homeFromAddress: 'Home',
              homeToAddress: 'Office',
              homeFromLat: null,
              homeFromLng: null,
              homeToLat: null,
              homeToLng: null,
            )).called(1);
      },
    );

    blocTest<TripsBloc, TripsState>(
      'events for independent sections do not clobber each other\'s state',
      setUp: () {
        when(() => repository.getTrips('offer'))
            .thenAnswer((_) async => [drive]);
        when(() => repository.getRideRequests(
              homeFromAddress: any(named: 'homeFromAddress'),
              homeToAddress: any(named: 'homeToAddress'),
              homeFromLat: any(named: 'homeFromLat'),
              homeFromLng: any(named: 'homeFromLng'),
              homeToLat: any(named: 'homeToLat'),
              homeToLng: any(named: 'homeToLng'),
            )).thenAnswer((_) async => [requestedRide]);
      },
      build: () => TripsBloc(tripsRepository: repository),
      act: (bloc) async {
        bloc.add(const TripsDrivesRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const TripsRequestedRidesRequested());
      },
      expect: () => [
        const TripsState(drivesStatus: TripsSectionStatus.loading),
        TripsState(
          drivesStatus: TripsSectionStatus.loaded,
          drives: [drive],
        ),
        TripsState(
          drivesStatus: TripsSectionStatus.loaded,
          drives: [drive],
          requestedRidesStatus: TripsSectionStatus.loading,
        ),
        TripsState(
          drivesStatus: TripsSectionStatus.loaded,
          drives: [drive],
          requestedRidesStatus: TripsSectionStatus.loaded,
          requestedRides: [requestedRide],
        ),
      ],
    );
  });
}
