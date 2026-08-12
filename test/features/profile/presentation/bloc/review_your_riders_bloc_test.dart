import 'package:acepool/features/profile/domain/entities/driver_ratable_ride.dart';
import 'package:acepool/features/profile/domain/repositories/ratings_repository.dart';
import 'package:acepool/features/profile/presentation/bloc/review_your_riders_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRatingsRepository extends Mock implements RatingsRepository {}

void main() {
  late MockRatingsRepository repository;

  final ride = DriverRatableRide(
    requestId: 'req1',
    rideId: 'ride1',
    driverId: 'driver1',
    date: DateTime(2026, 1, 1),
    time: const TimeOfDay(hour: 10, minute: 0),
    pickup: 'Pickup',
    drop: 'Drop',
    driverRating: 4,
    ratedRiders: 1,
    totalRiders: 3,
  );

  setUp(() {
    repository = MockRatingsRepository();
  });

  group('ReviewYourRidersEvent equality', () {
    test('supports value equality', () {
      expect(const ReviewYourRidersStarted(), const ReviewYourRidersStarted());
    });
  });

  group('ReviewYourRidersState equality', () {
    test('supports value equality based on props', () {
      expect(const ReviewYourRidersState(), const ReviewYourRidersState());
      expect(
        const ReviewYourRidersState().props,
        [ReviewYourRidersStatus.initial, const <DriverRatableRide>[]],
      );
      expect(
        ReviewYourRidersState(status: ReviewYourRidersStatus.loaded, rides: [ride]),
        ReviewYourRidersState(status: ReviewYourRidersStatus.loaded, rides: [ride]),
      );
      expect(
        ReviewYourRidersState(status: ReviewYourRidersStatus.loaded, rides: [ride]),
        isNot(const ReviewYourRidersState()),
      );
    });
  });

  group('ReviewYourRidersBloc', () {
    test('initial state is ReviewYourRidersState()', () {
      expect(
        ReviewYourRidersBloc(ratingsRepository: repository).state,
        const ReviewYourRidersState(),
      );
    });

    blocTest<ReviewYourRidersBloc, ReviewYourRidersState>(
      'emits [loading, loaded] with rides when '
      'getMyCompletedRidesAsDriver succeeds',
      build: () {
        when(() => repository.getMyCompletedRidesAsDriver())
            .thenAnswer((_) async => [ride]);
        return ReviewYourRidersBloc(ratingsRepository: repository);
      },
      act: (bloc) => bloc.add(const ReviewYourRidersStarted()),
      expect: () => [
        const ReviewYourRidersState(status: ReviewYourRidersStatus.loading),
        ReviewYourRidersState(status: ReviewYourRidersStatus.loaded, rides: [ride]),
      ],
    );

    blocTest<ReviewYourRidersBloc, ReviewYourRidersState>(
      'emits [loading, loaded] with an empty list when there are no '
      'offered rides',
      build: () {
        when(() => repository.getMyCompletedRidesAsDriver())
            .thenAnswer((_) async => []);
        return ReviewYourRidersBloc(ratingsRepository: repository);
      },
      act: (bloc) => bloc.add(const ReviewYourRidersStarted()),
      expect: () => const [
        ReviewYourRidersState(status: ReviewYourRidersStatus.loading),
        ReviewYourRidersState(status: ReviewYourRidersStatus.loaded, rides: []),
      ],
    );

    blocTest<ReviewYourRidersBloc, ReviewYourRidersState>(
      'emits only [loading] and surfaces an error when the repository '
      'throws',
      build: () {
        when(() => repository.getMyCompletedRidesAsDriver())
            .thenThrow(Exception('load failed'));
        return ReviewYourRidersBloc(ratingsRepository: repository);
      },
      act: (bloc) => bloc.add(const ReviewYourRidersStarted()),
      expect: () => const [
        ReviewYourRidersState(status: ReviewYourRidersStatus.loading),
      ],
      errors: () => [isA<Exception>()],
    );
  });
}
