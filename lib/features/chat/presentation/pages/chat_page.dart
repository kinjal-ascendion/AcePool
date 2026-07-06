import 'package:acepool/di/injection.dart';
import 'package:acepool/features/chat/domain/repositories/chat_repository.dart';
import 'package:acepool/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final String title;
  final String? subtitle;
  final List<String>? profileImages;
  final Map<String, String>? participantNames; // Added to show initials
  final String? receiverId;
  final String? receiverName;

  const ChatPage({
    super.key,
    required this.chatId,
    required this.title,
    this.subtitle,
    this.profileImages,
    this.participantNames,
    this.receiverId,
    this.receiverName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  bool _showSuggestions = true;

  final List<String> _suggestedReplies = [
    "Reschedule the ride",
    "Change pickup point",
    "Running late",
    "Confirm my seat",
  ];

  @override
  void initState() {
    super.initState();
    if (_currentUserId != null) {
      sl<ChatRepository>().markAsRead(widget.chatId, _currentUserId!);
    }
  }

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
      receiverId: widget.receiverId ?? 'group',
      senderName: FirebaseAuth.instance.currentUser?.displayName ?? 'User',
      receiverName: widget.receiverName ?? 'Group',
    ));
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) return const Scaffold(body: Center(child: Text('Please log in')));

    return BlocProvider(
      create: (context) => sl<ChatBloc>()..add(ChatMessagesSubscriptionRequested(widget.chatId)),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
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
                  style: const TextStyle(color: Colors.black54, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          actions: [
            _buildAvatarStack(),
          ],
        ),
        body: Column(
          children: [
            // Date Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Today',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ),
              ),
            ),
            
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state.status == ChatStatus.loading) return const Center(child: CircularProgressIndicator());
                  
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final msg = state.messages[index];
                      final isMe = msg.senderId == _currentUserId;
                      return _MessageBubble(
                        text: msg.text,
                        isMe: isMe,
                        time: msg.timestamp,
                        senderName: isMe ? null : msg.senderName,
                        reactionCount: msg.reactionCount,
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

  Widget _buildAvatarStack() {
    final List<String> names = widget.participantNames?.values.toList() ?? [];
    final List<String> photos = widget.profileImages ?? [];
    final int count = names.isNotEmpty ? names.length : photos.length;
    
    if (count == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: SizedBox(
        width: 80,
        child: Stack(
          alignment: Alignment.centerRight,
          children: [
            if (count > 3)
              Positioned(
                right: 0,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.grey.shade300,
                  child: Text(
                    '+${count - 3}',
                    style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ...List.generate(
              count > 3 ? 3 : count,
              (index) {
                final reverseIndex = (count > 3 ? 3 : count) - 1 - index;
                final offset = (count > 3 ? index + 1 : index) * 16.0;
                
                String? photoUrl;
                if (photos.length > reverseIndex) photoUrl = photos[reverseIndex];
                
                String initial = '?';
                if (names.length > reverseIndex && names[reverseIndex].isNotEmpty) {
                  initial = names[reverseIndex][0].toUpperCase();
                }

                return Positioned(
                  right: offset,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 13,
                      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                      backgroundColor: _getAvatarColor(index),
                      child: photoUrl == null ? Text(initial, style: const TextStyle(fontSize: 12, color: Colors.white)) : null,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getAvatarColor(int index) {
    const colors = [Colors.purple, Colors.orange, Colors.blue, Colors.green];
    return colors[index % colors.length];
  }

  Widget _buildBottomPanel(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showSuggestions) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                ]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'SUGGESTED REPLIES',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _showSuggestions = false),
                        child: const Icon(Icons.close, size: 16, color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (ctx) => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _suggestedReplies.map((reply) => GestureDetector(
                        onTap: () => _sendTextMessage(reply, ctx),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.grey.shade600, Colors.grey.shade800],
                            ),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Text(
                            reply,
                            style: const TextStyle(fontSize: 13, color: Colors.white),
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Input field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onSubmitted: (v) => _sendTextMessage(v, context),
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const Icon(Icons.mic_none_rounded, color: Colors.grey, size: 22),
                  const SizedBox(width: 12),
                  Builder(
                    builder: (ctx) => GestureDetector(
                      onTap: () => _sendTextMessage(_messageController.text, ctx),
                      child: const Icon(Icons.send_rounded, color: Color(0xFF1B8A3F), size: 22),
                    ),
                  ),
                ],
              ),
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
  final int reactionCount;

  const _MessageBubble({
    required this.text,
    required this.isMe,
    this.time,
    this.senderName,
    this.reactionCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe)
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, color: Colors.white, size: 16),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        senderName ?? 'User',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(time),
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                if (isMe)
                  Text(
                    _formatTime(time),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                const SizedBox(height: 4),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isMe ? const Color(0xFFE8F5E9) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: isMe ? null : Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        text,
                        style: const TextStyle(color: Colors.black87, fontSize: 14),
                      ),
                    ),
                    if (reactionCount > 0)
                      Positioned(
                        bottom: -12,
                        left: isMe ? null : 12,
                        right: isMe ? 12 : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade100),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.thumb_up, size: 12, color: Color(0xFF1B8A3F)),
                              const SizedBox(width: 4),
                              Text(
                                '$reactionCount',
                                style: const TextStyle(fontSize: 10, color: Color(0xFF1B8A3F), fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'pm' : 'am';
    return "$hour:$minute $period";
  }
}
