import 'package:acepool/features/profile/domain/entities/rider_review.dart';
import 'package:acepool/features/profile/domain/repositories/ratings_repository.dart';
import 'package:acepool/features/profile/presentation/bloc/review_riders_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRatingsRepository extends Mock implements RatingsRepository {}

// Note: RiderReview does not extend Equatable/override ==, so equal field
// values do NOT mean equal instances. Where the bloc constructs a new
// instance via copyWith, tests use field-level `having` matchers instead of
// full state equality.
void main() {
  late MockRatingsRepository repository;

  RiderReview buildReview({int? driverRating}) => RiderReview(
        requestId: 'req1',
        riderId: 'rider1',
        riderName: 'Alice',
        employeeId: 'EMP001',
        pickupPoint: 'Pickup',
        dropOffPoint: 'Drop',
        driverRating: driverRating,
      );

  setUp(() {
    repository = MockRatingsRepository();
  });

  group('ReviewRidersEvent equality', () {
    test('ReviewRidersStarted supports value equality based on props', () {
      expect(const ReviewRidersStarted('ride1'), const ReviewRidersStarted('ride1'));
      expect(const ReviewRidersStarted('ride1').props, ['ride1']);
      expect(
        const ReviewRidersStarted('ride1'),
        isNot(const ReviewRidersStarted('ride2')),
      );
    });

    test('ReviewRidersStarSelected supports value equality based on props', () {
      const selected = ReviewRidersStarSelected(requestId: 'req1', rating: 4);
      expect(selected, const ReviewRidersStarSelected(requestId: 'req1', rating: 4));
      expect(selected.props, ['req1', 4]);
      expect(
        selected,
        isNot(const ReviewRidersStarSelected(requestId: 'req1', rating: 5)),
      );
    });

    test('ReviewRidersSubmitted supports value equality based on props', () {
      expect(const ReviewRidersSubmitted('req1'), const ReviewRidersSubmitted('req1'));
      expect(const ReviewRidersSubmitted('req1').props, ['req1']);
      expect(
        const ReviewRidersSubmitted('req1'),
        isNot(const ReviewRidersSubmitted('req2')),
      );
    });
  });

  group('ReviewRidersBloc', () {
    test('initial state is ReviewRidersState()', () {
      expect(
        ReviewRidersBloc(ratingsRepository: repository).state,
        const ReviewRidersState(),
      );
    });

    blocTest<ReviewRidersBloc, ReviewRidersState>(
      'emits [loading, loaded] with riders when getRidersToReview succeeds',
      build: () {
        final review = buildReview();
        when(() => repository.getRidersToReview('ride1'))
            .thenAnswer((_) async => [review]);
        return ReviewRidersBloc(ratingsRepository: repository);
      },
      act: (bloc) => bloc.add(const ReviewRidersStarted('ride1')),
      expect: () => [
        const ReviewRidersState(status: ReviewRidersStatus.loading),
        isA<ReviewRidersState>()
            .having((s) => s.status, 'status', ReviewRidersStatus.loaded)
            .having((s) => s.riders, 'riders', hasLength(1))
            .having((s) => s.riders.first.requestId, 'riders.first.requestId', 'req1'),
      ],
      verify: (_) {
        verify(() => repository.getRidersToReview('ride1')).called(1);
      },
    );

    blocTest<ReviewRidersBloc, ReviewRidersState>(
      'emits [loading, loaded] with an empty list when there are no riders '
      'to review',
      build: () {
        when(() => repository.getRidersToReview('ride1'))
            .thenAnswer((_) async => []);
        return ReviewRidersBloc(ratingsRepository: repository);
      },
      act: (bloc) => bloc.add(const ReviewRidersStarted('ride1')),
      expect: () => const [
        ReviewRidersState(status: ReviewRidersStatus.loading),
        ReviewRidersState(status: ReviewRidersStatus.loaded, riders: []),
      ],
    );

    blocTest<ReviewRidersBloc, ReviewRidersState>(
      'emits only [loading] and surfaces an error when the repository '
      'throws',
      build: () {
        when(() => repository.getRidersToReview('ride1'))
            .thenThrow(Exception('load failed'));
        return ReviewRidersBloc(ratingsRepository: repository);
      },
      act: (bloc) => bloc.add(const ReviewRidersStarted('ride1')),
      expect: () => const [
        ReviewRidersState(status: ReviewRidersStatus.loading),
      ],
      errors: () => [isA<Exception>()],
    );

    blocTest<ReviewRidersBloc, ReviewRidersState>(
      'records the selected rating for a rider when '
      'ReviewRidersStarSelected is added',
      build: () => ReviewRidersBloc(ratingsRepository: repository),
      act: (bloc) => bloc.add(
        const ReviewRidersStarSelected(requestId: 'req1', rating: 4),
      ),
      expect: () => const [
        ReviewRidersState(selectedRatings: {'req1': 4}),
      ],
    );

    blocTest<ReviewRidersBloc, ReviewRidersState>(
      'accumulates ratings for multiple riders across events',
      build: () => ReviewRidersBloc(ratingsRepository: repository),
      act: (bloc) => bloc
        ..add(const ReviewRidersStarSelected(requestId: 'req1', rating: 4))
        ..add(const ReviewRidersStarSelected(requestId: 'req2', rating: 2)),
      expect: () => const [
        ReviewRidersState(selectedRatings: {'req1': 4}),
        ReviewRidersState(selectedRatings: {'req1': 4, 'req2': 2}),
      ],
    );

    blocTest<ReviewRidersBloc, ReviewRidersState>(
      'does not emit when ReviewRidersSubmitted is added without a selected '
      'rating for that requestId',
      build: () => ReviewRidersBloc(ratingsRepository: repository),
      seed: () => ReviewRidersState(riders: [buildReview()]),
      act: (bloc) => bloc.add(const ReviewRidersSubmitted('req1')),
      expect: () => const <ReviewRidersState>[],
      verify: (_) {
        verifyNever(
          () => repository.submitDriverRating(
            requestId: any(named: 'requestId'),
            rating: any(named: 'rating'),
          ),
        );
      },
    );

    blocTest<ReviewRidersBloc, ReviewRidersState>(
      'updates the matching rider rating when ReviewRidersSubmitted '
      'succeeds',
      build: () {
        when(
          () => repository.submitDriverRating(
            requestId: any(named: 'requestId'),
            rating: any(named: 'rating'),
          ),
        ).thenAnswer((_) async {});
        return ReviewRidersBloc(ratingsRepository: repository);
      },
      seed: () => ReviewRidersState(
        riders: [buildReview()],
        selectedRatings: const {'req1': 5},
      ),
      act: (bloc) => bloc.add(const ReviewRidersSubmitted('req1')),
      expect: () => [
        isA<ReviewRidersState>()
            .having((s) => s.riders.single.driverRating, 'riders.single.driverRating', 5),
      ],
      verify: (_) {
        verify(
          () => repository.submitDriverRating(requestId: 'req1', rating: 5),
        ).called(1);
      },
    );
  });
}
