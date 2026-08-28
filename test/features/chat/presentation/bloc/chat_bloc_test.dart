import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:acepool/features/chat/domain/entities/chat_message.dart';
import 'package:acepool/features/chat/domain/usecases/get_messages_usecase.dart';
import 'package:acepool/features/chat/domain/usecases/send_message_usecase.dart';
import 'package:acepool/features/chat/presentation/bloc/chat_bloc.dart';

class MockGetMessagesUseCase extends Mock implements GetMessagesUseCase {}

class MockSendMessageUseCase extends Mock implements SendMessageUseCase {}

void main() {
  late MockGetMessagesUseCase getMessages;
  late MockSendMessageUseCase sendMessage;

  setUpAll(() {
    registerFallbackValue(ChatMessage(
      id: 'fallback',
      senderId: 'fallback',
      receiverId: 'fallback',
      text: 'fallback',
    ));
  });

  setUp(() {
    getMessages = MockGetMessagesUseCase();
    sendMessage = MockSendMessageUseCase();
  });

  ChatBloc buildBloc() => ChatBloc(getMessages: getMessages, sendMessage: sendMessage);

  final message = ChatMessage(
    id: 'msg-1',
    senderId: 'u1',
    receiverId: 'u2',
    text: 'hello',
  );

  group('ChatEvent equality', () {
    test('ChatMessagesSubscriptionRequested supports value equality', () {
      expect(
        const ChatMessagesSubscriptionRequested('chat-1'),
        const ChatMessagesSubscriptionRequested('chat-1'),
      );
      expect(const ChatMessagesSubscriptionRequested('chat-1').props, ['chat-1']);
      expect(
        const ChatMessagesSubscriptionRequested('chat-1'),
        isNot(const ChatMessagesSubscriptionRequested('chat-2')),
      );
    });

    test('ChatMessagesUpdated supports value equality based on the messages list', () {
      expect(ChatMessagesUpdated([message]), ChatMessagesUpdated([message]));
      expect(ChatMessagesUpdated([message]).props, [
        [message],
      ]);
      expect(ChatMessagesUpdated([message]), isNot(ChatMessagesUpdated(const [])));
    });

    test('ChatSubscriptionFailed supports value equality', () {
      expect(const ChatSubscriptionFailed('boom'), const ChatSubscriptionFailed('boom'));
      expect(const ChatSubscriptionFailed('boom').props, ['boom']);
      expect(
        const ChatSubscriptionFailed('boom'),
        isNot(const ChatSubscriptionFailed('other')),
      );
    });

    test('ChatMessageSent supports value equality based on props', () {
      const sent = ChatMessageSent(
        chatId: 'chat-1',
        text: 'hi',
        senderId: 'u1',
        receiverId: 'u2',
        senderName: 'Alice',
        receiverName: 'Bob',
      );
      expect(
        sent,
        const ChatMessageSent(
          chatId: 'chat-1',
          text: 'hi',
          senderId: 'u1',
          receiverId: 'u2',
          senderName: 'Alice',
          receiverName: 'Bob',
        ),
      );
      expect(
        sent.props,
        ['chat-1', 'hi', null, MessageType.text, 'u1', 'u2', 'Alice', 'Bob'],
      );
      expect(
        sent,
        isNot(const ChatMessageSent(
          chatId: 'chat-1',
          text: 'different',
          senderId: 'u1',
          receiverId: 'u2',
          senderName: 'Alice',
          receiverName: 'Bob',
        )),
      );
    });
  });

  group('ChatState equality', () {
    test('supports value equality based on props', () {
      expect(const ChatState(), const ChatState());
      expect(const ChatState().props, [ChatStatus.initial, const <ChatMessage>[], null]);
      expect(
        ChatState(status: ChatStatus.success, messages: [message]),
        ChatState(status: ChatStatus.success, messages: [message]),
      );
      expect(
        const ChatState(status: ChatStatus.failure, errorMessage: 'x'),
        isNot(const ChatState(status: ChatStatus.failure, errorMessage: 'y')),
      );
    });
  });

  group('ChatBloc', () {
    test('initial state is ChatState()', () {
      when(() => getMessages(any())).thenAnswer((_) => const Stream.empty());
      expect(buildBloc().state, const ChatState());
    });

    blocTest<ChatBloc, ChatState>(
      'emits [loading, success] when subscription requested and messages stream emits',
      setUp: () {
        when(() => getMessages('chat-1'))
            .thenAnswer((_) => Stream.value([message]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const ChatMessagesSubscriptionRequested('chat-1')),
      expect: () => [
        const ChatState(status: ChatStatus.loading),
        ChatState(status: ChatStatus.success, messages: [message]),
      ],
      verify: (_) {
        verify(() => getMessages('chat-1')).called(1);
      },
    );

    blocTest<ChatBloc, ChatState>(
      'emits [loading, success, success] for multiple stream emissions',
      setUp: () {
        when(() => getMessages('chat-1')).thenAnswer(
          (_) => Stream.fromIterable([
            <ChatMessage>[],
            [message],
          ]),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const ChatMessagesSubscriptionRequested('chat-1')),
      expect: () => [
        const ChatState(status: ChatStatus.loading),
        const ChatState(status: ChatStatus.success, messages: []),
        ChatState(status: ChatStatus.success, messages: [message]),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'emits [loading, failure] when messages stream errors',
      setUp: () {
        when(() => getMessages('chat-1'))
            .thenAnswer((_) => Stream.error(Exception('boom')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const ChatMessagesSubscriptionRequested('chat-1')),
      expect: () => [
        const ChatState(status: ChatStatus.loading),
        isA<ChatState>()
            .having((s) => s.status, 'status', ChatStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage', contains('boom')),
      ],
    );

    test('cancels previous subscription when a new subscription is requested', () async {
      final controller1 = StreamController<List<ChatMessage>>();
      final controller2 = StreamController<List<ChatMessage>>();
      when(() => getMessages('chat-1')).thenAnswer((_) => controller1.stream);
      when(() => getMessages('chat-2')).thenAnswer((_) => controller2.stream);

      final bloc = buildBloc();

      bloc.add(const ChatMessagesSubscriptionRequested('chat-1'));
      await Future<void>.delayed(Duration.zero);
      controller1.add([message]);
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.status, ChatStatus.success);
      expect(bloc.state.messages, [message]);

      // Requesting a new subscription should cancel the first stream.
      bloc.add(const ChatMessagesSubscriptionRequested('chat-2'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.status, ChatStatus.loading);
      expect(controller1.hasListener, isFalse);

      // Further events on the cancelled stream must not affect state.
      final message2 = ChatMessage(id: 'msg-2', senderId: 'u2', receiverId: 'u1', text: 'ignored');
      controller1.add([message2]);
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.status, ChatStatus.loading);

      // The new stream still works.
      controller2.add(const []);
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.status, ChatStatus.success);
      expect(bloc.state.messages, isEmpty);

      verify(() => getMessages('chat-1')).called(1);
      verify(() => getMessages('chat-2')).called(1);

      await bloc.close();
      await controller1.close();
      await controller2.close();
    });

    blocTest<ChatBloc, ChatState>(
      'ChatMessagesUpdated directly emits success state with messages',
      build: () {
        when(() => getMessages(any())).thenAnswer((_) => const Stream.empty());
        return buildBloc();
      },
      act: (bloc) => bloc.add(ChatMessagesUpdated([message])),
      expect: () => [
        ChatState(status: ChatStatus.success, messages: [message]),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'ChatSubscriptionFailed directly emits failure state with error',
      build: () {
        when(() => getMessages(any())).thenAnswer((_) => const Stream.empty());
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ChatSubscriptionFailed('bad thing')),
      expect: () => [
        const ChatState(status: ChatStatus.failure, errorMessage: 'bad thing'),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'ChatMessageSent calls sendMessage usecase and emits nothing on success',
      setUp: () {
        when(() => sendMessage(
              chatId: any(named: 'chatId'),
              message: any(named: 'message'),
              senderName: any(named: 'senderName'),
              receiverName: any(named: 'receiverName'),
            )).thenAnswer((_) async {});
      },
      build: () {
        when(() => getMessages(any())).thenAnswer((_) => const Stream.empty());
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ChatMessageSent(
        chatId: 'chat-1',
        text: 'hello',
        senderId: 'u1',
        receiverId: 'u2',
        senderName: 'Alice',
        receiverName: 'Bob',
      )),
      expect: () => <ChatState>[],
      verify: (_) {
        verify(() => sendMessage(
              chatId: 'chat-1',
              message: any(named: 'message'),
              senderName: 'Alice',
              receiverName: 'Bob',
            )).called(1);
      },
    );

    blocTest<ChatBloc, ChatState>(
      'ChatMessageSent emits failure state when sendMessage throws',
      setUp: () {
        when(() => sendMessage(
              chatId: any(named: 'chatId'),
              message: any(named: 'message'),
              senderName: any(named: 'senderName'),
              receiverName: any(named: 'receiverName'),
            )).thenThrow(Exception('send failed'));
      },
      build: () {
        when(() => getMessages(any())).thenAnswer((_) => const Stream.empty());
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ChatMessageSent(
        chatId: 'chat-1',
        text: 'hello',
        senderId: 'u1',
        receiverId: 'u2',
        senderName: 'Alice',
        receiverName: 'Bob',
      )),
      expect: () => [
        isA<ChatState>()
            .having((s) => s.status, 'status', ChatStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage', contains('send failed')),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'ChatMessageSent for audio type builds an audio message',
      setUp: () {
        when(() => sendMessage(
              chatId: any(named: 'chatId'),
              message: any(named: 'message'),
              senderName: any(named: 'senderName'),
              receiverName: any(named: 'receiverName'),
            )).thenAnswer((_) async {});
      },
      build: () {
        when(() => getMessages(any())).thenAnswer((_) => const Stream.empty());
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ChatMessageSent(
        chatId: 'chat-1',
        text: '',
        audioUrl: 'https://example.com/audio.m4a',
        type: MessageType.audio,
        senderId: 'u1',
        receiverId: 'u2',
        senderName: 'Alice',
        receiverName: 'Bob',
      )),
      expect: () => <ChatState>[],
      verify: (_) {
        final captured = verify(() => sendMessage(
              chatId: 'chat-1',
              message: captureAny(named: 'message'),
              senderName: 'Alice',
              receiverName: 'Bob',
            )).captured;
        final sentMessage = captured.single as ChatMessage;
        expect(sentMessage.type, MessageType.audio);
        expect(sentMessage.audioUrl, 'https://example.com/audio.m4a');
        expect(sentMessage.senderId, 'u1');
        expect(sentMessage.receiverId, 'u2');
      },
    );

    test('close cancels the active subscription', () async {
      final controller = StreamController<List<ChatMessage>>();
      when(() => getMessages('chat-1')).thenAnswer((_) => controller.stream);

      final bloc = buildBloc();
      bloc.add(const ChatMessagesSubscriptionRequested('chat-1'));
      await Future<void>.delayed(Duration.zero);
      await bloc.close();

      expect(controller.hasListener, isFalse);
      await controller.close();
    });
  });
}
