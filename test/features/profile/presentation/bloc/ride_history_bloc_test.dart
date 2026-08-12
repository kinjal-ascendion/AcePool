import 'package:acepool/features/profile/domain/repositories/ride_history_repository.dart';
import 'package:acepool/features/profile/presentation/bloc/ride_history_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRideHistoryRepository extends Mock implements RideHistoryRepository {}

void main() {
  late MockRideHistoryRepository repository;

  final ride = <String, dynamic>{
    'rideId': 'ride1',
    'pickup': 'Pickup',
    'drop': 'Drop',
    'role': 'driver',
  };

  setUp(() {
    repository = MockRideHistoryRepository();
  });

  group('RideHistoryEvent equality', () {
    test('supports value equality', () {
      expect(const RideHistoryStarted(), const RideHistoryStarted());
    });
  });

  group('RideHistoryState equality', () {
    test('supports value equality based on props', () {
      expect(const RideHistoryState(), const RideHistoryState());
      expect(
        const RideHistoryState().props,
        [RideHistoryStatus.initial, const <Map<String, dynamic>>[]],
      );
      expect(
        RideHistoryState(status: RideHistoryStatus.loaded, rides: [ride]),
        RideHistoryState(status: RideHistoryStatus.loaded, rides: [ride]),
      );
      expect(
        RideHistoryState(status: RideHistoryStatus.loaded, rides: [ride]),
        isNot(const RideHistoryState()),
      );
    });
  });

  group('RideHistoryBloc', () {
    test('initial state is RideHistoryState()', () {
      expect(
        RideHistoryBloc(rideHistoryRepository: repository).state,
        const RideHistoryState(),
      );
    });

    blocTest<RideHistoryBloc, RideHistoryState>(
      'emits [loading, loaded] with ride history when getHistory succeeds',
      build: () {
        when(() => repository.getHistory()).thenAnswer((_) async => [ride]);
        return RideHistoryBloc(rideHistoryRepository: repository);
      },
      act: (bloc) => bloc.add(const RideHistoryStarted()),
      expect: () => [
        const RideHistoryState(status: RideHistoryStatus.loading),
        RideHistoryState(status: RideHistoryStatus.loaded, rides: [ride]),
      ],
    );

    blocTest<RideHistoryBloc, RideHistoryState>(
      'emits [loading, loaded] with an empty list when there is no ride '
      'history',
      build: () {
        when(() => repository.getHistory()).thenAnswer((_) async => []);
        return RideHistoryBloc(rideHistoryRepository: repository);
      },
      act: (bloc) => bloc.add(const RideHistoryStarted()),
      expect: () => const [
        RideHistoryState(status: RideHistoryStatus.loading),
        RideHistoryState(status: RideHistoryStatus.loaded, rides: []),
      ],
    );

    blocTest<RideHistoryBloc, RideHistoryState>(
      'emits only [loading] and surfaces an error when the repository '
      'throws',
      build: () {
        when(() => repository.getHistory())
            .thenThrow(Exception('load failed'));
        return RideHistoryBloc(rideHistoryRepository: repository);
      },
      act: (bloc) => bloc.add(const RideHistoryStarted()),
      expect: () => const [
        RideHistoryState(status: RideHistoryStatus.loading),
      ],
      errors: () => [isA<Exception>()],
    );
  });
}
