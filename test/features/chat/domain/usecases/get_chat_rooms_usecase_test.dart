import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:acepool/features/chat/domain/entities/chat_room.dart';
import 'package:acepool/features/chat/domain/repositories/chat_repository.dart';
import 'package:acepool/features/chat/domain/usecases/get_chat_rooms_usecase.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late MockChatRepository repository;
  late GetChatRoomsUseCase usecase;

  setUp(() {
    repository = MockChatRepository();
    usecase = GetChatRoomsUseCase(repository);
  });

  final room = ChatRoom(
    id: 'room-1',
    lastMessage: 'hi',
    participants: const ['u1', 'u2'],
    participantNames: const {'u1': 'Alice', 'u2': 'Bob'},
  );

  test('forwards the stream emitted by repository.getChatRooms', () {
    when(() => repository.getChatRooms('u1'))
        .thenAnswer((_) => Stream.value([room]));

    expectLater(usecase('u1'), emits([room]));
  });

  test('calls repository.getChatRooms with the given userId', () {
    when(() => repository.getChatRooms(any()))
        .thenAnswer((_) => const Stream.empty());

    usecase('u1');

    verify(() => repository.getChatRooms('u1')).called(1);
  });

  test('forwards multiple emitted values in order', () {
    when(() => repository.getChatRooms('u1')).thenAnswer(
      (_) => Stream.fromIterable([
        <ChatRoom>[],
        [room],
      ]),
    );

    expectLater(
      usecase('u1'),
      emitsInOrder([
        <ChatRoom>[],
        [room],
        emitsDone,
      ]),
    );
  });

  test('forwards errors from the repository stream', () {
    when(() => repository.getChatRooms('u1'))
        .thenAnswer((_) => Stream.error(Exception('boom')));

    expectLater(usecase('u1'), emitsError(isException));
  });
}
