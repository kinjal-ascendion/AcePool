import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:acepool/features/chat/domain/entities/chat_message.dart';
import 'package:acepool/features/chat/domain/repositories/chat_repository.dart';
import 'package:acepool/features/chat/domain/usecases/send_message_usecase.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late MockChatRepository repository;
  late SendMessageUseCase usecase;

  setUpAll(() {
    registerFallbackValue(ChatMessage(
      id: 'fallback',
      senderId: 'fallback',
      receiverId: 'fallback',
      text: 'fallback',
    ));
  });

  setUp(() {
    repository = MockChatRepository();
    usecase = SendMessageUseCase(repository);
  });

  final message = ChatMessage(
    id: 'msg-1',
    senderId: 'u1',
    receiverId: 'u2',
    text: 'hello',
  );

  test('calls repository.sendMessage with the given arguments', () async {
    when(() => repository.sendMessage(any(), any(), any(), any()))
        .thenAnswer((_) async {});

    await usecase(
      chatId: 'chat-1',
      message: message,
      senderName: 'Alice',
      receiverName: 'Bob',
    );

    verify(() => repository.sendMessage(
          'chat-1',
          message,
          'Alice',
          'Bob',
        )).called(1);
  });

  test('propagates errors thrown by repository.sendMessage', () {
    when(() => repository.sendMessage(any(), any(), any(), any()))
        .thenThrow(Exception('send failed'));

    expect(
      () => usecase(
        chatId: 'chat-1',
        message: message,
        senderName: 'Alice',
        receiverName: 'Bob',
      ),
      throwsException,
    );
  });

  test('completes normally when repository.sendMessage resolves', () async {
    when(() => repository.sendMessage(any(), any(), any(), any()))
        .thenAnswer((_) async {});

    await expectLater(
      usecase(
        chatId: 'chat-1',
        message: message,
        senderName: 'Alice',
        receiverName: 'Bob',
      ),
      completes,
    );
  });
}
