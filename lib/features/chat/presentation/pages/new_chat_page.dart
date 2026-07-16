import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/di/injection.dart';
import 'package:acepool/features/chat/domain/repositories/chat_repository.dart';
import 'package:acepool/features/chat/presentation/pages/chat_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class NewChatPage extends StatefulWidget {
  const NewChatPage({super.key});

  @override
  State<NewChatPage> createState() => _NewChatPageState();
}

class _NewChatPageState extends State<NewChatPage> {
  static final _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'acepool',
  );

  final _searchController = TextEditingController();
  late Future<QuerySnapshot<Map<String, dynamic>>> _usersFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _usersFuture = _db.collection('users').get();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openChat(String otherId, String otherName) async {
    final myId = FirebaseAuth.instance.currentUser?.uid;
    if (myId == null) return;

    final ids = [myId, otherId]..sort();
    final chatId = ids.join('_');

    await sl<ChatRepository>().ensureChatExists(
      chatId: chatId,
      participantIds: [myId, otherId],
      participantNames: {
        myId: FirebaseAuth.instance.currentUser?.displayName ?? 'User',
        otherId: otherName,
      },
      type: 'private',
    );

    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChatPage(
        chatId: chatId,
        title: otherName,
        receiverId: otherId,
        receiverName: otherName,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final myId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'New chat',
          style: TextStyle(color: AppColors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Search people',
                  prefixIcon: Icon(Icons.search, color: AppColors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
              future: _usersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final users = (snapshot.data?.docs ?? [])
                    .where((doc) => doc.id != myId)
                    .where((doc) {
                      if (_query.isEmpty) return true;
                      final name = (doc.data()['fullName'] as String? ?? '').toLowerCase();
                      return name.contains(_query);
                    })
                    .toList()
                  ..sort((a, b) => (a.data()['fullName'] as String? ?? '')
                      .compareTo(b.data()['fullName'] as String? ?? ''));

                if (users.isEmpty) {
                  return const Center(child: Text('No people found'));
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final doc = users[index];
                    final data = doc.data();
                    final name = (data['fullName'] as String? ?? '').trim();
                    final displayName = name.isNotEmpty ? name : 'User';
                    final initials = name.isNotEmpty
                        ? name
                            .split(' ')
                            .where((w) => w.isNotEmpty)
                            .take(2)
                            .map((w) => w[0].toUpperCase())
                            .join()
                        : '?';

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.grey200,
                        child: Text(
                          initials,
                          style: const TextStyle(color: AppColors.black87, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(data['email'] as String? ?? ''),
                      onTap: () => _openChat(doc.id, displayName),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
