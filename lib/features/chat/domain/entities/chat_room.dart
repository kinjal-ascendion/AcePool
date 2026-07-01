class ChatRoom {
  final String id;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final List<String> participants;
  final Map<String, String> participantNames;

  ChatRoom({
    required this.id,
    required this.lastMessage,
    this.lastMessageTime,
    required this.participants,
    required this.participantNames,
  });
}
