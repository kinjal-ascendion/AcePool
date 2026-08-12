import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:acepool/features/chat/domain/entities/chat_message.dart';
import 'package:acepool/features/chat/domain/repositories/chat_repository.dart';
import 'package:acepool/features/chat/domain/usecases/get_messages_usecase.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late MockChatRepository repository;
  late GetMessagesUseCase usecase;

  setUp(() {
    repository = MockChatRepository();
    usecase = GetMessagesUseCase(repository);
  });

  final message = ChatMessage(
    id: 'msg-1',
    senderId: 'u1',
    receiverId: 'u2',
    text: 'hello',
  );

  test('forwards the stream emitted by repository.getMessages', () {
    when(() => repository.getMessages('chat-1'))
        .thenAnswer((_) => Stream.value([message]));

    expectLater(usecase('chat-1'), emits([message]));
  });

  test('calls repository.getMessages with the given chatId', () {
    when(() => repository.getMessages(any()))
        .thenAnswer((_) => const Stream.empty());

    usecase('chat-1');

    verify(() => repository.getMessages('chat-1')).called(1);
  });

  test('forwards multiple emitted values in order', () {
    when(() => repository.getMessages('chat-1')).thenAnswer(
      (_) => Stream.fromIterable([
        <ChatMessage>[],
        [message],
      ]),
    );

    expectLater(
      usecase('chat-1'),
      emitsInOrder([
        <ChatMessage>[],
        [message],
        emitsDone,
      ]),
    );
  });

  test('forwards errors from the repository stream', () {
    when(() => repository.getMessages('chat-1'))
        .thenAnswer((_) => Stream.error(Exception('boom')));

    expectLater(usecase('chat-1'), emitsError(isException));
  });
}
