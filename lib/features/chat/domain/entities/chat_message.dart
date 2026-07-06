class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime? timestamp;
  final String? senderName;
  final int reactionCount;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    this.timestamp,
    this.senderName,
    this.reactionCount = 0,
  });
}
