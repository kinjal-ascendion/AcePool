import 'dart:io';
import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/di/injection.dart';
import 'package:acepool/features/chat/domain/entities/chat_message.dart';
import 'package:acepool/features/chat/domain/repositories/chat_repository.dart';
import 'package:acepool/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'dart:async';

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
  
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isUploading = false;
  String? _audioPath;

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
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      debugPrint('Attempting to start recording...');
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        debugPrint('Recording to: $path');
        const config = RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 22050,
        );
        
        await _audioRecorder.start(config, path: path);
        
        setState(() {
          _isRecording = true;
          _audioPath = path;
        });
        debugPrint('Recording started');
      } else {
        debugPrint('Microphone permission denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission is required')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording(BuildContext context) async {
    try {
      debugPrint('Stopping recording...');
      final isRecording = await _audioRecorder.isRecording();
      if (!isRecording) {
        debugPrint('Not recording, ignoring stop call');
        setState(() => _isRecording = false);
        return;
      }

      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _isUploading = true;
      });
      
      if (path != null && _currentUserId != null) {
        debugPrint('Recording stopped, path: $path');
        
        final bloc = context.read<ChatBloc>();
        final chatRepo = sl<ChatRepository>();
        
        final audioFile = File(path);
        debugPrint('Uploading audio file...');
        final audioUrl = await chatRepo.uploadAudio(audioFile);
        debugPrint('Audio uploaded, URL: $audioUrl');
        
        bloc.add(ChatMessageSent(
          chatId: widget.chatId,
          text: 'Audio message',
          audioUrl: audioUrl,
          type: MessageType.audio,
          senderId: _currentUserId!,
          receiverId: widget.receiverId ?? 'group',
          senderName: FirebaseAuth.instance.currentUser?.displayName ?? 'User',
          receiverName: widget.receiverName ?? 'Group',
        ));
      } else {
        debugPrint('Recording stopped but path is null or userId is null');
      }
    } catch (e) {
      debugPrint('Error in _stopRecording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send audio: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
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
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.scaffoldBackground,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(color: AppColors.black, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (widget.subtitle != null)
                  Text(
                    widget.subtitle!,
                    style: const TextStyle(color: AppColors.black54, fontSize: 11),
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
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Today',
                      style: TextStyle(color: AppColors.black54, fontSize: 12),
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
                          audioUrl: msg.audioUrl,
                          type: msg.type,
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
                  backgroundColor: AppColors.grey300,
                  child: Text(
                    '+${count - 3}',
                    style: const TextStyle(fontSize: 10, color: AppColors.black54, fontWeight: FontWeight.bold),
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
                      border: Border.all(color: AppColors.white, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 13,
                      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                      backgroundColor: _getAvatarColor(index),
                      child: photoUrl == null ? Text(initial, style: const TextStyle(fontSize: 12, color: AppColors.white)) : null,
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
    const colors = [AppColors.purple, AppColors.orange, AppColors.blue, AppColors.green];
    return colors[index % colors.length];
  }

  Widget _buildBottomPanel(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showSuggestions) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.grey200),
                boxShadow: [
                  BoxShadow(color: AppColors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
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
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.black54),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _showSuggestions = false),
                        child: const Icon(Icons.close, size: 16, color: AppColors.black54),
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
                              colors: [AppColors.grey600, AppColors.grey800],
                            ),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Text(
                            reply,
                            style: const TextStyle(fontSize: 13, color: AppColors.white),
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
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  /* if (_isRecording)
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Recording audio...',
                          style: TextStyle(color: AppColors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  else if (_isUploading)
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Sending voice message...',
                          style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  else */
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
                  /* GestureDetector(
                    onLongPress: _startRecording,
                    onLongPressUp: () => _stopRecording(context),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Hold to record voice message'), duration: Duration(seconds: 1)),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        _isRecording ? Icons.mic : Icons.mic_none_rounded,
                        color: _isRecording ? AppColors.red : AppColors.grey,
                        size: 24,
                      ),
                    ),
                  ), */
                  const SizedBox(width: 12),
                  Builder(
                    builder: (ctx) => GestureDetector(
                      onTap: () => _sendTextMessage(_messageController.text, ctx),
                      child: const Icon(Icons.send_rounded, color: AppColors.primaryGreen, size: 22),
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
  final String? audioUrl;
  final MessageType type;
  final bool isMe;
  final DateTime? time;
  final String? senderName;
  final int reactionCount;

  const _MessageBubble({
    required this.text,
    this.audioUrl,
    this.type = MessageType.text,
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
              backgroundColor: AppColors.grey,
              child: Icon(Icons.person, color: AppColors.white, size: 16),
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
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.grey),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(time),
                        style: const TextStyle(fontSize: 11, color: AppColors.grey),
                      ),
                    ],
                  ),
                if (isMe)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(time),
                        style: const TextStyle(fontSize: 11, color: AppColors.grey),
                      ),
                    ],
                  ),
                const SizedBox(height: 4),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: type == MessageType.audio 
                          ? const EdgeInsets.symmetric(vertical: 8, horizontal: 12)
                          : const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isMe ? AppColors.chatBubbleMe : AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: isMe ? null : Border.all(color: AppColors.grey200),
                      ),
                      child: type == MessageType.audio
                          ? _AudioPlayerWidget(url: audioUrl!, isMe: isMe)
                          : Text(
                              text,
                              style: const TextStyle(color: AppColors.black87, fontSize: 14),
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
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.grey100),
                            boxShadow: [
                              BoxShadow(color: AppColors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.thumb_up, size: 12, color: AppColors.primaryGreen),
                              const SizedBox(width: 4),
                              Text(
                                '$reactionCount',
                                style: const TextStyle(fontSize: 10, color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
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

class _AudioPlayerWidget extends StatefulWidget {
  final String url;
  final bool isMe;

  const _AudioPlayerWidget({required this.url, required this.isMe});

  @override
  State<_AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<_AudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onLog.listen((msg) => debugPrint('AudioPlayer Log: $msg'));
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) {
        setState(() => _duration = d);
      }
    });
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) {
        setState(() => _position = p);
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            if (_isPlaying) {
              _audioPlayer.pause();
            } else {
              _audioPlayer.play(UrlSource(widget.url));
            }
          },
          child: Icon(
            _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
            color: widget.isMe ? AppColors.white : AppColors.primaryGreen,
            size: 32,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
            ),
            child: Slider(
              value: _position.inMilliseconds.toDouble(),
              max: _duration.inMilliseconds.toDouble() > 0 
                  ? _duration.inMilliseconds.toDouble() 
                  : 1.0,
              activeColor: widget.isMe ? AppColors.white : AppColors.primaryGreen,
              inactiveColor: widget.isMe ? AppColors.white.withOpacity(0.3) : AppColors.grey200,
              onChanged: (v) {
                _audioPlayer.seek(Duration(milliseconds: v.toInt()));
              },
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          _formatDuration(_isPlaying ? _position : _duration),
          style: TextStyle(
            fontSize: 10, 
            color: widget.isMe ? AppColors.white : AppColors.grey,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
