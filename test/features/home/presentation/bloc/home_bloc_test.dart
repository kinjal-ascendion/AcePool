import 'package:acepool/core/services/location_service.dart';
import 'package:acepool/features/home/domain/entities/upcoming_trip.dart';
import 'package:acepool/features/home/domain/usecases/get_travel_preference_usecase.dart';
import 'package:acepool/features/home/domain/usecases/get_upcoming_trips_usecase.dart';
import 'package:acepool/features/home/presentation/bloc/home_bloc.dart';
import 'package:acepool/features/rides/domain/entities/ride_match.dart';
import 'package:acepool/features/rides/domain/usecases/find_matching_rides_usecase.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';

class MockGetUpcomingTripsUseCase extends Mock implements GetUpcomingTripsUseCase {}

class MockGetTravelPreferenceUseCase extends Mock implements GetTravelPreferenceUseCase {}

class MockFindMatchingRidesUseCase extends Mock implements FindMatchingRidesUseCase {}

class MockLocationService extends Mock implements LocationService {}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026, 1, 1));
    registerFallbackValue(const TimeOfDay(hour: 0, minute: 0));
  });

  late MockGetUpcomingTripsUseCase getUpcomingTrips;
  late MockGetTravelPreferenceUseCase getTravelPreference;
  late MockFindMatchingRidesUseCase findMatchingRides;
  late MockLocationService locationService;

  final trip = UpcomingTrip(
    id: 't1',
    date: DateTime(2026, 1, 1),
    time: const TimeOfDay(hour: 9, minute: 0),
    fromAddress: 'A',
    toAddress: 'B',
    seatsFilled: 0,
    seatsTotal: 4,
  );

  final rideMatch = RideMatch(
    id: 'r1',
    driverId: 'd1',
    driverName: 'Driver',
    date: DateTime(2026, 5, 1),
    time: const TimeOfDay(hour: 9, minute: 0),
    fromAddress: 'A',
    toAddress: 'B',
    seatsFilled: 0,
    seatsTotal: 4,
    vehicleType: 'car',
    alreadyRequested: false,
    distanceKm: null,
    matchPercent: 80,
  );

  HomeBloc buildBloc() {
    return HomeBloc(
      getUpcomingTrips: getUpcomingTrips,
      getTravelPreference: getTravelPreference,
      findMatchingRides: findMatchingRides,
      locationService: locationService,
    );
  }

  setUp(() {
    getUpcomingTrips = MockGetUpcomingTripsUseCase();
    getTravelPreference = MockGetTravelPreferenceUseCase();
    findMatchingRides = MockFindMatchingRidesUseCase();
    locationService = MockLocationService();
    // Silent by default -- most tests aren't exercising location fetching.
    when(() => locationService.getCurrentLocation()).thenAnswer((_) async => null);
  });

  group('HomeEvent equality', () {
    test(
      'HomeStarted, LocationsSwapped, RideFormReset, FindRidesRequested, and '
      'RefreshUpcomingTrips support value equality',
      () {
        expect(const HomeStarted(), const HomeStarted());
        expect(const LocationsSwapped(), const LocationsSwapped());
        expect(const RideFormReset(), const RideFormReset());
        expect(const FindRidesRequested(), const FindRidesRequested());
        expect(const RefreshUpcomingTrips(), const RefreshUpcomingTrips());
      },
    );

    test('RideModeChanged supports value equality based on props', () {
      expect(const RideModeChanged(RideMode.find), const RideModeChanged(RideMode.find));
      expect(const RideModeChanged(RideMode.find).props, [RideMode.find]);
      expect(
        const RideModeChanged(RideMode.find),
        isNot(const RideModeChanged(RideMode.offer)),
      );
    });

    test('VehicleTypeChanged supports value equality based on props', () {
      expect(
        const VehicleTypeChanged(VehicleType.car),
        const VehicleTypeChanged(VehicleType.car),
      );
      expect(const VehicleTypeChanged(VehicleType.car).props, [VehicleType.car]);
      expect(
        const VehicleTypeChanged(VehicleType.car),
        isNot(const VehicleTypeChanged(VehicleType.bike)),
      );
    });

    test('FromAddressChanged supports value equality based on props', () {
      expect(
        const FromAddressChanged('Home', lat: 1.0, lng: 2.0),
        const FromAddressChanged('Home', lat: 1.0, lng: 2.0),
      );
      expect(
        const FromAddressChanged('Home', lat: 1.0, lng: 2.0).props,
        ['Home', 1.0, 2.0],
      );
      expect(
        const FromAddressChanged('Home', lat: 1.0, lng: 2.0),
        isNot(const FromAddressChanged('Office', lat: 1.0, lng: 2.0)),
      );
    });

    test('ToAddressChanged supports value equality based on props', () {
      expect(
        const ToAddressChanged('Office', lat: 3.0, lng: 4.0),
        const ToAddressChanged('Office', lat: 3.0, lng: 4.0),
      );
      expect(
        const ToAddressChanged('Office', lat: 3.0, lng: 4.0).props,
        ['Office', 3.0, 4.0],
      );
      expect(const ToAddressChanged('Office'), isNot(const ToAddressChanged('Home')));
    });

    test('DateSelected supports value equality based on props', () {
      final date = DateTime(2026, 5, 1);
      expect(DateSelected(date), DateSelected(date));
      expect(DateSelected(date).props, [date]);
      expect(DateSelected(date), isNot(DateSelected(DateTime(2026, 5, 2))));
    });

    test('TimeSelected supports value equality based on props', () {
      expect(
        const TimeSelected(TimeOfDay(hour: 8, minute: 15)),
        const TimeSelected(TimeOfDay(hour: 8, minute: 15)),
      );
      expect(
        const TimeSelected(TimeOfDay(hour: 8, minute: 15)).props,
        [const TimeOfDay(hour: 8, minute: 15)],
      );
    });

    test('SeatCountChanged supports value equality based on props', () {
      expect(const SeatCountChanged(2), const SeatCountChanged(2));
      expect(const SeatCountChanged(2).props, [2]);
      expect(const SeatCountChanged(2), isNot(const SeatCountChanged(3)));
    });

    test('CurrentLocationFetched supports value equality based on props', () {
      expect(
        const CurrentLocationFetched(lat: 5.0, lng: 6.0),
        const CurrentLocationFetched(lat: 5.0, lng: 6.0),
      );
      expect(const CurrentLocationFetched(lat: 5.0, lng: 6.0).props, [5.0, 6.0]);
      expect(
        const CurrentLocationFetched(lat: 5.0, lng: 6.0),
        isNot(const CurrentLocationFetched(lat: 5.0, lng: 7.0)),
      );
    });
  });

  group('HomeBloc', () {
    test('initial state is HomeState()', () {
      expect(buildBloc().state, const HomeState());
    });

    group('HomeStarted', () {
      blocTest<HomeBloc, HomeState>(
        'emits [loading, success] with trips and unchanged rideMode when '
        'travelPreference is null',
        setUp: () {
          when(() => getUpcomingTrips()).thenAnswer((_) async => [trip]);
          when(() => getTravelPreference()).thenAnswer((_) async => null);
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const HomeStarted()),
        expect: () => [
          const HomeState(status: HomeStatus.loading),
          HomeState(
            status: HomeStatus.success,
            upcomingTrips: [trip],
            rideMode: RideMode.offer,
          ),
        ],
      );

      blocTest<HomeBloc, HomeState>(
        "sets rideMode to find when travelPreference is 'ride'",
        setUp: () {
          when(() => getUpcomingTrips()).thenAnswer((_) async => []);
          when(() => getTravelPreference()).thenAnswer((_) async => 'ride');
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const HomeStarted()),
        expect: () => [
          const HomeState(status: HomeStatus.loading),
          const HomeState(
            status: HomeStatus.success,
            upcomingTrips: [],
            rideMode: RideMode.find,
            travelPreference: 'ride',
          ),
        ],
      );

      blocTest<HomeBloc, HomeState>(
        "sets rideMode to offer when travelPreference is 'drive'",
        setUp: () {
          when(() => getUpcomingTrips()).thenAnswer((_) async => []);
          when(() => getTravelPreference()).thenAnswer((_) async => 'drive');
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const HomeStarted()),
        expect: () => [
          const HomeState(status: HomeStatus.loading),
          const HomeState(
            status: HomeStatus.success,
            upcomingTrips: [],
            rideMode: RideMode.offer,
            travelPreference: 'drive',
          ),
        ],
      );

      blocTest<HomeBloc, HomeState>(
        'emits [loading, failure] with errorMessage when getUpcomingTrips throws',
        setUp: () {
          when(() => getUpcomingTrips()).thenThrow(Exception('boom'));
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const HomeStarted()),
        expect: () => [
          const HomeState(status: HomeStatus.loading),
          isA<HomeState>()
              .having((s) => s.status, 'status', HomeStatus.failure)
              .having((s) => s.errorMessage, 'errorMessage', contains('boom')),
        ],
      );

      blocTest<HomeBloc, HomeState>(
        'fetches current location in the background and emits CurrentLocationFetched '
        'when a position is available',
        setUp: () {
          when(() => getUpcomingTrips()).thenAnswer((_) async => []);
          when(() => getTravelPreference()).thenAnswer((_) async => null);
          when(() => locationService.getCurrentLocation()).thenAnswer(
            (_) async => Position(
              latitude: 12.0,
              longitude: 34.0,
              timestamp: DateTime(2026, 1, 1),
              accuracy: 0,
              altitude: 0,
              altitudeAccuracy: 0,
              heading: 0,
              headingAccuracy: 0,
              speed: 0,
              speedAccuracy: 0,
            ),
          );
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const HomeStarted()),
        wait: const Duration(milliseconds: 50),
        expect: () => [
          const HomeState(status: HomeStatus.loading),
          const HomeState(status: HomeStatus.success),
          isA<HomeState>()
              .having((s) => s.currentLat, 'currentLat', 12.0)
              .having((s) => s.currentLng, 'currentLng', 34.0),
        ],
      );
    });

    group('RefreshUpcomingTrips', () {
      blocTest<HomeBloc, HomeState>(
        'emits updated upcomingTrips on success',
        setUp: () => when(() => getUpcomingTrips()).thenAnswer((_) async => [trip]),
        build: buildBloc,
        act: (bloc) => bloc.add(const RefreshUpcomingTrips()),
        expect: () => [
          HomeState(upcomingTrips: [trip]),
        ],
      );

      blocTest<HomeBloc, HomeState>(
        'emits nothing when getUpcomingTrips throws',
        setUp: () => when(() => getUpcomingTrips()).thenThrow(Exception('fail')),
        build: buildBloc,
        act: (bloc) => bloc.add(const RefreshUpcomingTrips()),
        expect: () => <HomeState>[],
      );
    });

    group('form field events', () {
      blocTest<HomeBloc, HomeState>(
        'RideModeChanged updates rideMode',
        build: buildBloc,
        act: (bloc) => bloc.add(const RideModeChanged(RideMode.find)),
        expect: () => [const HomeState(rideMode: RideMode.find)],
      );

      blocTest<HomeBloc, HomeState>(
        'VehicleTypeChanged to bike clamps seatCount down to 1 when it exceeds max',
        build: buildBloc,
        seed: () => const HomeState(seatCount: 3),
        act: (bloc) => bloc.add(const VehicleTypeChanged(VehicleType.bike)),
        expect: () => [
          const HomeState(vehicleType: VehicleType.bike, seatCount: 1),
        ],
      );

      blocTest<HomeBloc, HomeState>(
        'VehicleTypeChanged to car keeps seatCount when within max',
        build: buildBloc,
        seed: () => const HomeState(vehicleType: VehicleType.bike, seatCount: 1),
        act: (bloc) => bloc.add(const VehicleTypeChanged(VehicleType.car)),
        expect: () => [
          const HomeState(vehicleType: VehicleType.car, seatCount: 1),
        ],
      );

      blocTest<HomeBloc, HomeState>(
        'VehicleTypeChanged to car clamps seatCount down to 4 when it exceeds max',
        build: buildBloc,
        seed: () => const HomeState(seatCount: 5),
        act: (bloc) => bloc.add(const VehicleTypeChanged(VehicleType.car)),
        expect: () => [
          const HomeState(vehicleType: VehicleType.car, seatCount: 4),
        ],
      );

      blocTest<HomeBloc, HomeState>(
        'FromAddressChanged updates fromAddress/fromLat/fromLng',
        build: buildBloc,
        act: (bloc) => bloc.add(const FromAddressChanged('Home', lat: 1.0, lng: 2.0)),
        expect: () => [
          const HomeState(fromAddress: 'Home', fromLat: 1.0, fromLng: 2.0),
        ],
      );

      blocTest<HomeBloc, HomeState>(
        'ToAddressChanged updates toAddress/toLat/toLng',
        build: buildBloc,
        act: (bloc) => bloc.add(const ToAddressChanged('Office', lat: 3.0, lng: 4.0)),
        expect: () => [
          const HomeState(toAddress: 'Office', toLat: 3.0, toLng: 4.0),
        ],
      );

      blocTest<HomeBloc, HomeState>(
        'LocationsSwapped swaps from/to fields',
        build: buildBloc,
        seed: () => const HomeState(
          fromAddress: 'Home',
          fromLat: 1.0,
          fromLng: 2.0,
          toAddress: 'Office',
          toLat: 3.0,
          toLng: 4.0,
        ),
        act: (bloc) => bloc.add(const LocationsSwapped()),
        expect: () => [
          const HomeState(
            fromAddress: 'Office',
            fromLat: 3.0,
            fromLng: 4.0,
            toAddress: 'Home',
            toLat: 1.0,
            toLng: 2.0,
          ),
        ],
      );

      blocTest<HomeBloc, HomeState>(
        'DateSelected updates selectedDate',
        build: buildBloc,
        act: (bloc) => bloc.add(DateSelected(DateTime(2026, 5, 1))),
        expect: () => [
          HomeState(selectedDate: DateTime(2026, 5, 1)),
        ],
      );

      blocTest<HomeBloc, HomeState>(
        'TimeSelected updates selectedTime',
        build: buildBloc,
        act: (bloc) => bloc.add(const TimeSelected(TimeOfDay(hour: 8, minute: 15))),
        expect: () => [
          const HomeState(selectedTime: TimeOfDay(hour: 8, minute: 15)),
        ],
      );

      blocTest<HomeBloc, HomeState>(
        'SeatCountChanged updates seatCount',
        build: buildBloc,
        act: (bloc) => bloc.add(const SeatCountChanged(2)),
        expect: () => [const HomeState(seatCount: 2)],
      );

      blocTest<HomeBloc, HomeState>(
        'CurrentLocationFetched updates currentLat/currentLng',
        build: buildBloc,
        act: (bloc) => bloc.add(const CurrentLocationFetched(lat: 5.0, lng: 6.0)),
        expect: () => [const HomeState(currentLat: 5.0, currentLng: 6.0)],
      );
    });

    group('RideFormReset', () {
      blocTest<HomeBloc, HomeState>(
        'resets the form but keeps refreshed upcomingTrips',
        setUp: () => when(() => getUpcomingTrips()).thenAnswer((_) async => [trip]),
        build: buildBloc,
        seed: () => const HomeState(
          fromAddress: 'Home',
          toAddress: 'Office',
          seatCount: 3,
        ),
        act: (bloc) => bloc.add(const RideFormReset()),
        expect: () => [
          isA<HomeState>()
              .having((s) => s.fromAddress, 'fromAddress', isNull)
              .having((s) => s.toAddress, 'toAddress', isNull)
              .having((s) => s.seatCount, 'seatCount', 1)
              .having((s) => s.upcomingTrips, 'upcomingTrips', [trip]),
        ],
      );

      blocTest<HomeBloc, HomeState>(
        'resets the form and keeps existing upcomingTrips when the refetch throws',
        setUp: () => when(() => getUpcomingTrips()).thenThrow(Exception('fail')),
        build: buildBloc,
        seed: () => HomeState(fromAddress: 'Home', upcomingTrips: [trip]),
        act: (bloc) => bloc.add(const RideFormReset()),
        expect: () => [
          isA<HomeState>()
              .having((s) => s.fromAddress, 'fromAddress', isNull)
              .having((s) => s.upcomingTrips, 'upcomingTrips', [trip]),
        ],
      );
    });

    group('FindRidesRequested', () {
      blocTest<HomeBloc, HomeState>(
        'does nothing when the form is invalid',
        build: buildBloc,
        act: (bloc) => bloc.add(const FindRidesRequested()),
        expect: () => <HomeState>[],
        verify: (_) {
          verifyNever(() => findMatchingRides(
                fromAddress: any(named: 'fromAddress'),
                toAddress: any(named: 'toAddress'),
                fromLat: any(named: 'fromLat'),
                fromLng: any(named: 'fromLng'),
                toLat: any(named: 'toLat'),
                toLng: any(named: 'toLng'),
                date: any(named: 'date'),
                time: any(named: 'time'),
                vehicleType: any(named: 'vehicleType'),
              ));
        },
      );

      final validSeed = HomeState(
        fromAddress: 'Home',
        toAddress: 'Office',
        selectedDate: DateTime(2026, 5, 1),
        selectedTime: const TimeOfDay(hour: 9, minute: 0),
      );

      blocTest<HomeBloc, HomeState>(
        'emits [findStatus loading, findStatus success] with results on success',
        setUp: () => when(() => findMatchingRides(
              fromAddress: any(named: 'fromAddress'),
              toAddress: any(named: 'toAddress'),
              fromLat: any(named: 'fromLat'),
              fromLng: any(named: 'fromLng'),
              toLat: any(named: 'toLat'),
              toLng: any(named: 'toLng'),
              date: any(named: 'date'),
              time: any(named: 'time'),
              vehicleType: any(named: 'vehicleType'),
            )).thenAnswer((_) async => [rideMatch]),
        build: buildBloc,
        seed: () => validSeed,
        act: (bloc) => bloc.add(const FindRidesRequested()),
        expect: () => [
          validSeed.copyWith(
            findStatus: HomeStatus.loading,
            hasSearchedRides: true,
          ),
          validSeed.copyWith(
            findStatus: HomeStatus.success,
            hasSearchedRides: true,
            findResults: [rideMatch],
          ),
        ],
      );

      blocTest<HomeBloc, HomeState>(
        'emits [findStatus loading, findStatus failure] with empty results and '
        'errorMessage when the usecase throws',
        setUp: () => when(() => findMatchingRides(
              fromAddress: any(named: 'fromAddress'),
              toAddress: any(named: 'toAddress'),
              fromLat: any(named: 'fromLat'),
              fromLng: any(named: 'fromLng'),
              toLat: any(named: 'toLat'),
              toLng: any(named: 'toLng'),
              date: any(named: 'date'),
              time: any(named: 'time'),
              vehicleType: any(named: 'vehicleType'),
            )).thenThrow(Exception('search failed')),
        build: buildBloc,
        seed: () => validSeed,
        act: (bloc) => bloc.add(const FindRidesRequested()),
        expect: () => [
          validSeed.copyWith(
            findStatus: HomeStatus.loading,
            hasSearchedRides: true,
          ),
          isA<HomeState>()
              .having((s) => s.findStatus, 'findStatus', HomeStatus.failure)
              .having((s) => s.findResults, 'findResults', isEmpty)
              .having((s) => s.errorMessage, 'errorMessage', contains('search failed')),
        ],
      );
    });
  });
}
