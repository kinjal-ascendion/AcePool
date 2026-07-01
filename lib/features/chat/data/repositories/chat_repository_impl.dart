import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_room.dart';
import '../../domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'acepool',
  );

  @override
  Stream<List<ChatRoom>> getChatRooms(String userId) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return ChatRoom(
                id: doc.id,
                lastMessage: data['lastMessage'] ?? '',
                lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
                participants: List<String>.from(data['participants'] ?? []),
                participantNames: Map<String, String>.from(data['participantNames'] ?? {}),
              );
            }).toList());
  }

  @override
  Stream<List<ChatMessage>> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return ChatMessage(
                id: doc.id,
                senderId: data['senderId'] ?? '',
                receiverId: data['receiverId'] ?? '',
                text: data['text'] ?? '',
                timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
              );
            }).toList());
  }

  @override
  Future<void> sendMessage(String chatId, ChatMessage message, String senderName, String receiverName) async {
    final now = FieldValue.serverTimestamp();
    final batch = _db.batch();
    final chatRef = _db.collection('chats').doc(chatId);

    batch.set(chatRef, {
      'lastMessage': message.text,
      'lastMessageTime': now,
      'participants': [message.senderId, message.receiverId],
      'participantNames': {
        message.senderId: senderName,
        message.receiverId: receiverName,
      }
    }, SetOptions(merge: true));

    final messageRef = chatRef.collection('messages').doc();
    batch.set(messageRef, {
      'senderId': message.senderId,
      'receiverId': message.receiverId,
      'text': message.text,
      'timestamp': now,
    });

    await batch.commit();
  }
}
