import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StoryViewer extends StatefulWidget {
  final String userId;
  final String username;
  final String? initialStoryId;

  const StoryViewer({
    Key? key,
    required this.userId,
    required this.username,
    this.initialStoryId,
  }) : super(key: key);

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> {
  List<Map<String, dynamic>> stories = [];
  int currentIndex = 0;
  bool loading = true;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _fetchStories();
  }

  Future<void> _fetchStories() async {
    final snap =
        await FirebaseFirestore.instance
            .collection('stories')
            .where('userId', isEqualTo: widget.userId)
            .where('expiresAt', isGreaterThan: Timestamp.now())
            .orderBy('timestamp')
            .get();
    setState(() {
      stories =
          snap.docs.map((doc) {
            final data = doc.data();
            return {'mediaUrl': data['mediaUrl'], 'storyId': doc.id};
          }).toList();
      if (widget.initialStoryId != null) {
        final idx = stories.indexWhere(
          (s) => s['storyId'] == widget.initialStoryId,
        );
        if (idx != -1) currentIndex = idx;
      }
      loading = false;
    });
  }

  void _onPageChanged(int idx) {
    setState(() {
      currentIndex = idx;
    });
  }

  Future<void> _toggleLike() async {
    if (stories.isEmpty || currentUserId == null) return;
    final storyId = stories[currentIndex]['storyId'];
    final ref = FirebaseFirestore.instance.collection('stories').doc(storyId);
    final doc = await ref.get();
    final data = doc.data();
    final likes = (data?['likes'] as List<dynamic>? ?? []);
    final isLiked = likes.contains(currentUserId);
    if (isLiked) {
      await ref.update({
        'likes': FieldValue.arrayRemove([currentUserId]),
      });
    } else {
      await ref.update({
        'likes': FieldValue.arrayUnion([currentUserId]),
      });
    }
    setState(() {}); // Refresh like state
  }

  Future<bool> _isLiked() async {
    if (stories.isEmpty || currentUserId == null) return false;
    final storyId = stories[currentIndex]['storyId'];
    final doc =
        await FirebaseFirestore.instance
            .collection('stories')
            .doc(storyId)
            .get();
    final data = doc.data();
    final likes = (data?['likes'] as List<dynamic>? ?? []);
    return likes.contains(currentUserId);
  }

  Future<int> _likeCount() async {
    if (stories.isEmpty) return 0;
    final storyId = stories[currentIndex]['storyId'];
    final doc =
        await FirebaseFirestore.instance
            .collection('stories')
            .doc(storyId)
            .get();
    final data = doc.data();
    final likes = (data?['likes'] as List<dynamic>? ?? []);
    return likes.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : stories.isEmpty
              ? const Center(
                child: Text(
                  'No stories',
                  style: TextStyle(color: Colors.white),
                ),
              )
              : Stack(
                children: [
                  PageView.builder(
                    itemCount: stories.length,
                    controller: PageController(initialPage: currentIndex),
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, idx) {
                      return Center(
                        child: Image.network(
                          stories[idx]['mediaUrl'],
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          errorBuilder:
                              (context, error, stackTrace) => const Center(
                                child: Icon(Icons.error, color: Colors.white),
                              ),
                        ),
                      );
                    },
                  ),
                  // Progress tabs
                  Positioned(
                    top: 40,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        stories.length,
                        (idx) => Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            height: 4,
                            decoration: BoxDecoration(
                              color:
                                  idx <= currentIndex
                                      ? Colors.white
                                      : Colors.white24,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Username
                  Positioned(
                    top: 50,
                    left: 16,
                    child: Text(
                      widget.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Close button
                  Positioned(
                    top: 40,
                    right: 16,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  // Like button and count
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: FutureBuilder<bool>(
                      future: _isLiked(),
                      builder: (context, likeSnap) {
                        final isLiked = likeSnap.data ?? false;
                        return Column(
                          children: [
                            IconButton(
                              icon: Icon(
                                isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isLiked ? Colors.red : Colors.white,
                                size: 36,
                              ),
                              onPressed: _toggleLike,
                            ),
                            FutureBuilder<int>(
                              future: _likeCount(),
                              builder: (context, countSnap) {
                                final count = countSnap.data ?? 0;
                                return Text(
                                  '$count likes',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}
