import 'package:acepool/di/injection.dart';
import 'package:acepool/features/chat/presentation/bloc/chat_list_bloc.dart';
import 'package:acepool/features/chat/presentation/pages/chat_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Please log in'));

    return BlocProvider(
      create: (context) => sl<ChatListBloc>()..add(ChatListSubscriptionRequested(uid)),
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Chats',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
        body: BlocBuilder<ChatListBloc, ChatListState>(
          builder: (context, state) {
            if (state.status == ChatListStatus.failure) {
              return Center(child: Text('Error: ${state.errorMessage}'));
            }
            if (state.status == ChatListStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.rooms.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text(
                      'No conversations yet',
                      style: TextStyle(color: Colors.black45),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.rooms.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
              final room = state.rooms[index];
              final isGroup = room.type == 'group';
              
              String displayName;
              String otherId = '';
              String? subtitle;
              List<String> photos = [];
              
              if (isGroup) {
                displayName = room.groupTitle ?? 'Group Chat';
                final names = room.participantNames.values.toList();
                subtitle = names.join(', ');
                photos = room.participantPhotos.values.toList();
              } else {
                // Find the other participant's name
                otherId = room.participants.firstWhere(
                  (id) => id != uid,
                  orElse: () => '',
                );
                displayName = room.participantNames[otherId] ?? 'User';
                subtitle = null;
                final photo = room.participantPhotos[otherId];
                photos = photo != null ? [photo] : [];
              }
              
              final lastTime = room.lastMessageTime;

              return ListTile(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatPage(
                        chatId: room.id,
                        title: displayName,
                        subtitle: subtitle,
                        profileImages: photos,
                        receiverId: isGroup ? null : otherId,
                        receiverName: isGroup ? null : displayName,
                      ),
                    ),
                  );
                },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  leading: CircleAvatar(
                    backgroundColor: isGroup ? Colors.blue.shade100 : Colors.grey.shade200,
                    child: isGroup 
                      ? const Icon(Icons.group, color: Colors.blue)
                      : Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : '?'),
                  ),
                  title: Text(
                    displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    room.lastMessage.isEmpty ? 'No messages yet' : room.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                trailing: lastTime != null
                    ? Text(
                        _formatDate(lastTime),
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      )
                    : null,
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return "$hour:$minute $period";
    }
    return "${date.day}/${date.month}";
  }
}
