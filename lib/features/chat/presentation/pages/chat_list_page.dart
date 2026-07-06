import 'package:acepool/di/injection.dart';
import 'package:acepool/features/chat/domain/repositories/chat_repository.dart';
import 'package:acepool/features/chat/presentation/bloc/chat_list_bloc.dart';
import 'package:acepool/features/chat/presentation/pages/chat_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatListPage extends StatefulWidget {
  final VoidCallback? onBack;
  const ChatListPage({super.key, this.onBack});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Please log in'));

    return BlocProvider(
      create: (context) => sl<ChatListBloc>()..add(ChatListSubscriptionRequested(uid)),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Chats',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.add, color: Colors.black, size: 20),
                  onPressed: () {},
                ),
              ),
            )
          ],
        ),
        body: BlocBuilder<ChatListBloc, ChatListState>(
          builder: (context, state) {
            return Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (query) => context.read<ChatListBloc>().add(ChatSearchQueryChanged(query)),
                      decoration: const InputDecoration(
                        hintText: 'Search Chat',
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                
                // Filter Chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All', 
                        isSelected: state.filter == ChatFilter.all,
                        onTap: () => context.read<ChatListBloc>().add(const ChatFilterChanged(ChatFilter.all)),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Unread', 
                        isSelected: state.filter == ChatFilter.unread,
                        onTap: () => context.read<ChatListBloc>().add(const ChatFilterChanged(ChatFilter.unread)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, size: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                // Archived
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.archive_outlined, color: Colors.grey, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Archived',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const Divider(indent: 16, endIndent: 16),

                // Chat List
                Expanded(
                  child: _buildChatList(context, state, uid),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildChatList(BuildContext context, ChatListState state, String uid) {
    if (state.status == ChatListStatus.failure) {
      return Center(child: Text('Error: ${state.errorMessage}'));
    }
    if (state.status == ChatListStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.rooms.isEmpty) {
      return const Center(child: Text('No active conversations'));
    }

    // Filter by Unread if active
    var displayedRooms = state.rooms;
    if (state.filter == ChatFilter.unread) {
      displayedRooms = state.rooms.where((room) => room.getUnreadCount(uid) > 0).toList();
    }

    // Filter by Search Query
    if (state.searchQuery.trim().isNotEmpty) {
      final query = state.searchQuery.trim().toLowerCase();
      displayedRooms = displayedRooms.where((room) {
        final isGroup = room.type == 'group';
        if (isGroup) {
          final groupTitle = (room.groupTitle ?? '').toLowerCase();
          final participantNames = room.participantNames.values.join(' ').toLowerCase();
          return groupTitle.contains(query) || participantNames.contains(query);
        } else {
          final otherId = room.participants.firstWhere((id) => id != uid, orElse: () => '');
          final otherName = (room.participantNames[otherId] ?? '').toLowerCase();
          return otherName.contains(query);
        }
      }).toList();
    }

    if (displayedRooms.isEmpty) {
      if (state.filter == ChatFilter.unread) {
        return const Center(child: Text('No unread messages'));
      } else if (state.searchQuery.isNotEmpty) {
        return const Center(child: Text('No results found'));
      }
      return const Center(child: Text('No active conversations'));
    }

    final sortedRooms = List.of(displayedRooms)
      ..sort((a, b) {
        final aPinned = a.isPinned(uid);
        final bPinned = b.isPinned(uid);
        if (aPinned && !bPinned) return -1;
        if (!aPinned && bPinned) return 1;
        
        final aTime = a.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

    return ListView.builder(
      itemCount: sortedRooms.length,
      itemBuilder: (context, index) {
        final room = sortedRooms[index];
        final isGroup = room.type == 'group';
        
        String displayName;
        String otherId = '';
        String? subtitleStr;
        List<String> photos = [];
        
        if (isGroup) {
          displayName = room.groupTitle ?? 'Group Chat';
          final names = room.participantNames.entries
              .map((e) => e.key == uid ? "You" : e.value)
              .toList();
          subtitleStr = names.join(', ');
          photos = room.participantPhotos.values.toList();
        } else {
          otherId = room.participants.firstWhere((id) => id != uid, orElse: () => '');
          displayName = room.participantNames[otherId] ?? 'User';
          subtitleStr = null;
          final photo = room.participantPhotos[otherId];
          photos = photo != null ? [photo] : [];
        }
        
        return _ChatListItem(
          room: room,
          displayName: displayName,
          subtitle: subtitleStr,
          isGroup: isGroup,
          userId: uid,
          onTap: () {
            sl<ChatRepository>().markAsRead(room.id, uid);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatPage(
                  chatId: room.id,
                  title: displayName,
                  subtitle: subtitleStr,
                  profileImages: photos,
                  participantNames: room.participantNames,
                  receiverId: isGroup ? null : otherId,
                  receiverName: isGroup ? null : displayName,
                ),
              ),
            );
          },
          onLongPress: () {
            final isPinned = room.isPinned(uid);
            sl<ChatRepository>().togglePin(room.id, uid, !isPinned);
          },
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF1B8A3F) : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final dynamic room;
  final String displayName;
  final String? subtitle;
  final bool isGroup;
  final String userId;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ChatListItem({
    required this.room,
    required this.displayName,
    this.subtitle,
    required this.isGroup,
    required this.userId,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final unreadCount = room.getUnreadCount(userId);
    final isPinned = room.isPinned(userId);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey.shade200,
                  child: isGroup 
                    ? Image.asset('assets/images/group.png', width: 30, height: 30, color: Colors.grey)
                    : const Icon(Icons.person, color: Colors.grey, size: 30),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset('assets/images/timer.png', width: 14, height: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    room.lastMessage.isEmpty ? 'No messages yet' : room.lastMessage,
                    style: TextStyle(
                      color: unreadCount > 0 ? const Color(0xFF1B8A3F) : Colors.grey.shade600, 
                      fontSize: 14,
                      fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatDate(room.lastMessageTime),
                  style: TextStyle(
                    color: unreadCount > 0 ? const Color(0xFF1B8A3F) : Colors.grey.shade500,
                    fontSize: 12, 
                    fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (isPinned)
                      const Icon(Icons.push_pin, size: 14, color: Colors.grey),
                    if (isPinned && unreadCount > 0)
                      const SizedBox(width: 4),
                    if (unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1B8A3F),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    }
    return "Yesterday";
  }
}
