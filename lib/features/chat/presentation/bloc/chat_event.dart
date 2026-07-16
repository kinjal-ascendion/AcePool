part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class ChatMessagesSubscriptionRequested extends ChatEvent {
  final String chatId;
  const ChatMessagesSubscriptionRequested(this.chatId);
  @override
  List<Object?> get props => [chatId];
}

class ChatMessagesUpdated extends ChatEvent {
  final List<ChatMessage> messages;
  const ChatMessagesUpdated(this.messages);
  @override
  List<Object?> get props => [messages];
}

class ChatMessageSent extends ChatEvent {
  final String chatId;
  final String text;
  final String? audioUrl;
  final MessageType type;
  final String senderId;
  final String receiverId;
  final String senderName;
  final String receiverName;

  const ChatMessageSent({
    required this.chatId,
    required this.text,
    this.audioUrl,
    this.type = MessageType.text,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    required this.receiverName,
  });
  @override
  List<Object?> get props => [chatId, text, audioUrl, type, senderId, receiverId, senderName, receiverName];
}
