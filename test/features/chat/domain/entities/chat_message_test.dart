import 'package:flutter_test/flutter_test.dart';

import 'package:acepool/features/chat/domain/entities/chat_message.dart';

void main() {
  group('ChatMessage', () {
    test('constructs with all fields set', () {
      final timestamp = DateTime(2024, 1, 1, 12, 30);
      final message = ChatMessage(
        id: 'msg-1',
        senderId: 'sender-1',
        receiverId: 'receiver-1',
        text: 'hello',
        audioUrl: 'https://example.com/audio.m4a',
        type: MessageType.audio,
        timestamp: timestamp,
        senderName: 'Alice',
        reactionCount: 3,
      );

      expect(message.id, 'msg-1');
      expect(message.senderId, 'sender-1');
      expect(message.receiverId, 'receiver-1');
      expect(message.text, 'hello');
      expect(message.audioUrl, 'https://example.com/audio.m4a');
      expect(message.type, MessageType.audio);
      expect(message.timestamp, timestamp);
      expect(message.senderName, 'Alice');
      expect(message.reactionCount, 3);
    });

    test('applies default values for optional fields', () {
      final message = ChatMessage(
        id: 'msg-2',
        senderId: 'sender-2',
        receiverId: 'receiver-2',
        text: 'hi there',
      );

      expect(message.audioUrl, isNull);
      expect(message.type, MessageType.text);
      expect(message.timestamp, isNull);
      expect(message.senderName, isNull);
      expect(message.reactionCount, 0);
    });

    test('supports MessageType.text and MessageType.audio explicitly', () {
      final textMessage = ChatMessage(
        id: 'msg-3',
        senderId: 's',
        receiverId: 'r',
        text: 'text msg',
        type: MessageType.text,
      );
      final audioMessage = ChatMessage(
        id: 'msg-4',
        senderId: 's',
        receiverId: 'r',
        text: '',
        type: MessageType.audio,
      );

      expect(textMessage.type, MessageType.text);
      expect(audioMessage.type, MessageType.audio);
    });

    test('supports empty string fields', () {
      final message = ChatMessage(
        id: '',
        senderId: '',
        receiverId: '',
        text: '',
      );

      expect(message.id, isEmpty);
      expect(message.senderId, isEmpty);
      expect(message.receiverId, isEmpty);
      expect(message.text, isEmpty);
    });

    test('MessageType enum has exactly text and audio values', () {
      expect(MessageType.values, [MessageType.text, MessageType.audio]);
    });

    test('non-const instances with equal fields are not identical '
        '(confirms no value equality, ChatMessage is a plain class)', () {
      final timestamp = DateTime(2024, 1, 1);
      final a = ChatMessage(
        id: 'id-1',
        senderId: 's',
        receiverId: 'r',
        text: 'hi',
        timestamp: timestamp,
      );
      final b = ChatMessage(
        id: 'id-1',
        senderId: 's',
        receiverId: 'r',
        text: 'hi',
        timestamp: timestamp,
      );

      expect(identical(a, b), isFalse);
      expect(a == b, isFalse);
    });
  });
}
