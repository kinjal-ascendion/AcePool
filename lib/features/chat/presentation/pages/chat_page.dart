import 'package:acepool/di/injection.dart';
import 'package:acepool/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final String title;
  final String? subtitle;
  final List<String>? profileImages;
  final String? receiverId; // Null for group chats
  final String? receiverName; // Null for group chats

  const ChatPage({
    super.key,
    required this.chatId,
    required this.title,
    this.subtitle,
    this.profileImages,
    this.receiverId,
    this.receiverName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  final List<String> _suggestedReplies = [
    "Reschedule the ride",
    "Change pickup point",
    "Running late",
    "Confirm my seat",
    "I'm here",
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendTextMessage(String text, BuildContext context) {
    if (text.isEmpty || _currentUserId == null) return;
    
    context.read<ChatBloc>().add(ChatMessageSent(
      chatId: widget.chatId,
      text: text,
      senderId: _currentUserId!,
      receiverId: widget.receiverId ?? 'group', // Use 'group' if no specific receiver
      senderName: FirebaseAuth.instance.currentUser?.displayName ?? 'User',
      receiverName: widget.receiverName ?? 'Group',
    ));
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    return BlocProvider(
      create: (context) => sl<ChatBloc>()..add(ChatMessagesSubscriptionRequested(widget.chatId)),
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (widget.subtitle != null)
                Text(
                  widget.subtitle!,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
            ],
          ),
          actions: [
            if (widget.profileImages != null && widget.profileImages!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 60,
                  child: Stack(
                    alignment: Alignment.centerRight,
                    children: List.generate(
                      widget.profileImages!.length > 3 ? 3 : widget.profileImages!.length,
                      (index) => Positioned(
                        right: index * 15.0,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 12,
                            backgroundImage: NetworkImage(widget.profileImages![index]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state.status == ChatStatus.failure) {
                    return Center(child: Text('Error: ${state.errorMessage}'));
                  }
                  if (state.status == ChatStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text('No messages yet. Say hello!', style: TextStyle(color: Colors.black45)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final msg = state.messages[index];
                      final isMe = msg.senderId == _currentUserId;
                      return _MessageBubble(
                        text: msg.text,
                        isMe: isMe,
                        time: msg.timestamp,
                        senderName: isMe ? null : msg.senderName,
                      );
                    },
                  );
                },
              ),
            ),
            _buildBottomPanel(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Suggested Replies
          Builder(
            builder: (ctx) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: _suggestedReplies.map((reply) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(reply, style: const TextStyle(fontSize: 12, color: Colors.white)),
                    backgroundColor: Colors.grey.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onPressed: () => _sendTextMessage(reply, ctx),
                  ),
                )).toList(),
              ),
            ),
          ),
          
          // Input field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Builder(
                  builder: (ctx) => GestureDetector(
                    onTap: () => _sendTextMessage(_messageController.text, ctx),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(color: Color(0xFF1B8A3F), shape: BoxShape.circle),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final DateTime? time;
  final String? senderName;

  const _MessageBubble({required this.text, required this.isMe, this.time, this.senderName});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe && senderName != null)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 2),
              child: Text(
                senderName!,
                style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.bold),
              ),
            ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFF1B8A3F) : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 16),
              ),
              boxShadow: [if (!isMe) const BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(text, style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
                if (time != null)
                  Text(
                    "${time!.hour}:${time!.minute.toString().padLeft(2, '0')}",
                    style: TextStyle(color: isMe ? Colors.white70 : Colors.black38, fontSize: 10),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
