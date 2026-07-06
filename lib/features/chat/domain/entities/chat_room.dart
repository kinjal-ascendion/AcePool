class ChatRoom {
  final String id;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String> participantPhotos;
  final Map<String, int> unreadCounts;
  final List<String> pinnedBy;
  final String type; // 'private' or 'group'
  final String? groupTitle;

  ChatRoom({
    required this.id,
    required this.lastMessage,
    this.lastMessageTime,
    required this.participants,
    required this.participantNames,
    this.participantPhotos = const {},
    this.unreadCounts = const {},
    this.pinnedBy = const [],
    this.type = 'private',
    this.groupTitle,
  });

  bool isPinned(String userId) => pinnedBy.contains(userId);
  int getUnreadCount(String userId) => unreadCounts[userId] ?? 0;
}
