import 'package:acepool/features/profile/domain/repositories/profile_repository.dart';
import 'package:acepool/features/profile/presentation/bloc/route_matching_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository repository;

  setUp(() {
    repository = MockProfileRepository();
  });

  group('RouteMatchingEvent equality', () {
    test('RouteMatchingStarted supports value equality', () {
      expect(const RouteMatchingStarted(), const RouteMatchingStarted());
    });

    test('RouteMatchingSaveRequested supports value equality based on props', () {
      expect(
        const RouteMatchingSaveRequested(7.0),
        const RouteMatchingSaveRequested(7.0),
      );
      expect(const RouteMatchingSaveRequested(7.0).props, [7.0]);
      expect(
        const RouteMatchingSaveRequested(7.0),
        isNot(const RouteMatchingSaveRequested(5.5)),
      );
    });
  });

  group('RouteMatchingBloc', () {
    test('initial state is RouteMatchingState()', () {
      expect(
        RouteMatchingBloc(profileRepository: repository).state,
        const RouteMatchingState(),
      );
    });

    blocTest<RouteMatchingBloc, RouteMatchingState>(
      'emits [loaded] with the fetched radius when RouteMatchingStarted '
      'succeeds',
      build: () {
        when(() => repository.getRouteMatchingRadius())
            .thenAnswer((_) async => 5.5);
        return RouteMatchingBloc(profileRepository: repository);
      },
      act: (bloc) => bloc.add(const RouteMatchingStarted()),
      expect: () => const [
        RouteMatchingState(status: RouteMatchingStatus.loaded, radius: 5.5),
      ],
    );

    blocTest<RouteMatchingBloc, RouteMatchingState>(
      'emits no state and surfaces an error when getRouteMatchingRadius '
      'throws',
      build: () {
        when(() => repository.getRouteMatchingRadius())
            .thenThrow(Exception('load failed'));
        return RouteMatchingBloc(profileRepository: repository);
      },
      act: (bloc) => bloc.add(const RouteMatchingStarted()),
      expect: () => const <RouteMatchingState>[],
      errors: () => [isA<Exception>()],
    );

    blocTest<RouteMatchingBloc, RouteMatchingState>(
      'emits [isSaving true, then saved] when RouteMatchingSaveRequested '
      'succeeds',
      build: () {
        when(() => repository.saveRouteMatchingRadius(any()))
            .thenAnswer((_) async {});
        return RouteMatchingBloc(profileRepository: repository);
      },
      act: (bloc) => bloc.add(const RouteMatchingSaveRequested(7.0)),
      expect: () => const [
        RouteMatchingState(isSaving: true),
        RouteMatchingState(isSaving: false, savedTick: 1, radius: 7.0),
      ],
      verify: (_) {
        verify(() => repository.saveRouteMatchingRadius(7.0)).called(1);
      },
    );

    blocTest<RouteMatchingBloc, RouteMatchingState>(
      'emits [isSaving true, then saveError] when '
      'RouteMatchingSaveRequested fails',
      build: () {
        when(() => repository.saveRouteMatchingRadius(any()))
            .thenThrow(Exception('save failed'));
        return RouteMatchingBloc(profileRepository: repository);
      },
      act: (bloc) => bloc.add(const RouteMatchingSaveRequested(7.0)),
      expect: () => [
        const RouteMatchingState(isSaving: true),
        isA<RouteMatchingState>()
            .having((s) => s.isSaving, 'isSaving', false)
            .having((s) => s.savedTick, 'savedTick', 0)
            .having((s) => s.saveError, 'saveError', contains('save failed')),
      ],
    );
  });
}
