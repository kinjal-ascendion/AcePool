import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:acepool/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:acepool/features/chat/domain/entities/chat_message.dart';

class MockFirebaseStorage extends Mock implements FirebaseStorage {}

class MockReference extends Mock implements Reference {}

class MockTaskSnapshot extends Mock implements TaskSnapshot {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

/// A [Fake] (not [Mock]) so we can implement `then` with real delegating
/// code. mocktail cannot reliably match a `when()` stub against the
/// generic method `Task.then<S>`, so a hand-written delegate is used
/// instead to make `await someUploadTask` resolve/throw as configured.
class FakeUploadTask extends Fake implements UploadTask {
  FakeUploadTask(this._future);
  final Future<TaskSnapshot> _future;

  @override
  Future<S> then<S>(FutureOr<S> Function(TaskSnapshot) onValue, {Function? onError}) {
    return _future.then(onValue, onError: onError);
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(SettableMetadata());
    registerFallbackValue(File(''));
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(SetOptions(merge: true));
  });

  group('ChatRepositoryImpl.getChatRooms', () {
    late FakeFirebaseFirestore firestore;
    late ChatRepositoryImpl repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = ChatRepositoryImpl(db: firestore, storage: MockFirebaseStorage());
    });

    test('maps a full firestore doc into a ChatRoom', () async {
      final lastMessageTime = DateTime(2024, 3, 1, 10, 30);
      await firestore.collection('chats').doc('room-1').set({
        'lastMessage': 'hello',
        'lastMessageTime': Timestamp.fromDate(lastMessageTime),
        'participants': ['u1', 'u2'],
        'participantNames': {'u1': 'Alice', 'u2': 'Bob'},
        'participantPhotos': {'u1': 'photo.png'},
        'unreadCounts': {'u1': 2, 'u2': 0},
        'pinnedBy': ['u1'],
        'type': 'group',
        'groupTitle': 'Trip',
      });

      final rooms = await repository.getChatRooms('u1').first;

      expect(rooms, hasLength(1));
      final room = rooms.first;
      expect(room.id, 'room-1');
      expect(room.lastMessage, 'hello');
      expect(room.lastMessageTime, lastMessageTime);
      expect(room.participants, ['u1', 'u2']);
      expect(room.participantNames, {'u1': 'Alice', 'u2': 'Bob'});
      expect(room.participantPhotos, {'u1': 'photo.png'});
      expect(room.unreadCounts, {'u1': 2, 'u2': 0});
      expect(room.pinnedBy, ['u1']);
      expect(room.type, 'group');
      expect(room.groupTitle, 'Trip');
    });

    test('applies defaults when optional fields are missing', () async {
      await firestore.collection('chats').doc('room-2').set({
        'participants': ['u1'],
      });

      final rooms = await repository.getChatRooms('u1').first;

      expect(rooms, hasLength(1));
      final room = rooms.first;
      expect(room.lastMessage, '');
      expect(room.lastMessageTime, isNull);
      expect(room.participantNames, isEmpty);
      expect(room.participantPhotos, isEmpty);
      expect(room.unreadCounts, isEmpty);
      expect(room.pinnedBy, isEmpty);
      expect(room.type, 'private');
      expect(room.groupTitle, isNull);
    });

    test('only returns rooms containing the given userId as a participant', () async {
      await firestore.collection('chats').doc('room-a').set({'participants': ['u1']});
      await firestore.collection('chats').doc('room-b').set({'participants': ['u2']});

      final rooms = await repository.getChatRooms('u1').first;

      expect(rooms.map((r) => r.id), ['room-a']);
    });

