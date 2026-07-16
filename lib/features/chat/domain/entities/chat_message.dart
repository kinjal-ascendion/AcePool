enum MessageType { text, audio }

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final String? audioUrl;
  final MessageType type;
  final DateTime? timestamp;
  final String? senderName;
  final int reactionCount;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    this.audioUrl,
    this.type = MessageType.text,
    this.timestamp,
    this.senderName,
    this.reactionCount = 0,
  });
}
