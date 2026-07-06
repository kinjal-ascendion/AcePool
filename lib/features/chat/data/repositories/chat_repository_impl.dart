import 'package:acepool/features/chat/domain/entities/chat_message.dart';
import 'package:acepool/features/chat/domain/entities/chat_room.dart';
import 'package:acepool/features/chat/domain/repositories/chat_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class ChatRepositoryImpl implements ChatRepository {
  final _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'acepool',
  );

  @override
  Stream<List<ChatRoom>> getChatRooms(String userId) {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);

    return _db
        .collection('chats')
        .where('participants', arrayContains: userId)
        .where('rideDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              
              // Handle unread counts safely
              final Map<String, int> unreadCounts = {};
              if (data['unreadCounts'] != null && data['unreadCounts'] is Map) {
                (data['unreadCounts'] as Map).forEach((key, value) {
                  unreadCounts[key.toString()] = (value as num).toInt();
                });
              }

              return ChatRoom(
                id: doc.id,
                lastMessage: data['lastMessage'] ?? '',
                lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
                participants: List<String>.from(data['participants'] ?? []),
                participantNames: Map<String, String>.from(data['participantNames'] ?? {}),
                participantPhotos: Map<String, String>.from(data['participantPhotos'] ?? {}),
                unreadCounts: unreadCounts,
                pinnedBy: List<String>.from(data['pinnedBy'] ?? []),
                type: data['type'] ?? 'private',
                groupTitle: data['groupTitle'],
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
                senderName: data['senderName'],
                reactionCount: (data['reactionCount'] as num?)?.toInt() ?? 0,
              );
            }).toList());
  }

  @override
  Future<void> sendMessage(String chatId, ChatMessage message, String senderName, String receiverName) async {
    final now = FieldValue.serverTimestamp();
    final chatRef = _db.collection('chats').doc(chatId);

    // Get current chat to know participants
    final chatDoc = await chatRef.get();
    List<String> participants;
    
    if (chatDoc.exists) {
      participants = List<String>.from(chatDoc.data()?['participants'] ?? []);
    } else {
      participants = [message.senderId];
      if (message.receiverId != 'group') {
        participants.add(message.receiverId);
      }
    }

    // Prepare unread counts map for merging
    final Map<String, dynamic> unreadUpdates = {};
    for (final pId in participants) {
      if (pId != message.senderId) {
        unreadUpdates[pId] = FieldValue.increment(1);
      }
    }

    final Map<String, dynamic> updateData = {
      'lastMessage': message.text,
      'lastMessageTime': now,
      'participants': FieldValue.arrayUnion(participants),
      'unreadCounts': unreadUpdates,
      'rideDate': message.timestamp != null ? Timestamp.fromDate(message.timestamp!) : now,
    };

    if (message.receiverId == 'group') {
      updateData['type'] = 'group';
      // Use set with merge to avoid overwriting the whole participantNames map
      await chatRef.set({
        'participantNames': { message.senderId: senderName }
      }, SetOptions(merge: true));
    } else {
      updateData['type'] = 'private';
      updateData['participantNames'] = {
        message.senderId: senderName,
        message.receiverId: receiverName,
      };
    }

    final batch = _db.batch();
    batch.set(chatRef, updateData, SetOptions(merge: true));

    final messageRef = chatRef.collection('messages').doc();
    batch.set(messageRef, {
      'senderId': message.senderId,
      'receiverId': message.receiverId,
      'text': message.text,
      'timestamp': now,
      'senderName': senderName,
    });

    await batch.commit();
  }

  @override
  Future<void> markAsRead(String chatId, String userId) async {
    try {
      // Using set with merge to target the specific key in the map
      await _db.collection('chats').doc(chatId).set({
        'unreadCounts': { userId: 0 }
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  @override
  Future<void> togglePin(String chatId, String userId, bool pin) async {
    if (pin) {
      await _db.collection('chats').doc(chatId).update({
        'pinnedBy': FieldValue.arrayUnion([userId]),
      });
    } else {
      await _db.collection('chats').doc(chatId).update({
        'pinnedBy': FieldValue.arrayRemove([userId]),
      });
    }
  }
}
