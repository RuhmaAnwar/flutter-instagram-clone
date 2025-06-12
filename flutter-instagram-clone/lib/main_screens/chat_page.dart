import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/chat_room_page.dart';
import '../theme/colors.dart';
import '../custom_widgets/insta_textfield.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  List<QueryDocumentSnapshot> _searchResults = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _isSearching = false;
  DocumentSnapshot? _lastChatDocument;
  static const int _pageSize = 15;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  Stream<QuerySnapshot> _getChatsStream() {
    Query query = _firestore
        .collection('chats')
        .where('members', arrayContains: _auth.currentUser!.uid)
        .orderBy('lastTimestamp', descending: true)
        .limit(_pageSize);

    if (_lastChatDocument != null) {
      query = query.startAfterDocument(_lastChatDocument!);
    }

    return query.snapshots();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent &&
        !_isFetchingMore &&
        _lastChatDocument != null &&
        !_isSearching) {
      setState(() => _isFetchingMore = true);
    }
  }

  Future<void> _fetchUsers(String query) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('username', isLessThan: query.toLowerCase() + 'z')
          .limit(_pageSize)
          .get();

      final filteredDocs = querySnapshot.docs.where((doc) {
        final uid = doc['uid'] as String? ?? '';
        return uid.isNotEmpty && uid != _auth.currentUser!.uid;
      }).toList();

      if (mounted) {
        setState(() {
          _searchResults = filteredDocs;
          _isSearching = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching users: $e')),
        );
      }
    }
  }

  void _startChat(String userId, String firstName, String lastName) {
    final chatRoomId = _getChatRoomId(userId);
    _firestore.collection('chats').doc(chatRoomId).set({
      'members': [_auth.currentUser!.uid, userId],
      'lastMessage': '',
      'lastTimestamp': null,
      'isTyping': {
        _auth.currentUser!.uid: false,
        userId: false,
      },
    }, SetOptions(merge: true));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomPage(
          userId: userId,
          firstName: firstName,
          lastName: lastName,
        ),
      ),
    ).then((_) {
      // Reset last document to reload initial page on return
      setState(() {
        _lastChatDocument = null;
        _isLoading = true;
      });
    });
  }

  String _getChatRoomId(String otherUserId) =>
      ([_auth.currentUser!.uid, otherUserId]..sort()).join('_');

  Future<Map<String, dynamic>> _getUserData(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    return userDoc.data() ?? {};
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SizedBox(
          width: 200.w,
          child: InstaTextField(
            controller: _searchController,
            hintText: 'Search users...',
            onChanged: (value) {
              if (value.isEmpty) {
                setState(() {
                  _isSearching = false;
                  _searchResults.clear();
                });
              } else {
                _fetchUsers(value);
              }
            },
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, size: 20.sp, color: AppColors.greyDark),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _isSearching = false;
                        _searchResults.clear();
                      });
                    },
                  )
                : null,
          ),
        ),
      ),
      body: _isSearching
          ? _searchResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('No users found', style: TextStyle(fontSize: 16.sp)),
                      ElevatedButton(
                        onPressed: () => _fetchUsers(_searchController.text.toLowerCase()),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    final firstName = user['firstName'] as String? ?? 'Unknown';
                    final lastName = user['lastName'] as String? ?? '';
                    final profileImageUrl = user['profileImageUrl'] as String? ?? '';
                    final userId = user['uid'] as String? ?? '';
                    if (userId.isEmpty) return const SizedBox.shrink();

                    return ListTile(
                      leading: SizedBox(
                        width: 40.w,
                        height: 40.w,
                        child: CircleAvatar(
                          radius: 20.r,
                          backgroundImage: profileImageUrl.isNotEmpty
                              ? NetworkImage(profileImageUrl)
                              : null,
                          backgroundColor: profileImageUrl.isEmpty ? AppColors.greyLight : null,
                          child: profileImageUrl.isEmpty
                              ? Icon(Icons.person, size: 20.r, color: AppColors.greyDark)
                              : null,
                          onBackgroundImageError: profileImageUrl.isNotEmpty
                              ? (error, stackTrace) => Icon(Icons.error, size: 20.r)
                              : null,
                        ),
                      ),
                      title: Text('$firstName $lastName', style: TextStyle(fontSize: 16.sp)),
                      onTap: () => _startChat(userId, firstName, lastName),
                    );
                  },
                )
          : StreamBuilder<QuerySnapshot>(
              stream: _getChatsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && _isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  print('Error streaming chats: ${snapshot.error}'); // Debug log
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error loading chats', style: TextStyle(fontSize: 16.sp)),
                        ElevatedButton(
                          onPressed: () => setState(() {
                            _isLoading = true;
                            _lastChatDocument = null;
                          }),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final chats = snapshot.data?.docs ?? [];
                if (chats.isEmpty && _lastChatDocument == null) {
                  print('No chats found for user ${_auth.currentUser!.uid}'); // Debug log
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('No chats yet', style: TextStyle(fontSize: 16.sp)),
                        ElevatedButton(
                          onPressed: () => setState(() {
                            _isLoading = true;
                            _lastChatDocument = null;
                          }),
                          child: const Text('Refresh'),
                        ),
                      ],
                    ),
                  );
                }

                if (_lastChatDocument == null) {
                  _isLoading = false;
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _lastChatDocument = null;
                      _isLoading = true;
                    });
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: chats.length + (_isFetchingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == chats.length && _isFetchingMore) {
                        _lastChatDocument = chats.isNotEmpty ? chats.last : null;
                        return Padding(
                          padding: EdgeInsets.all(16.0.w),
                          child: const Center(child: CircularProgressIndicator()),
                        );
                      }

                      final chat = chats[index];
                      final members = chat['members'] as List<dynamic>? ?? [];
                      final otherUserId = members.firstWhere(
                        (id) => id != _auth.currentUser!.uid,
                        orElse: () => '',
                      );
                      if (otherUserId.isEmpty) return const SizedBox.shrink();

                      final lastMessage = chat['lastMessage'] as String? ?? '';
                      final lastTimestamp = (chat['lastTimestamp'] as Timestamp?)?.toDate();

                      return FutureBuilder<Map<String, dynamic>>(
                        future: _getUserData(otherUserId),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const ListTile(
                              leading: CircularProgressIndicator(),
                              title: Text('Loading...'),
                            );
                          }
                          final userData = snapshot.data!;
                          final firstName = userData['firstName'] as String? ?? 'Unknown';
                          final lastName = userData['lastName'] as String? ?? '';
                          final profileImageUrl = userData['profileImageUrl'] as String? ?? '';

                          return ListTile(
                            leading: SizedBox(
                              width: 40.w,
                              height: 40.w,
                              child: CircleAvatar(
                                radius: 20.r,
                                backgroundImage: profileImageUrl.isNotEmpty
                                    ? NetworkImage(profileImageUrl)
                                    : null,
                                backgroundColor: profileImageUrl.isEmpty ? AppColors.greyLight : null,
                                child: profileImageUrl.isEmpty
                                    ? Icon(Icons.person, size: 20.r, color: AppColors.greyDark)
                                    : null,
                                onBackgroundImageError: profileImageUrl.isNotEmpty
                                    ? (error, stackTrace) => Icon(Icons.error, size: 20.r)
                                    : null,
                              ),
                            ),
                            title: Text(
                              '$firstName $lastName',
                              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              lastMessage.isNotEmpty ? lastMessage : 'No messages',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14.sp, color: AppColors.greyDark),
                            ),
                            trailing: lastTimestamp != null
                                ? Text(
                                    _formatTimestamp(lastTimestamp),
                                    style: TextStyle(fontSize: 12.sp, color: AppColors.greyDark),
                                  )
                                : null,
                            onTap: () => _startChat(otherUserId, firstName, lastName),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}