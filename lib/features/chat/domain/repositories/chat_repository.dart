import 'dart:io';
import '../entities/chat_message.dart';
import '../entities/chat_room.dart';

abstract class ChatRepository {
  Stream<List<ChatRoom>> getChatRooms(String userId);
  Stream<List<ChatMessage>> getMessages(String chatId);
  Future<void> sendMessage(String chatId, ChatMessage message, String senderName, String receiverName);
  Future<void> markAsRead(String chatId, String userId);
  Future<void> togglePin(String chatId, String userId, bool pin);
  Future<String> uploadAudio(File audioFile);
  Future<void> ensureChatExists({
    required String chatId,
    required List<String> participantIds,
    required Map<String, String> participantNames,
    Map<String, String> participantPhotos,
    String type,
    String? groupTitle,
  });
}
