import 'package:acepool/features/profile/domain/entities/rider_ratable_ride.dart';
import 'package:acepool/features/profile/domain/repositories/ratings_repository.dart';
import 'package:acepool/features/profile/presentation/bloc/ratings_by_you_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRatingsRepository extends Mock implements RatingsRepository {}

// Note: RiderRatableRide does not extend Equatable/override ==, so equal
// field values do NOT mean equal instances. Tests reuse a single shared
// instance where identity equality is required, and use field-level
// `having` matchers where the bloc constructs a new instance via
// copyWith.
void main() {
  late MockRatingsRepository repository;

  RiderRatableRide buildRide({int? riderRating}) => RiderRatableRide(
        requestId: 'req1',
        rideId: 'ride1',
        driverId: 'driver1',
        date: DateTime(2026, 1, 1),
        time: const TimeOfDay(hour: 9, minute: 0),
        pickup: 'Pickup',
        drop: 'Drop',
        riderRating: riderRating,
      );

  setUp(() {
    repository = MockRatingsRepository();
  });

  group('RatingsByYouEvent equality', () {
    test('RatingsByYouStarted supports value equality', () {
      expect(const RatingsByYouStarted(), const RatingsByYouStarted());
    });

    test('RatingsByYouExpandToggled supports value equality based on props', () {
      expect(
        const RatingsByYouExpandToggled('req1'),
        const RatingsByYouExpandToggled('req1'),
      );
      expect(const RatingsByYouExpandToggled('req1').props, ['req1']);
      expect(
        const RatingsByYouExpandToggled('req1'),
        isNot(const RatingsByYouExpandToggled('req2')),
      );
    });

    test('RatingsByYouStarSelected supports value equality based on props', () {
      expect(const RatingsByYouStarSelected(3), const RatingsByYouStarSelected(3));
      expect(const RatingsByYouStarSelected(3).props, [3]);
      expect(const RatingsByYouStarSelected(3), isNot(const RatingsByYouStarSelected(4)));
    });

    test('RatingsByYouSubmitted supports value equality based on props', () {
      expect(const RatingsByYouSubmitted('req1'), const RatingsByYouSubmitted('req1'));
      expect(const RatingsByYouSubmitted('req1').props, ['req1']);
      expect(
        const RatingsByYouSubmitted('req1'),
        isNot(const RatingsByYouSubmitted('req2')),
      );
    });
  });

  group('RatingsByYouBloc', () {
    test('initial state is RatingsByYouState()', () {
      expect(
        RatingsByYouBloc(ratingsRepository: repository).state,
        const RatingsByYouState(),
      );
    });

    blocTest<RatingsByYouBloc, RatingsByYouState>(
      'emits [loading, loaded] with rides when getMyCompletedRidesToRate '
      'succeeds',
      build: () {
        final ride = buildRide();
        when(() => repository.getMyCompletedRidesToRate())
            .thenAnswer((_) async => [ride]);
        return RatingsByYouBloc(ratingsRepository: repository);
      },
      act: (bloc) => bloc.add(const RatingsByYouStarted()),
      expect: () => [
        const RatingsByYouState(status: RatingsByYouStatus.loading),
        isA<RatingsByYouState>()
            .having((s) => s.status, 'status', RatingsByYouStatus.loaded)
            .having((s) => s.rides, 'rides', hasLength(1))
            .having((s) => s.rides.first.requestId, 'rides.first.requestId', 'req1'),
      ],
    );

    blocTest<RatingsByYouBloc, RatingsByYouState>(
      'emits [loading, loaded] with an empty list when there are no rides '
      'to rate',
      build: () {
        when(() => repository.getMyCompletedRidesToRate())
            .thenAnswer((_) async => []);
        return RatingsByYouBloc(ratingsRepository: repository);
      },
      act: (bloc) => bloc.add(const RatingsByYouStarted()),
      expect: () => const [
        RatingsByYouState(status: RatingsByYouStatus.loading),
        RatingsByYouState(status: RatingsByYouStatus.loaded, rides: []),
      ],
    );

    blocTest<RatingsByYouBloc, RatingsByYouState>(
      'emits only [loading] and surfaces an error when the repository '
      'throws',
      build: () {
        when(() => repository.getMyCompletedRidesToRate())
            .thenThrow(Exception('load failed'));
        return RatingsByYouBloc(ratingsRepository: repository);
      },
      act: (bloc) => bloc.add(const RatingsByYouStarted()),
      expect: () => const [
        RatingsByYouState(status: RatingsByYouStatus.loading),
      ],
      errors: () => [isA<Exception>()],
    );

    blocTest<RatingsByYouBloc, RatingsByYouState>(
      'expands the tapped ride when RatingsByYouExpandToggled is added',
      build: () => RatingsByYouBloc(ratingsRepository: repository),
      act: (bloc) => bloc.add(const RatingsByYouExpandToggled('req1')),
      expect: () => const [
        RatingsByYouState(expandedRequestId: 'req1'),
      ],
    );

    blocTest<RatingsByYouBloc, RatingsByYouState>(
      'collapses the ride and resets selectedRating when the same ride is '
      'toggled again',
      build: () => RatingsByYouBloc(ratingsRepository: repository),
      seed: () => const RatingsByYouState(
        expandedRequestId: 'req1',
        selectedRating: 4,
      ),
      act: (bloc) => bloc.add(const RatingsByYouExpandToggled('req1')),
      expect: () => const [
        RatingsByYouState(),
      ],
    );

    blocTest<RatingsByYouBloc, RatingsByYouState>(
      'emits selectedRating when RatingsByYouStarSelected is added',
      build: () => RatingsByYouBloc(ratingsRepository: repository),
      act: (bloc) => bloc.add(const RatingsByYouStarSelected(3)),
      expect: () => const [
        RatingsByYouState(selectedRating: 3),
      ],
    );

    blocTest<RatingsByYouBloc, RatingsByYouState>(
      'updates the matching ride and clears expansion when '
      'RatingsByYouSubmitted succeeds',
      build: () {
        when(
          () => repository.submitRiderRating(
            requestId: any(named: 'requestId'),
            rating: any(named: 'rating'),
          ),
        ).thenAnswer((_) async {});
        return RatingsByYouBloc(ratingsRepository: repository);
      },
      seed: () => RatingsByYouState(
        rides: [buildRide()],
        expandedRequestId: 'req1',
        selectedRating: 5,
      ),
      act: (bloc) => bloc.add(const RatingsByYouSubmitted('req1')),
      expect: () => [
        isA<RatingsByYouState>()
            .having((s) => s.rides.single.riderRating, 'rides.single.riderRating', 5)
            .having((s) => s.expandedRequestId, 'expandedRequestId', isNull)
            .having((s) => s.selectedRating, 'selectedRating', 0),
      ],
      verify: (_) {
        verify(
          () => repository.submitRiderRating(requestId: 'req1', rating: 5),
        ).called(1);
      },
    );

    blocTest<RatingsByYouBloc, RatingsByYouState>(
      'leaves rides unchanged when the submitted requestId is not found',
      build: () {
        when(
          () => repository.submitRiderRating(
            requestId: any(named: 'requestId'),
            rating: any(named: 'rating'),
          ),
        ).thenAnswer((_) async {});
        return RatingsByYouBloc(ratingsRepository: repository);
      },
      seed: () => RatingsByYouState(
        rides: [buildRide()],
        expandedRequestId: 'req1',
        selectedRating: 5,
      ),
      act: (bloc) => bloc.add(const RatingsByYouSubmitted('unknown-req')),
      expect: () => [
        isA<RatingsByYouState>()
            .having((s) => s.rides.single.riderRating, 'rides.single.riderRating', isNull)
            .having((s) => s.expandedRequestId, 'expandedRequestId', isNull)
            .having((s) => s.selectedRating, 'selectedRating', 0),
      ],
    );

    blocTest<RatingsByYouBloc, RatingsByYouState>(
      'emits errorMessage when RatingsByYouSubmitted fails',
      build: () {
        when(
          () => repository.submitRiderRating(
            requestId: any(named: 'requestId'),
            rating: any(named: 'rating'),
          ),
        ).thenThrow(Exception('submit failed'));
        return RatingsByYouBloc(ratingsRepository: repository);
      },
      seed: () => RatingsByYouState(
        rides: [buildRide()],
        expandedRequestId: 'req1',
        selectedRating: 5,
      ),
      act: (bloc) => bloc.add(const RatingsByYouSubmitted('req1')),
      expect: () => [
        isA<RatingsByYouState>().having(
          (s) => s.errorMessage,
          'errorMessage',
          contains('submit failed'),
        ),
      ],
    );
  });
}
