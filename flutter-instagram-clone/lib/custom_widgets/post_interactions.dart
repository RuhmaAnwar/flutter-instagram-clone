import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_instagram_clone/main_screens/chat_room_page.dart';

class PostInteractions extends StatefulWidget {
  final String postId;
  final String postUserId;
  final String mediaUrl;
  final String caption;

  const PostInteractions({
    Key? key,
    required this.postId,
    required this.postUserId,
    required this.mediaUrl,
    required this.caption,
  }) : super(key: key);

  @override
  State<PostInteractions> createState() => _PostInteractionsState();
}

class _PostInteractionsState extends State<PostInteractions> {
  final TextEditingController _commentController = TextEditingController();
  bool _isLiked = false;
  int _likeCount = 0;
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = false;
  late BuildContext _safeContext;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _safeContext = context;
  }

  @override
  void initState() {
    super.initState();
    _loadPostData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadPostData() async {
    if (!mounted) return;

    final postDoc =
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .get();

    if (postDoc.exists && mounted) {
      final data = postDoc.data()!;
      final likes = List<String>.from(data['likes'] ?? []);
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

      // Get comments with user data
      final comments = List<Map<String, dynamic>>.from(data['comments'] ?? []);
      final commentsWithUserData = await Future.wait(
        comments.map((comment) async {
          final userDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(comment['userId'])
                  .get();
          return {
            ...comment,
            'username': userDoc.data()?['username'] ?? 'Unknown',
            'profileImageUrl': userDoc.data()?['profileImageUrl'] ?? '',
          };
        }),
      );

      if (mounted) {
        setState(() {
          _isLiked = currentUserId != null && likes.contains(currentUserId);
          _likeCount = likes.length;
          _comments = commentsWithUserData;
        });
      }
    }
  }

  Future<void> _toggleLike() async {
    if (!mounted) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    setState(() => _isLoading = true);
    try {
      final postRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId);

      if (_isLiked) {
        await postRef.update({
          'likes': FieldValue.arrayRemove([currentUserId]),
        });
      } else {
        await postRef.update({
          'likes': FieldValue.arrayUnion([currentUserId]),
        });
      }

      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _likeCount += _isLiked ? 1 : -1;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          _safeContext,
        ).showSnackBar(SnackBar(content: Text('Error updating like: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addComment() async {
    if (!mounted) return;

    if (_commentController.text.trim().isEmpty) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    setState(() => _isLoading = true);
    try {
      // Get current user data
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .get();
      final username = userDoc.data()?['username'] ?? 'Unknown';
      final profileImageUrl = userDoc.data()?['profileImageUrl'] ?? '';

      final comment = {
        'userId': currentUserId,
        'username': username,
        'profileImageUrl': profileImageUrl,
        'text': _commentController.text.trim(),
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };

      // Get current comments
      final postDoc =
          await FirebaseFirestore.instance
              .collection('posts')
              .doc(widget.postId)
              .get();

      final currentComments = List<Map<String, dynamic>>.from(
        postDoc.data()?['comments'] ?? [],
      );
      currentComments.add(comment);

      // Update comments in Firestore
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .update({'comments': currentComments});

      // Update local state
      if (mounted) {
        setState(() {
          _comments.add(comment);
          _commentController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          _safeContext,
        ).showSnackBar(SnackBar(content: Text('Error adding comment: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showShareDialog() async {
    if (!mounted) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    // Get followers
    final followersSnapshot =
        await FirebaseFirestore.instance
            .collection('follows')
            .where('followingId', isEqualTo: currentUserId)
            .get();

    if (followersSnapshot.docs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(_safeContext).showSnackBar(
          const SnackBar(content: Text('You have no followers to share with')),
        );
      }
      return;
    }

    if (!mounted) return;

    showDialog(
      context: _safeContext,
      builder:
          (context) => AlertDialog(
            title: const Text('Share with followers'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300.h,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: followersSnapshot.docs.length,
                itemBuilder: (context, index) {
                  final follower = followersSnapshot.docs[index];
                  return FutureBuilder<DocumentSnapshot>(
                    future:
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(follower['followerId'])
                            .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      final userData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(
                            userData['profileImageUrl'] ?? '',
                          ),
                        ),
                        title: Text(userData['username'] ?? 'Unknown'),
                        onTap: () async {
                          Navigator.pop(context);
                          try {
                            // Create or get chat room
                            final chatRoomId =
                                [currentUserId, follower['followerId']].toList()
                                  ..sort();
                            final chatRoomRef = FirebaseFirestore.instance
                                .collection('chats')
                                .doc(chatRoomId.join('_'));

                            // Create chat room if it doesn't exist
                            await chatRoomRef.set({
                              'members': chatRoomId,
                              'lastMessage': 'Shared a post',
                              'lastTimestamp': FieldValue.serverTimestamp(),
                              'isTyping': {
                                currentUserId: false,
                                follower['followerId']: false,
                              },
                            }, SetOptions(merge: true));

                            // Add message with shared post
                            await chatRoomRef.collection('messages').add({
                              'senderId': currentUserId,
                              'receiverId': follower['followerId'],
                              'text': 'Shared a post',
                              'timestamp': FieldValue.serverTimestamp(),
                              'mediaType': 'post',
                              'postId': widget.postId,
                              'postUrl': widget.mediaUrl,
                              'postCaption': widget.caption,
                              'postUserId': widget.postUserId,
                              'seenBy': {
                                currentUserId: true,
                                follower['followerId']: false,
                              },
                              'isDeletedFor': [],
                            });

                            if (mounted) {
                              // Navigate to chat room
                              Navigator.push(
                                _safeContext,
                                MaterialPageRoute(
                                  builder:
                                      (context) => ChatRoomPage(
                                        userId: follower['followerId'],
                                        username:
                                            userData['username'] ?? 'Unknown',
                                      ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(_safeContext).showSnackBar(
                                SnackBar(
                                  content: Text('Error sharing post: $e'),
                                ),
                              );
                            }
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : null,
                  ),
                  onPressed: _isLoading ? null : _toggleLike,
                ),
                IconButton(
                  icon: const Icon(Icons.comment_outlined),
                  onPressed: () {
                    // Show comments section
                    showModalBottomSheet(
                      context: _safeContext,
                      isScrollControlled: true,
                      builder:
                          (context) => Container(
                            padding: EdgeInsets.all(16.w),
                            height: MediaQuery.of(context).size.height * 0.75,
                            child: Column(
                              children: [
                                // Comments header
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Comments',
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                // Comments list
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: _comments.length,
                                    itemBuilder: (context, index) {
                                      final comment = _comments[index];
                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundImage: NetworkImage(
                                            comment['profileImageUrl'] ?? '',
                                          ),
                                          child:
                                              comment['profileImageUrl'] == null
                                                  ? Text(
                                                    (comment['username'] ??
                                                            'U')[0]
                                                        .toUpperCase(),
                                                  )
                                                  : null,
                                        ),
                                        title: Text(
                                          comment['username'] ?? 'Unknown',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(comment['text'] ?? ''),
                                      );
                                    },
                                  ),
                                ),
                                // Comment input
                                Container(
                                  padding: EdgeInsets.symmetric(vertical: 8.h),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(24.r),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _commentController,
                                          decoration: const InputDecoration(
                                            hintText: 'Add a comment...',
                                            border: InputBorder.none,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon:
                                            _isLoading
                                                ? const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                                : const Icon(Icons.send),
                                        onPressed:
                                            _isLoading ? null : _addComment,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: _showShareDialog,
                ),
              ],
            ),
            // Add three-dot menu
            StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .snapshots(),
              builder: (context, snapshot) {
                final isPostOwner = snapshot.data?.id == widget.postUserId;
                if (!isPostOwner) return const SizedBox.shrink();

                return PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    if (value == 'delete') {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Delete Post'),
                              content: const Text(
                                'Are you sure you want to delete this post?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                      );

                      if (confirmed == true && mounted) {
                        try {
                          // Delete post from Firestore
                          await FirebaseFirestore.instance
                              .collection('posts')
                              .doc(widget.postId)
                              .delete();

                          // Update user's post count
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(widget.postUserId)
                              .update({'postCount': FieldValue.increment(-1)});

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Post deleted successfully'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error deleting post: $e'),
                              ),
                            );
                          }
                        }
                      }
                    }
                  },
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete Post'),
                            ],
                          ),
                        ),
                      ],
                );
              },
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            '$_likeCount likes',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
          ),
        ),
      ],
    );
  }
}
