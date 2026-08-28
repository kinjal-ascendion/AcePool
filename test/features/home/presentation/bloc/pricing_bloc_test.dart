import 'package:acepool/core/services/directions_service.dart';
import 'package:acepool/features/home/domain/entities/fare_breakdown.dart';
import 'package:acepool/features/home/domain/entities/vehicle_option.dart';
import 'package:acepool/features/home/domain/usecases/estimate_route_usecase.dart';
import 'package:acepool/features/home/domain/usecases/get_vehicle_options_usecase.dart';
import 'package:acepool/features/home/domain/usecases/schedule_ride_usecase.dart';
import 'package:acepool/features/home/presentation/bloc/pricing_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEstimateRouteUseCase extends Mock implements EstimateRouteUseCase {}

class MockScheduleRideUseCase extends Mock implements ScheduleRideUseCase {}

class MockGetVehicleOptionsUseCase extends Mock implements GetVehicleOptionsUseCase {}

void main() {
  late MockEstimateRouteUseCase estimateRoute;
  late MockScheduleRideUseCase scheduleRide;
  late MockGetVehicleOptionsUseCase getVehicleOptions;

  const vehicles = [
    VehicleOption(id: 'v1', label: 'Honda Activa', type: 'two_wheeler'),
  ];

  setUpAll(() {
    registerFallbackValue(DateTime(2026, 1, 1));
    registerFallbackValue(const TimeOfDay(hour: 0, minute: 0));
    registerFallbackValue(<String, dynamic>{});
  });

  PricingBloc buildBloc() {
    return PricingBloc(
      estimateRoute: estimateRoute,
      scheduleRide: scheduleRide,
      getVehicleOptions: getVehicleOptions,
    );
  }

  setUp(() {
    estimateRoute = MockEstimateRouteUseCase();
    scheduleRide = MockScheduleRideUseCase();
    getVehicleOptions = MockGetVehicleOptionsUseCase();
  });

  group('PricingEvent equality', () {
    final date = DateTime(2026, 5, 1);
    const time = TimeOfDay(hour: 10, minute: 0);

    test('PricingStarted supports value equality based on props', () {
      final event = PricingStarted(
        fromAddress: 'Home',
        toAddress: 'Office',
        fromLat: 1.0,
        fromLng: 2.0,
        toLat: 3.0,
        toLng: 4.0,
        date: date,
        time: time,
        seatCount: 2,
        vehicleType: 'car',
        rideMode: 'offer',
      );
      expect(
        event,
        PricingStarted(
          fromAddress: 'Home',
          toAddress: 'Office',
          fromLat: 1.0,
          fromLng: 2.0,
          toLat: 3.0,
          toLng: 4.0,
          date: date,
          time: time,
          seatCount: 2,
          vehicleType: 'car',
          rideMode: 'offer',
        ),
      );
      expect(event.props, [
        'Home',
        'Office',
        1.0,
        2.0,
        3.0,
        4.0,
        date,
        time,
        2,
        'car',
        'offer',
      ]);
      expect(
        event,
        isNot(PricingStarted(
          fromAddress: 'Other',
          toAddress: 'Office',
          date: date,
          time: time,
          seatCount: 2,
          vehicleType: 'car',
          rideMode: 'offer',
        )),
      );
    });

    test('VehicleSelected supports value equality based on props', () {
      expect(
        const VehicleSelected('v1', 'Honda Activa'),
        const VehicleSelected('v1', 'Honda Activa'),
      );
      expect(const VehicleSelected('v1', 'Honda Activa').props, ['v1', 'Honda Activa']);
      expect(
        const VehicleSelected('v1', 'Honda Activa'),
        isNot(const VehicleSelected('v2', 'Honda Activa')),
      );
    });

    test('RatePerKmChanged supports value equality based on props', () {
      expect(const RatePerKmChanged(8.0), const RatePerKmChanged(8.0));
      expect(const RatePerKmChanged(8.0).props, [8.0]);
      expect(const RatePerKmChanged(8.0), isNot(const RatePerKmChanged(9.0)));
    });

    test(
      'VehiclesRefreshRequested and PublishRideRequested support value '
      'equality',
      () {
        expect(const VehiclesRefreshRequested(), const VehiclesRefreshRequested());
        expect(const PublishRideRequested(), const PublishRideRequested());
      },
    );
  });

  group('PricingState.isFormValid', () {
    test('is true when fare, vehicleId, and a positive ratePerKm are all set', () {
      const state = PricingState(
        fare: FareBreakdown(
          distanceKm: 10,
          durationMinutes: 20,
          vehicleId: 'v1',
          ratePerKm: 5,
        ),
      );
      expect(state.isFormValid, isTrue);
    });

    test('is false when fare is null', () {
      expect(const PricingState().isFormValid, isFalse);
    });

    test('is false when fare.vehicleId is null', () {
      const state = PricingState(
        fare: FareBreakdown(distanceKm: 10, durationMinutes: 20, ratePerKm: 5),
      );
      expect(state.isFormValid, isFalse);
    });

    test('is false when fare.ratePerKm is 0', () {
      const state = PricingState(
        fare: FareBreakdown(distanceKm: 10, durationMinutes: 20, vehicleId: 'v1'),
      );
      expect(state.isFormValid, isFalse);
    });
  });

  group('PricingBloc', () {
    test('initial state is PricingState()', () {
      expect(buildBloc().state, const PricingState());
    });

    group('PricingStarted', () {
      final date = DateTime(2026, 5, 1);
      const time = TimeOfDay(hour: 10, minute: 0);

      blocTest<PricingBloc, PricingState>(
        'fetches the route and vehicles, then emits [loading, ready] when '
        'all 4 coordinates are present',
        setUp: () {
          when(() => estimateRoute(
                originLat: 1.0,
                originLng: 2.0,
                destLat: 3.0,
                destLng: 4.0,
              )).thenAnswer((_) async => const RouteDetails(distanceKm: 20, durationMinutes: 30));
          when(() => getVehicleOptions('car')).thenAnswer((_) async => vehicles);
        },
        build: buildBloc,
        act: (bloc) => bloc.add(PricingStarted(
          fromAddress: 'Home',
          toAddress: 'Office',
          fromLat: 1.0,
          fromLng: 2.0,
          toLat: 3.0,
          toLng: 4.0,
          date: date,
          time: time,
          seatCount: 2,
          vehicleType: 'car',
          rideMode: 'offer',
        )),
        expect: () => [
          PricingState(
            status: PricingStatus.loading,
            fromAddress: 'Home',
            toAddress: 'Office',
            date: date,
            time: time,
            seatCount: 2,
            vehicleType: 'car',
          ),
          PricingState(
            status: PricingStatus.ready,
            fromAddress: 'Home',
            toAddress: 'Office',
            date: date,
            time: time,
            seatCount: 2,
            vehicleType: 'car',
            fare: const FareBreakdown(distanceKm: 20, durationMinutes: 30, ratePerKm: 0),
            vehicles: vehicles,
          ),
        ],
        verify: (_) {
          verify(() => estimateRoute(
                originLat: 1.0,
                originLng: 2.0,
                destLat: 3.0,
                destLng: 4.0,
              )).called(1);
        },
      );

      blocTest<PricingBloc, PricingState>(
        'skips route estimation (fare distance/duration default to 0) when any '
        'coordinate is missing',
        setUp: () {
          when(() => getVehicleOptions('car')).thenAnswer((_) async => vehicles);
        },
        build: buildBloc,
        act: (bloc) => bloc.add(PricingStarted(
          fromAddress: 'Home',
          toAddress: 'Office',
          fromLat: 1.0,
          fromLng: 2.0,
          // toLat/toLng missing
          date: date,
          time: time,
          seatCount: 2,
          vehicleType: 'car',
          rideMode: 'offer',
        )),
        expect: () => [
          PricingState(
            status: PricingStatus.loading,
            fromAddress: 'Home',
            toAddress: 'Office',
            date: date,
            time: time,
            seatCount: 2,
            vehicleType: 'car',
          ),
          PricingState(
            status: PricingStatus.ready,
            fromAddress: 'Home',
            toAddress: 'Office',
            date: date,
            time: time,
            seatCount: 2,
            vehicleType: 'car',
            fare: const FareBreakdown(distanceKm: 0, durationMinutes: 0, ratePerKm: 0),
            vehicles: vehicles,
          ),
        ],
        verify: (_) {
          verifyNever(() => estimateRoute(
                originLat: any(named: 'originLat'),
                originLng: any(named: 'originLng'),
                destLat: any(named: 'destLat'),
                destLng: any(named: 'destLng'),
              ));
        },
      );

      blocTest<PricingBloc, PricingState>(
        'fetches vehicle options using the vehicleType from the event',
        setUp: () {
          when(() => getVehicleOptions('bike')).thenAnswer((_) async => vehicles);
        },
        build: buildBloc,
        act: (bloc) => bloc.add(PricingStarted(
          fromAddress: 'Home',
          toAddress: 'Office',
          date: date,
          time: time,
          seatCount: 1,
          vehicleType: 'bike',
          rideMode: 'find',
        )),
        expect: () => [
          isA<PricingState>().having((s) => s.status, 'status', PricingStatus.loading),
          isA<PricingState>()
              .having((s) => s.status, 'status', PricingStatus.ready)
              .having((s) => s.vehicles, 'vehicles', vehicles),
        ],
        verify: (_) {
          verify(() => getVehicleOptions('bike')).called(1);
        },
      );
    });

    group('VehicleSelected', () {
      blocTest<PricingBloc, PricingState>(
        'updates fare.vehicleId/vehicleLabel when a fare already exists',
        build: buildBloc,
        seed: () => const PricingState(
          status: PricingStatus.ready,
          fare: FareBreakdown(distanceKm: 10, durationMinutes: 15),
        ),
        act: (bloc) => bloc.add(const VehicleSelected('v1', 'Honda Activa')),
        expect: () => [
          const PricingState(
            status: PricingStatus.ready,
            fare: FareBreakdown(
              distanceKm: 10,
              durationMinutes: 15,
              vehicleId: 'v1',
              vehicleLabel: 'Honda Activa',
            ),
          ),
        ],
      );

      blocTest<PricingBloc, PricingState>(
        'does nothing when there is no fare yet',
        build: buildBloc,
        seed: () => const PricingState(status: PricingStatus.loading),
        act: (bloc) => bloc.add(const VehicleSelected('v1', 'Honda Activa')),
        expect: () => <PricingState>[],
      );
    });

    group('RatePerKmChanged', () {
      blocTest<PricingBloc, PricingState>(
        'updates fare.ratePerKm when a fare already exists',
        build: buildBloc,
        seed: () => const PricingState(
          status: PricingStatus.ready,
          fare: FareBreakdown(distanceKm: 10, durationMinutes: 15),
        ),
        act: (bloc) => bloc.add(const RatePerKmChanged(8.0)),
        expect: () => [
          const PricingState(
            status: PricingStatus.ready,
            fare: FareBreakdown(distanceKm: 10, durationMinutes: 15, ratePerKm: 8.0),
          ),
        ],
      );

      blocTest<PricingBloc, PricingState>(
        'does nothing when there is no fare yet',
        build: buildBloc,
        seed: () => const PricingState(status: PricingStatus.loading),
        act: (bloc) => bloc.add(const RatePerKmChanged(8.0)),
        expect: () => <PricingState>[],
      );
    });

    group('VehiclesRefreshRequested', () {
      blocTest<PricingBloc, PricingState>(
        'refetches vehicles using the last-known vehicleType and updates state',
        setUp: () => when(() => getVehicleOptions('car')).thenAnswer((_) async => vehicles),
        build: buildBloc,
        act: (bloc) => bloc.add(const VehiclesRefreshRequested()),
        expect: () => [
          PricingState(vehicles: vehicles),
        ],
        verify: (_) {
          verify(() => getVehicleOptions('car')).called(1);
        },
      );
    });

    group('PublishRideRequested', () {
      final validFare = const FareBreakdown(
        distanceKm: 10,
        durationMinutes: 20,
        vehicleId: 'v1',
        vehicleLabel: 'Honda Activa',
        ratePerKm: 5,
      );
      final date = DateTime(2026, 5, 1);
      const time = TimeOfDay(hour: 10, minute: 0);

      blocTest<PricingBloc, PricingState>(
        'does nothing when fare is null',
        build: buildBloc,
        seed: () => PricingState(status: PricingStatus.ready, date: date, time: time),
        act: (bloc) => bloc.add(const PublishRideRequested()),
        expect: () => <PricingState>[],
      );

      blocTest<PricingBloc, PricingState>(
        'does nothing when date is null',
        build: buildBloc,
        seed: () => PricingState(status: PricingStatus.ready, fare: validFare, time: time),
        act: (bloc) => bloc.add(const PublishRideRequested()),
        expect: () => <PricingState>[],
      );

      blocTest<PricingBloc, PricingState>(
        'does nothing when time is null',
        build: buildBloc,
        seed: () => PricingState(status: PricingStatus.ready, fare: validFare, date: date),
        act: (bloc) => bloc.add(const PublishRideRequested()),
        expect: () => <PricingState>[],
      );

      blocTest<PricingBloc, PricingState>(
        'does nothing when fare.vehicleId is null',
        build: buildBloc,
        seed: () => PricingState(
          status: PricingStatus.ready,
          date: date,
          time: time,
          fare: const FareBreakdown(distanceKm: 10, durationMinutes: 20, ratePerKm: 5),
        ),
        act: (bloc) => bloc.add(const PublishRideRequested()),
        expect: () => <PricingState>[],
      );

      blocTest<PricingBloc, PricingState>(
        'does nothing when fare.ratePerKm is 0',
        build: buildBloc,
        seed: () => PricingState(
          status: PricingStatus.ready,
          date: date,
          time: time,
          fare: const FareBreakdown(
            distanceKm: 10,
            durationMinutes: 20,
            vehicleId: 'v1',
            ratePerKm: 0,
          ),
        ),
        act: (bloc) => bloc.add(const PublishRideRequested()),
        expect: () => <PricingState>[],
      );

      blocTest<PricingBloc, PricingState>(
        'emits [publishing, published] and schedules the ride with computed fare on success',
        setUp: () {
          when(() => scheduleRide(
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
        },
        build: buildBloc,
        seed: () => PricingState(
          status: PricingStatus.ready,
          fromAddress: 'Home',
          toAddress: 'Office',
          date: date,
          time: time,
          seatCount: 2,
          vehicleType: 'car',
          fare: validFare,
        ),
        act: (bloc) => bloc.add(const PublishRideRequested()),
        expect: () => [
          PricingState(
            status: PricingStatus.publishing,
            fromAddress: 'Home',
            toAddress: 'Office',
            date: date,
            time: time,
            seatCount: 2,
            vehicleType: 'car',
            fare: validFare,
          ),
          PricingState(
            status: PricingStatus.published,
            fromAddress: 'Home',
            toAddress: 'Office',
            date: date,
            time: time,
            seatCount: 2,
            vehicleType: 'car',
            fare: validFare,
          ),
        ],
        verify: (_) {
          verify(() => scheduleRide(
                rideMode: 'offer',
                vehicleType: 'car',
                fromAddress: 'Home',
                toAddress: 'Office',
                fromLat: null,
                fromLng: null,
                toLat: null,
                toLng: null,
                date: date,
                time: time,
                seatCount: 2,
                routeDistanceKm: 10,
                routeDurationMinutes: 20,
                fare: {
                  'vehicleId': 'v1',
                  'vehicleLabel': 'Honda Activa',
                  'ratePerKm': 5.0,
                  'totalCost': 50.0,
                  'farePerSeat': 25.0,
                  'driverEarnings': 50.0,
                },
              )).called(1);
        },
      );

      blocTest<PricingBloc, PricingState>(
        'emits [publishing, failure] with errorMessage when scheduleRide throws',
        setUp: () {
          when(() => scheduleRide(
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
              )).thenThrow(Exception('publish failed'));
        },
        build: buildBloc,
        seed: () => PricingState(
          status: PricingStatus.ready,
          date: date,
          time: time,
          seatCount: 2,
          fare: validFare,
        ),
        act: (bloc) => bloc.add(const PublishRideRequested()),
        expect: () => [
          isA<PricingState>().having((s) => s.status, 'status', PricingStatus.publishing),
          isA<PricingState>()
              .having((s) => s.status, 'status', PricingStatus.failure)
              .having((s) => s.errorMessage, 'errorMessage', contains('publish failed')),
        ],
      );
    });
  });
}
