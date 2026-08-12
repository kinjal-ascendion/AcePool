import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:acepool/features/rides/domain/repositories/rides_repository.dart';
import 'package:acepool/features/rides/presentation/bloc/ride_map_bloc.dart';

class MockRidesRepository extends Mock implements RidesRepository {}

void main() {
  late MockRidesRepository repository;

  setUp(() {
    repository = MockRidesRepository();
  });

  group('RideMapEvent equality', () {
    test('RideMapStarted supports value equality based on props', () {
      expect(
        const RideMapStarted(rideId: 'ride-1', initialNote: 'Initial'),
        const RideMapStarted(rideId: 'ride-1', initialNote: 'Initial'),
      );
      expect(
        const RideMapStarted(rideId: 'ride-1', initialNote: 'Initial').props,
        ['ride-1', 'Initial'],
      );
      expect(
        const RideMapStarted(rideId: 'ride-1'),
        isNot(const RideMapStarted(rideId: 'ride-2')),
      );
    });

    test('RideMapNoteChanged supports value equality based on props', () {
      expect(const RideMapNoteChanged('Something'), const RideMapNoteChanged('Something'));
      expect(const RideMapNoteChanged('Something').props, ['Something']);
      expect(
        const RideMapNoteChanged('Something'),
        isNot(const RideMapNoteChanged(null)),
      );
    });
  });

  group('RideMapBloc', () {
    test('initial state is RideMapState()', () {
      expect(RideMapBloc(ridesRepository: repository).state, const RideMapState());
    });

    blocTest<RideMapBloc, RideMapState>(
      'RideMapStarted seeds tripNote from initialNote, resolves isDriver, '
      'then applies note updates emitted by watchRideNote',
      setUp: () {
        when(() => repository.isRideOwnedByCurrentUser('ride-1'))
            .thenAnswer((_) async => true);
        when(() => repository.watchRideNote('ride-1'))
            .thenAnswer((_) => Stream.value('Live note'));
      },
      build: () => RideMapBloc(ridesRepository: repository),
      act: (bloc) => bloc.add(const RideMapStarted(rideId: 'ride-1', initialNote: 'Initial')),
      expect: () => [
        const RideMapState(tripNote: 'Initial'),
        const RideMapState(tripNote: 'Initial', isDriver: true),
        const RideMapState(tripNote: 'Live note', isDriver: true),
      ],
      verify: (_) {
        verify(() => repository.isRideOwnedByCurrentUser('ride-1')).called(1);
        verify(() => repository.watchRideNote('ride-1')).called(1);
      },
    );

    blocTest<RideMapBloc, RideMapState>(
      'RideMapStarted swallows an isRideOwnedByCurrentUser failure and still '
      'subscribes to note updates',
      setUp: () {
        when(() => repository.isRideOwnedByCurrentUser('ride-2'))
            .thenThrow(Exception('boom'));
        when(() => repository.watchRideNote('ride-2'))
            .thenAnswer((_) => const Stream.empty());
      },
      build: () => RideMapBloc(ridesRepository: repository),
      act: (bloc) => bloc.add(const RideMapStarted(rideId: 'ride-2')),
      expect: () => [
        const RideMapState(tripNote: null),
      ],
    );

    blocTest<RideMapBloc, RideMapState>(
      'RideMapStarted with no initialNote and isDriver resolving to the '
      "state's existing (false) default only produces a single emission "
      '(the bloc only always-emits the very first call; equal subsequent '
      'states are deduped)',
      setUp: () {
        when(() => repository.isRideOwnedByCurrentUser('ride-3'))
            .thenAnswer((_) async => false);
        when(() => repository.watchRideNote('ride-3'))
            .thenAnswer((_) => const Stream.empty());
      },
      build: () => RideMapBloc(ridesRepository: repository),
      act: (bloc) => bloc.add(const RideMapStarted(rideId: 'ride-3')),
      expect: () => [
        const RideMapState(),
      ],
    );

    blocTest<RideMapBloc, RideMapState>(
      'RideMapNoteChanged updates tripNote directly, including clearing it '
      'to null',
      build: () => RideMapBloc(ridesRepository: repository),
      seed: () => const RideMapState(tripNote: 'Something'),
      act: (bloc) => bloc.add(const RideMapNoteChanged(null)),
      expect: () => [
        const RideMapState(tripNote: null),
      ],
    );

    blocTest<RideMapBloc, RideMapState>(
      'a second RideMapStarted cancels the previous note subscription '
      'before subscribing again',
      setUp: () {
        when(() => repository.isRideOwnedByCurrentUser(any()))
            .thenAnswer((_) async => false);
        when(() => repository.watchRideNote('ride-a'))
            .thenAnswer((_) => Stream.value('note-a'));
        when(() => repository.watchRideNote('ride-b'))
            .thenAnswer((_) => Stream.value('note-b'));
      },
      build: () => RideMapBloc(ridesRepository: repository),
      act: (bloc) async {
        bloc.add(const RideMapStarted(rideId: 'ride-a'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const RideMapStarted(rideId: 'ride-b'));
      },
      verify: (_) {
        verify(() => repository.watchRideNote('ride-a')).called(1);
        verify(() => repository.watchRideNote('ride-b')).called(1);
      },
    );

    test('close() cancels the note subscription without throwing', () async {
      final controller = StreamController<String?>();
      when(() => repository.isRideOwnedByCurrentUser('ride-4'))
          .thenAnswer((_) async => false);
      when(() => repository.watchRideNote('ride-4')).thenAnswer((_) => controller.stream);

      final bloc = RideMapBloc(ridesRepository: repository);
      bloc.add(const RideMapStarted(rideId: 'ride-4'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await bloc.close();
      expect(controller.hasListener, isFalse);
      await controller.close();
    });
  });
}
