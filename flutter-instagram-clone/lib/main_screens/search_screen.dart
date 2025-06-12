import 'package:flutter/material.dart';
import '../custom_widgets/insta_textfield.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        automaticallyImplyLeading: false, // No back button
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: InstaTextField(
              controller: _searchController,
              hintText: 'Search',
            ),
          ),
          // Friend Suggestions
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 4.0,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Friend Suggestions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final users =
                    snapshot.data!.docs
                        .where((doc) => doc['uid'] != currentUserId)
                        .toList();
                if (users.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final username = user['username'] ?? 'Unknown';
                    final profileImageUrl = user['profileImageUrl'] ?? '';
                    final userId = user['uid'] as String;
                    return _FriendSuggestionTile(
                      userId: userId,
                      username: username,
                      profileImageUrl: profileImageUrl,
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

class _FriendSuggestionTile extends StatefulWidget {
  final String userId;
  final String username;
  final String profileImageUrl;
  const _FriendSuggestionTile({
    Key? key,
    required this.userId,
    required this.username,
    required this.profileImageUrl,
  }) : super(key: key);

  @override
  State<_FriendSuggestionTile> createState() => _FriendSuggestionTileState();
}

class _FriendSuggestionTileState extends State<_FriendSuggestionTile> {
  String? currentUserId;
  bool? isFollowing;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _checkFollowing();
  }

  Future<void> _checkFollowing() async {
    final snap =
        await FirebaseFirestore.instance
            .collection('follows')
            .where('followerId', isEqualTo: currentUserId)
            .where('followingId', isEqualTo: widget.userId)
            .get();
    setState(() {
      isFollowing = snap.docs.isNotEmpty;
    });
  }

  Future<void> _follow() async {
    await FirebaseFirestore.instance.collection('follows').add({
      'followerId': currentUserId,
      'followingId': widget.userId,
    });
    _checkFollowing();
  }

  Future<void> _unfollow() async {
    final snap =
        await FirebaseFirestore.instance
            .collection('follows')
            .where('followerId', isEqualTo: currentUserId)
            .where('followingId', isEqualTo: widget.userId)
            .get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
    _checkFollowing();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
            widget.profileImageUrl.isNotEmpty
                ? NetworkImage(widget.profileImageUrl)
                : null,
        child: widget.profileImageUrl.isEmpty ? const Icon(Icons.person) : null,
      ),
      title: Text(widget.username),
      trailing:
          isFollowing == null
              ? const SizedBox(width: 80, child: LinearProgressIndicator())
              : isFollowing!
              ? TextButton(onPressed: _unfollow, child: const Text('Unfollow'))
              : TextButton(onPressed: _follow, child: const Text('Follow')),
    );
  }
}
