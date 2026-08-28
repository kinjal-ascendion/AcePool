import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:acepool/features/chat/domain/entities/chat_room.dart';
import 'package:acepool/features/chat/domain/usecases/get_chat_rooms_usecase.dart';
import 'package:acepool/features/chat/presentation/bloc/chat_list_bloc.dart';

class MockGetChatRoomsUseCase extends Mock implements GetChatRoomsUseCase {}

void main() {
  late MockGetChatRoomsUseCase getChatRooms;

  setUp(() {
    getChatRooms = MockGetChatRoomsUseCase();
  });

  ChatListBloc buildBloc() => ChatListBloc(getChatRooms: getChatRooms);

  final room = ChatRoom(
    id: 'room-1',
    lastMessage: 'hi',
    participants: const ['u1', 'u2'],
    participantNames: const {'u1': 'Alice', 'u2': 'Bob'},
  );

  group('ChatListEvent equality', () {
    test('ChatListSubscriptionRequested supports value equality', () {
      expect(
        const ChatListSubscriptionRequested('u1'),
        const ChatListSubscriptionRequested('u1'),
      );
      expect(const ChatListSubscriptionRequested('u1').props, ['u1']);
      expect(
        const ChatListSubscriptionRequested('u1'),
        isNot(const ChatListSubscriptionRequested('u2')),
      );
    });

    test('ChatListUpdated supports value equality based on the rooms list', () {
      expect(ChatListUpdated([room]), ChatListUpdated([room]));
      expect(ChatListUpdated([room]).props, [
        [room],
      ]);
    });

    test('ChatSearchQueryChanged supports value equality', () {
      expect(const ChatSearchQueryChanged('trip'), const ChatSearchQueryChanged('trip'));
      expect(const ChatSearchQueryChanged('trip').props, ['trip']);
      expect(
        const ChatSearchQueryChanged('trip'),
        isNot(const ChatSearchQueryChanged('other')),
      );
    });
  });

  group('ChatListBloc', () {
    test('initial state is ChatListState()', () {
      when(() => getChatRooms(any())).thenAnswer((_) => const Stream.empty());
      expect(buildBloc().state, const ChatListState());
    });

    blocTest<ChatListBloc, ChatListState>(
      'emits [loading, success] when subscription requested and rooms stream emits',
      setUp: () {
        when(() => getChatRooms('u1')).thenAnswer((_) => Stream.value([room]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const ChatListSubscriptionRequested('u1')),
      expect: () => [
        const ChatListState(status: ChatListStatus.loading),
        ChatListState(status: ChatListStatus.success, rooms: [room]),
      ],
      verify: (_) {
        verify(() => getChatRooms('u1')).called(1);
      },
    );

    blocTest<ChatListBloc, ChatListState>(
      'emits [loading, success, success] for multiple stream emissions',
      setUp: () {
        when(() => getChatRooms('u1')).thenAnswer(
          (_) => Stream.fromIterable([
            <ChatRoom>[],
            [room],
          ]),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const ChatListSubscriptionRequested('u1')),
      expect: () => [
        const ChatListState(status: ChatListStatus.loading),
        const ChatListState(status: ChatListStatus.success, rooms: []),
        ChatListState(status: ChatListStatus.success, rooms: [room]),
      ],
    );

    blocTest<ChatListBloc, ChatListState>(
      'emits [loading, success(empty)] when rooms stream errors '
      '(errors are swallowed into an empty room list)',
      setUp: () {
        when(() => getChatRooms('u1'))
            .thenAnswer((_) => Stream.error(Exception('boom')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const ChatListSubscriptionRequested('u1')),
      expect: () => [
        const ChatListState(status: ChatListStatus.loading),
        const ChatListState(status: ChatListStatus.success, rooms: []),
      ],
    );

    blocTest<ChatListBloc, ChatListState>(
      'ChatListUpdated directly emits success state with rooms',
      build: () {
        when(() => getChatRooms(any())).thenAnswer((_) => const Stream.empty());
        return buildBloc();
      },
      act: (bloc) => bloc.add(ChatListUpdated([room])),
      expect: () => [
        ChatListState(status: ChatListStatus.success, rooms: [room]),
      ],
    );

    blocTest<ChatListBloc, ChatListState>(
      'ChatSearchQueryChanged updates searchQuery without changing status/rooms',
      build: () {
        when(() => getChatRooms(any())).thenAnswer((_) => const Stream.empty());
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ChatSearchQueryChanged('trip')),
      expect: () => [
        const ChatListState(searchQuery: 'trip'),
      ],
    );

    test('cancels previous subscription when a new subscription is requested', () async {
      final controller1 = StreamController<List<ChatRoom>>();
      final controller2 = StreamController<List<ChatRoom>>();
      when(() => getChatRooms('u1')).thenAnswer((_) => controller1.stream);
      when(() => getChatRooms('u2')).thenAnswer((_) => controller2.stream);

      final bloc = buildBloc();

      bloc.add(const ChatListSubscriptionRequested('u1'));
      await Future<void>.delayed(Duration.zero);
      controller1.add([room]);
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.status, ChatListStatus.success);
      expect(bloc.state.rooms, [room]);

      bloc.add(const ChatListSubscriptionRequested('u2'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.status, ChatListStatus.loading);
      expect(controller1.hasListener, isFalse);

      final room2 = ChatRoom(
        id: 'room-2',
        lastMessage: 'ignored',
        participants: const ['u1'],
        participantNames: const {},
      );
      controller1.add([room2]);
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.status, ChatListStatus.loading);

      controller2.add(const []);
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.status, ChatListStatus.success);
      expect(bloc.state.rooms, isEmpty);

      verify(() => getChatRooms('u1')).called(1);
      verify(() => getChatRooms('u2')).called(1);

      await bloc.close();
      await controller1.close();
      await controller2.close();
    });

    test('close cancels the active subscription', () async {
      final controller = StreamController<List<ChatRoom>>();
      when(() => getChatRooms('u1')).thenAnswer((_) => controller.stream);

      final bloc = buildBloc();
      bloc.add(const ChatListSubscriptionRequested('u1'));
      await Future<void>.delayed(Duration.zero);
      await bloc.close();

      expect(controller.hasListener, isFalse);
      await controller.close();
    });
  });
}
