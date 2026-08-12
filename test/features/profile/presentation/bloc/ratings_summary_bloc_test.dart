import 'package:acepool/features/profile/domain/entities/received_rating_ride.dart';
import 'package:acepool/features/profile/domain/repositories/ratings_repository.dart';
import 'package:acepool/features/profile/presentation/bloc/ratings_summary_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRatingsRepository extends Mock implements RatingsRepository {}

void main() {
  late MockRatingsRepository repository;

  final ride = ReceivedRatingRide(
    rideId: 'ride1',
    date: DateTime(2026, 1, 1),
    time: const TimeOfDay(hour: 8, minute: 0),
    pickup: 'Pickup',
    drop: 'Drop',
    rating: 4.5,
    reviews: 2,
  );

  final summary = RatingsSummary(
    averageRating: 4.5,
    totalReviews: 2,
    ratingCounts: const {5: 1, 4: 1},
    rides: [ride],
  );

  const emptySummary = RatingsSummary(
    averageRating: 0,
    totalReviews: 0,
    ratingCounts: {},
    rides: [],
  );

  setUp(() {
    repository = MockRatingsRepository();
  });

  group('RatingsSummaryEvent equality', () {
    test('supports value equality based on props', () {
      expect(
        const RatingsSummaryRequested(RatingsSummarySource.fromDrivers),
        const RatingsSummaryRequested(RatingsSummarySource.fromDrivers),
      );
      expect(
        const RatingsSummaryRequested(RatingsSummarySource.fromDrivers).props,
        [RatingsSummarySource.fromDrivers],
      );
      expect(
        const RatingsSummaryRequested(RatingsSummarySource.fromDrivers),
        isNot(const RatingsSummaryRequested(RatingsSummarySource.fromRiders)),
      );
    });
  });

  group('RatingsSummaryState equality', () {
    test('supports value equality based on props', () {
      expect(const RatingsSummaryState(), const RatingsSummaryState());
      expect(const RatingsSummaryState().props, [RatingsSummaryStatus.initial, null]);
      expect(
        RatingsSummaryState(status: RatingsSummaryStatus.loaded, summary: summary),
        RatingsSummaryState(status: RatingsSummaryStatus.loaded, summary: summary),
      );
      expect(
        RatingsSummaryState(status: RatingsSummaryStatus.loaded, summary: summary),
        isNot(
          const RatingsSummaryState(
            status: RatingsSummaryStatus.loaded,
            summary: emptySummary,
          ),
        ),
      );
    });
  });

  group('RatingsSummaryBloc', () {
    test('initial state is RatingsSummaryState()', () {
      expect(
        RatingsSummaryBloc(ratingsRepository: repository).state,
        const RatingsSummaryState(),
      );
    });

    blocTest<RatingsSummaryBloc, RatingsSummaryState>(
      'emits [loading, loaded] with driver ratings when source is '
      'fromDrivers',
      build: () {
        when(() => repository.getRatingsReceivedFromDrivers())
            .thenAnswer((_) async => summary);
        return RatingsSummaryBloc(ratingsRepository: repository);
      },
      act: (bloc) => bloc.add(
        const RatingsSummaryRequested(RatingsSummarySource.fromDrivers),
      ),
      expect: () => [
        const RatingsSummaryState(status: RatingsSummaryStatus.loading),
        RatingsSummaryState(status: RatingsSummaryStatus.loaded, summary: summary),
      ],
      verify: (_) {
        verify(() => repository.getRatingsReceivedFromDrivers()).called(1);
        verifyNever(() => repository.getRatingsReceivedFromRiders());
      },
    );

    blocTest<RatingsSummaryBloc, RatingsSummaryState>(
      'emits [loading, loaded] with rider ratings when source is fromRiders',
      build: () {
        when(() => repository.getRatingsReceivedFromRiders())
            .thenAnswer((_) async => summary);
        return RatingsSummaryBloc(ratingsRepository: repository);
      },
      act: (bloc) => bloc.add(
        const RatingsSummaryRequested(RatingsSummarySource.fromRiders),
      ),
      expect: () => [
        const RatingsSummaryState(status: RatingsSummaryStatus.loading),
        RatingsSummaryState(status: RatingsSummaryStatus.loaded, summary: summary),
      ],
      verify: (_) {
        verify(() => repository.getRatingsReceivedFromRiders()).called(1);
        verifyNever(() => repository.getRatingsReceivedFromDrivers());
      },
    );

    blocTest<RatingsSummaryBloc, RatingsSummaryState>(
      'emits [loading, loaded] with an empty summary when there are no '
      'ratings',
      build: () {
        when(() => repository.getRatingsReceivedFromDrivers())
            .thenAnswer((_) async => emptySummary);
        return RatingsSummaryBloc(ratingsRepository: repository);
      },
      act: (bloc) => bloc.add(
        const RatingsSummaryRequested(RatingsSummarySource.fromDrivers),
      ),
      expect: () => const [
        RatingsSummaryState(status: RatingsSummaryStatus.loading),
        RatingsSummaryState(status: RatingsSummaryStatus.loaded, summary: emptySummary),
      ],
    );

    blocTest<RatingsSummaryBloc, RatingsSummaryState>(
      'emits only [loading] and surfaces an error when the repository '
      'throws',
      build: () {
        when(() => repository.getRatingsReceivedFromDrivers())
            .thenThrow(Exception('failed to load'));
        return RatingsSummaryBloc(ratingsRepository: repository);
      },
      act: (bloc) => bloc.add(
        const RatingsSummaryRequested(RatingsSummarySource.fromDrivers),
      ),
      expect: () => const [
        RatingsSummaryState(status: RatingsSummaryStatus.loading),
      ],
      errors: () => [isA<Exception>()],
    );
  });
}