    test('emits an updated list when the underlying collection changes', () async {
      await firestore.collection('chats').doc('room-1').set({'participants': ['u1']});

      final stream = repository.getChatRooms('u1');
      final emissions = <int>[];
      final sub = stream.listen((rooms) => emissions.add(rooms.length));

      await Future<void>.delayed(Duration.zero);
      await firestore.collection('chats').doc('room-2').set({'participants': ['u1']});
      await Future<void>.delayed(Duration.zero);

      expect(emissions, [1, 2]);
      await sub.cancel();
    });
  });

  group('ChatRepositoryImpl.getMessages', () {
    late FakeFirebaseFirestore firestore;
    late ChatRepositoryImpl repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = ChatRepositoryImpl(db: firestore, storage: MockFirebaseStorage());
    });

    test('maps a full message doc into a ChatMessage', () async {
      final timestamp = DateTime(2024, 4, 1, 8, 0);
      await firestore
          .collection('chats')
          .doc('chat-1')
          .collection('messages')
          .doc('msg-1')
          .set({
        'senderId': 'u1',
        'receiverId': 'u2',
        'text': 'hi',
        'audioUrl': 'https://example.com/a.m4a',
        'type': 'audio',
        'timestamp': Timestamp.fromDate(timestamp),
        'senderName': 'Alice',
        'reactionCount': 3,
      });

      final messages = await repository.getMessages('chat-1').first;

      expect(messages, hasLength(1));
      final message = messages.first;
      expect(message.id, 'msg-1');
      expect(message.senderId, 'u1');
      expect(message.receiverId, 'u2');
      expect(message.text, 'hi');
      expect(message.audioUrl, 'https://example.com/a.m4a');
      expect(message.type, MessageType.audio);
      expect(message.timestamp, timestamp);
      expect(message.senderName, 'Alice');
      expect(message.reactionCount, 3);
    });

    test('applies defaults when optional fields are missing', () async {
      await firestore
          .collection('chats')
          .doc('chat-1')
          .collection('messages')
          .doc('msg-1')
          .set({});

      final messages = await repository.getMessages('chat-1').first;

      expect(messages, hasLength(1));
      final message = messages.first;
      expect(message.senderId, '');
      expect(message.receiverId, '');
      expect(message.text, '');
      expect(message.audioUrl, isNull);
      expect(message.type, MessageType.text);
      expect(message.timestamp, isNull);
      expect(message.senderName, isNull);
      expect(message.reactionCount, 0);
    });

    test('maps a non-"audio" type value to MessageType.text', () async {
      await firestore
          .collection('chats')
          .doc('chat-1')
          .collection('messages')
          .doc('msg-1')
          .set({'type': 'text'});

      final messages = await repository.getMessages('chat-1').first;

      expect(messages.first.type, MessageType.text);
    });

    test('only returns messages for the given chatId', () async {
      await firestore.collection('chats').doc('chat-1').collection('messages').doc('m1').set({'text': 'a'});
      await firestore.collection('chats').doc('chat-2').collection('messages').doc('m2').set({'text': 'b'});

      final messages = await repository.getMessages('chat-1').first;

      expect(messages, hasLength(1));
      expect(messages.first.text, 'a');
    });
  });

  group('ChatRepositoryImpl.sendMessage', () {
    late FakeFirebaseFirestore firestore;
    late ChatRepositoryImpl repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = ChatRepositoryImpl(db: firestore, storage: MockFirebaseStorage());
    });

    test('first message in a new private chat sets participants from sender+receiver', () async {
      final message = ChatMessage(
        id: '',
        senderId: 'u1',
        receiverId: 'u2',
        text: 'hello',
      );

      await repository.sendMessage('chat-1', message, 'Alice', 'Bob');

      final doc = await firestore.collection('chats').doc('chat-1').get();
      final data = doc.data()!;
      expect(data['type'], 'private');
      expect(List<String>.from(data['participants']), containsAll(['u1', 'u2']));
      expect(data['participantNames'], {'u1': 'Alice', 'u2': 'Bob'});
      expect(data['lastMessage'], 'hello');
      expect(data['unreadCounts'], {'u2': 1});

      final messages = await firestore.collection('chats').doc('chat-1').collection('messages').get();
      expect(messages.docs, hasLength(1));
      final messageData = messages.docs.first.data();
      expect(messageData['senderId'], 'u1');
      expect(messageData['receiverId'], 'u2');
      expect(messageData['text'], 'hello');
      expect(messageData['type'], 'text');
      expect(messageData['senderName'], 'Alice');
    });

    test('first message in a new group chat only adds sender to participants', () async {
      final message = ChatMessage(
        id: '',
        senderId: 'u1',
        receiverId: 'group',
        text: 'hi all',
      );

      await repository.sendMessage('chat-group', message, 'Alice', 'ignored-receiver-name');

      final doc = await firestore.collection('chats').doc('chat-group').get();
      final data = doc.data()!;
      expect(data['type'], 'group');
      expect(List<String>.from(data['participants']), ['u1']);
      expect(data['participantNames'], {'u1': 'Alice'});
      // Sender is not counted as unread for themselves, and there are no
      // other participants yet, so unreadCounts stays empty.
      expect(data['unreadCounts'], isEmpty);
    });

    test('subsequent message in an existing chat reuses stored participants and increments unread counts', () async {
      await firestore.collection('chats').doc('chat-1').set({
        'participants': ['u1', 'u2'],
        'participantNames': {'u1': 'Alice', 'u2': 'Bob'},
        'type': 'private',
        'unreadCounts': {'u2': 1},
      });

      final message = ChatMessage(
        id: '',
        senderId: 'u1',
        receiverId: 'u2',
        text: 'second message',
      );

      await repository.sendMessage('chat-1', message, 'Alice', 'Bob');

      final doc = await firestore.collection('chats').doc('chat-1').get();
      final data = doc.data()!;
      expect(data['lastMessage'], 'second message');
      // FieldValue.increment(1) applied on top of the existing unreadCounts.u2 = 1
      expect(data['unreadCounts'], {'u2': 2});
    });

    test('audio message sets lastMessage to "Audio message"', () async {
      final message = ChatMessage(
        id: '',
        senderId: 'u1',
        receiverId: 'u2',
        text: '',
        audioUrl: 'https://example.com/audio.m4a',
        type: MessageType.audio,
      );

      await repository.sendMessage('chat-1', message, 'Alice', 'Bob');

      final doc = await firestore.collection('chats').doc('chat-1').get();
      expect(doc.data()!['lastMessage'], 'Audio message');

      final messages = await firestore.collection('chats').doc('chat-1').collection('messages').get();
      expect(messages.docs.first.data()['type'], 'audio');
      expect(messages.docs.first.data()['audioUrl'], 'https://example.com/audio.m4a');
    });

    test('uses message.timestamp for rideDate when provided', () async {
      final timestamp = DateTime(2024, 6, 1);
      final message = ChatMessage(
        id: '',
        senderId: 'u1',
        receiverId: 'u2',
        text: 'hi',
        timestamp: timestamp,
      );

      await repository.sendMessage('chat-1', message, 'Alice', 'Bob');

      final doc = await firestore.collection('chats').doc('chat-1').get();
      final rideDate = doc.data()!['rideDate'] as Timestamp;
      expect(rideDate.toDate(), timestamp);
    });

    test('falls back to server timestamp for rideDate when message.timestamp is null', () async {
      final message = ChatMessage(
        id: '',
        senderId: 'u1',
        receiverId: 'u2',
        text: 'hi',
      );

      await repository.sendMessage('chat-1', message, 'Alice', 'Bob');

      final doc = await firestore.collection('chats').doc('chat-1').get();
      expect(doc.data()!['rideDate'], isNotNull);
      expect(doc.data()!['rideDate'], isA<Timestamp>());
    });
  });

  group('ChatRepositoryImpl.markAsRead', () {
    late FakeFirebaseFirestore firestore;
    late ChatRepositoryImpl repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = ChatRepositoryImpl(db: firestore, storage: MockFirebaseStorage());
    });

    test('merges unreadCounts[userId] = 0 without clobbering other keys', () async {
      await firestore.collection('chats').doc('chat-1').set({
        'lastMessage': 'hi',
        'unreadCounts': {'u1': 3, 'u2': 5},
      });

      await repository.markAsRead('chat-1', 'u1');

      final doc = await firestore.collection('chats').doc('chat-1').get();
      final data = doc.data()!;
      expect(data['unreadCounts'], {'u1': 0, 'u2': 5});
      expect(data['lastMessage'], 'hi');
    });

    test('creates the unreadCounts map when the doc previously had none', () async {
      await firestore.collection('chats').doc('chat-1').set({'lastMessage': 'hi'});

      await repository.markAsRead('chat-1', 'u1');

      final doc = await firestore.collection('chats').doc('chat-1').get();
      expect(doc.data()!['unreadCounts'], {'u1': 0});
    });

    test('swallows errors instead of throwing', () async {
      // A document ID cannot contain a forward slash; this makes the
      // underlying set() call throw so we can exercise the try/catch.
      await expectLater(
        repository.markAsRead('bad/id', 'u1'),
        completes,
      );
    });

    test('reaches the catch block and swallows the error (via a mocktail-'
        'forced set() failure) when the underlying write throws', () async {
      // Unlike the invalid-doc-id case above, this deterministically forces
      // the write itself to throw by mocking the Firestore layer directly,
      // so we know for certain the try/catch's debugPrint branch runs.
      final mockFirestore = MockFirebaseFirestore();
      final chatsCollection = MockCollectionReference();
      final chatDoc = MockDocumentReference();
      when(() => mockFirestore.collection('chats')).thenReturn(chatsCollection);
      when(() => chatsCollection.doc('chat-1')).thenReturn(chatDoc);
      when(() => chatDoc.set(any(), any())).thenThrow(Exception('forced set failure'));

      final repo = ChatRepositoryImpl(db: mockFirestore, storage: MockFirebaseStorage());

      await expectLater(
        repo.markAsRead('chat-1', 'u1'),
        completes,
      );

      verify(() => chatDoc.set(any(), any())).called(1);
    });
  });

  group('ChatRepositoryImpl.togglePin', () {
    late FakeFirebaseFirestore firestore;
    late ChatRepositoryImpl repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = ChatRepositoryImpl(db: firestore, storage: MockFirebaseStorage());
    });

    test('pin=true adds the userId to pinnedBy', () async {
      await firestore.collection('chats').doc('chat-1').set({'pinnedBy': <String>[]});

      await repository.togglePin('chat-1', 'u1', true);

      final doc = await firestore.collection('chats').doc('chat-1').get();
      expect(doc.data()!['pinnedBy'], ['u1']);
    });

    test('pin=true does not duplicate an already-pinned userId', () async {
      await firestore.collection('chats').doc('chat-1').set({'pinnedBy': ['u1']});

      await repository.togglePin('chat-1', 'u1', true);

      final doc = await firestore.collection('chats').doc('chat-1').get();
      expect(doc.data()!['pinnedBy'], ['u1']);
    });

    test('pin=false removes the userId from pinnedBy', () async {
      await firestore.collection('chats').doc('chat-1').set({'pinnedBy': ['u1', 'u2']});

      await repository.togglePin('chat-1', 'u1', false);

      final doc = await firestore.collection('chats').doc('chat-1').get();
      expect(doc.data()!['pinnedBy'], ['u2']);
    });
  });

  group('ChatRepositoryImpl.ensureChatExists', () {
    late FakeFirebaseFirestore firestore;
    late ChatRepositoryImpl repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = ChatRepositoryImpl(db: firestore, storage: MockFirebaseStorage());
    });

    test('sets groupTitle when provided', () async {
      await repository.ensureChatExists(
        chatId: 'chat-1',
        participantIds: ['u1', 'u2'],
        participantNames: {'u1': 'Alice', 'u2': 'Bob'},
        type: 'group',
        groupTitle: 'Trip Chat',
      );

      final doc = await firestore.collection('chats').doc('chat-1').get();
      final data = doc.data()!;
      expect(data['groupTitle'], 'Trip Chat');
      expect(data['type'], 'group');
      expect(List<String>.from(data['participants']), containsAll(['u1', 'u2']));
      expect(data['participantNames'], {'u1': 'Alice', 'u2': 'Bob'});
    });

    test('does not set groupTitle when absent', () async {
      await repository.ensureChatExists(
        chatId: 'chat-2',
        participantIds: ['u1'],
        participantNames: {'u1': 'Alice'},
      );

      final doc = await firestore.collection('chats').doc('chat-2').get();
      final data = doc.data()!;
      expect(data.containsKey('groupTitle'), isFalse);
      expect(data['type'], 'private');
    });

    test('applies default type and empty participantPhotos when omitted', () async {
      await repository.ensureChatExists(
        chatId: 'chat-3',
        participantIds: ['u1'],
        participantNames: {'u1': 'Alice'},
      );

      final doc = await firestore.collection('chats').doc('chat-3').get();
      final data = doc.data()!;
      expect(data['type'], 'private');
      expect(data['participantPhotos'], isEmpty);
    });

    test('merges participantIds with any already-stored participants (arrayUnion)', () async {
      await firestore.collection('chats').doc('chat-1').set({
        'participants': ['u1'],
      });

      await repository.ensureChatExists(
        chatId: 'chat-1',
        participantIds: ['u2'],
        participantNames: {'u2': 'Bob'},
      );

      final doc = await firestore.collection('chats').doc('chat-1').get();
      expect(List<String>.from(doc.data()!['participants']), containsAll(['u1', 'u2']));
    });
  });

  group('ChatRepositoryImpl.uploadAudio', () {
    late MockFirebaseStorage storage;
    late ChatRepositoryImpl repository;
    late Directory tempDir;

    setUp(() async {
      storage = MockFirebaseStorage();
      repository = ChatRepositoryImpl(
        db: FakeFirebaseFirestore(),
        storage: storage,
      );
      tempDir = await Directory.systemTemp.createTemp('chat_repo_test');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('throws when the audio file does not exist', () async {
      final missingFile = File('${tempDir.path}/does_not_exist.m4a');

      await expectLater(
        repository.uploadAudio(missingFile),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('does not exist'),
        )),
      );
    });

    test('throws when the audio file is empty', () async {
      final emptyFile = File('${tempDir.path}/empty.m4a');
      await emptyFile.create();

      await expectLater(
        repository.uploadAudio(emptyFile),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('empty'),
        )),
      );
    });

    test('uploads a non-empty file and returns the download URL', () async {
      final audioFile = File('${tempDir.path}/audio.m4a');
      await audioFile.writeAsBytes([1, 2, 3, 4]);

      final rootRef = MockReference();
      final audioFolderRef = MockReference();
      final fileRef = MockReference();
      final snapshot = MockTaskSnapshot();
      final downloadRef = MockReference();

      when(() => storage.ref()).thenReturn(rootRef);
      when(() => rootRef.child('chat_audio')).thenReturn(audioFolderRef);
      when(() => audioFolderRef.child(any())).thenReturn(fileRef);
      when(() => fileRef.fullPath).thenReturn('chat_audio/audio.m4a');
      when(() => fileRef.putFile(any(), any()))
          .thenAnswer((_) => FakeUploadTask(Future.value(snapshot)));
      when(() => snapshot.bytesTransferred).thenReturn(4);
      when(() => snapshot.ref).thenReturn(downloadRef);
      when(() => downloadRef.getDownloadURL())
          .thenAnswer((_) async => 'https://example.com/audio.m4a');

      final url = await repository.uploadAudio(audioFile);

      expect(url, 'https://example.com/audio.m4a');
      verify(() => fileRef.putFile(audioFile, any())).called(1);
    });

    test('maps an "object-not-found" upload failure to a friendlier message', () async {
      final audioFile = File('${tempDir.path}/audio.m4a');
      await audioFile.writeAsBytes([1, 2, 3, 4]);

      final rootRef = MockReference();
      final audioFolderRef = MockReference();
      final fileRef = MockReference();

      when(() => storage.ref()).thenReturn(rootRef);
      when(() => rootRef.child('chat_audio')).thenReturn(audioFolderRef);
      when(() => audioFolderRef.child(any())).thenReturn(fileRef);
      when(() => fileRef.fullPath).thenReturn('chat_audio/audio.m4a');
      when(() => fileRef.putFile(any(), any())).thenAnswer(
        (_) => FakeUploadTask(Future<TaskSnapshot>.error(
          Exception('object-not-found: no object exists'),
        )),
      );

      await expectLater(
        repository.uploadAudio(audioFile),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Storage Error'),
        )),
      );
    });

    test('rethrows other upload failures unchanged', () async {
      final audioFile = File('${tempDir.path}/audio.m4a');
      await audioFile.writeAsBytes([1, 2, 3, 4]);

      final rootRef = MockReference();
      final audioFolderRef = MockReference();
      final fileRef = MockReference();

      when(() => storage.ref()).thenReturn(rootRef);
      when(() => rootRef.child('chat_audio')).thenReturn(audioFolderRef);
      when(() => audioFolderRef.child(any())).thenReturn(fileRef);
      when(() => fileRef.fullPath).thenReturn('chat_audio/audio.m4a');
      when(() => fileRef.putFile(any(), any())).thenAnswer(
        (_) => FakeUploadTask(Future<TaskSnapshot>.error(Exception('network down'))),
      );

      await expectLater(
        repository.uploadAudio(audioFile),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('network down'),
        )),
      );
    });
  });
}
