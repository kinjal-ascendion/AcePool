import 'package:flutter_test/flutter_test.dart';

import 'package:acepool/features/chat/domain/entities/chat_room.dart';

void main() {
  group('ChatRoom', () {
    test('constructs with all fields set', () {
      final lastMessageTime = DateTime(2024, 5, 1, 9, 0);
      final room = ChatRoom(
        id: 'room-1',
        lastMessage: 'hello there',
        lastMessageTime: lastMessageTime,
        participants: const ['u1', 'u2'],
        participantNames: const {'u1': 'Alice', 'u2': 'Bob'},
        participantPhotos: const {'u1': 'photo1.png'},
        unreadCounts: const {'u1': 2, 'u2': 0},
        pinnedBy: const ['u1'],
        type: 'group',
        groupTitle: 'Trip Chat',
      );

      expect(room.id, 'room-1');
      expect(room.lastMessage, 'hello there');
      expect(room.lastMessageTime, lastMessageTime);
      expect(room.participants, ['u1', 'u2']);
      expect(room.participantNames, {'u1': 'Alice', 'u2': 'Bob'});
      expect(room.participantPhotos, {'u1': 'photo1.png'});
      expect(room.unreadCounts, {'u1': 2, 'u2': 0});
      expect(room.pinnedBy, ['u1']);
      expect(room.type, 'group');
      expect(room.groupTitle, 'Trip Chat');
    });

    test('applies default values for optional fields', () {
      final room = ChatRoom(
        id: 'room-2',
        lastMessage: 'hi',
        participants: const ['u1'],
        participantNames: const {'u1': 'Alice'},
      );

      expect(room.lastMessageTime, isNull);
      expect(room.participantPhotos, isEmpty);
      expect(room.unreadCounts, isEmpty);
      expect(room.pinnedBy, isEmpty);
      expect(room.type, 'private');
      expect(room.groupTitle, isNull);
    });

    group('isPinned', () {
      test('returns true when userId is in pinnedBy', () {
        final room = ChatRoom(
          id: 'room-3',
          lastMessage: 'hi',
          participants: const ['u1', 'u2'],
          participantNames: const {},
          pinnedBy: const ['u1', 'u2'],
        );

        expect(room.isPinned('u1'), isTrue);
      });

      test('returns false when userId is not in pinnedBy', () {
        final room = ChatRoom(
          id: 'room-4',
          lastMessage: 'hi',
          participants: const ['u1', 'u2'],
          participantNames: const {},
          pinnedBy: const ['u2'],
        );

        expect(room.isPinned('u1'), isFalse);
      });

      test('returns false when pinnedBy is empty', () {
        final room = ChatRoom(
          id: 'room-5',
          lastMessage: 'hi',
          participants: const ['u1'],
          participantNames: const {},
        );

        expect(room.isPinned('u1'), isFalse);
      });
    });

    group('getUnreadCount', () {
      test('returns the count for a known userId', () {
        final room = ChatRoom(
          id: 'room-6',
          lastMessage: 'hi',
          participants: const ['u1'],
          participantNames: const {},
          unreadCounts: const {'u1': 5},
        );

        expect(room.getUnreadCount('u1'), 5);
      });

      test('returns 0 for an unknown userId', () {
        final room = ChatRoom(
          id: 'room-7',
          lastMessage: 'hi',
          participants: const ['u1'],
          participantNames: const {},
          unreadCounts: const {'u2': 5},
        );

        expect(room.getUnreadCount('u1'), 0);
      });

      test('returns 0 when unreadCounts is empty', () {
        final room = ChatRoom(
          id: 'room-8',
          lastMessage: 'hi',
          participants: const ['u1'],
          participantNames: const {},
        );

        expect(room.getUnreadCount('u1'), 0);
      });
    });

    test('non-const instances with equal fields are not identical '
        '(confirms no value equality, ChatRoom is a plain class)', () {
      final a = ChatRoom(
        id: 'id-1',
        lastMessage: 'hi',
        participants: const ['u1'],
        participantNames: const {'u1': 'Alice'},
      );
      final b = ChatRoom(
        id: 'id-1',
        lastMessage: 'hi',
        participants: const ['u1'],
        participantNames: const {'u1': 'Alice'},
      );

      expect(identical(a, b), isFalse);
      expect(a == b, isFalse);
    });
  });
}
