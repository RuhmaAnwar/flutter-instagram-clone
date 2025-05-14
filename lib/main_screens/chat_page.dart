import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/chat_room_page.dart'; 
import '../theme/colors.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();
  List<QueryDocumentSnapshot> _users = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  DocumentSnapshot? _lastDocument;
  static const int _pageSize = 15;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _fetchUsers() async {
    if (_isFetchingMore) return;

    setState(() => _isFetchingMore = true);
    try {
      QuerySnapshot querySnapshot;
      if (_lastDocument == null) {
        // Initial fetch
        querySnapshot = await _firestore
            .collection('users')
            .where('uid', isNotEqualTo: _auth.currentUser!.uid)
            .orderBy('uid') // Required by Firestore for inequality filter
            .orderBy('createdAt', descending: true)
            .limit(_pageSize)
            .get();
      } else {
        // Fetch next page
        querySnapshot = await _firestore
            .collection('users')
            .where('uid', isNotEqualTo: _auth.currentUser!.uid)
            .orderBy('uid')
            .orderBy('createdAt', descending: true)
            .startAfterDocument(_lastDocument!)
            .limit(_pageSize)
            .get();
      }

      if (mounted) {
        setState(() {
          if (_lastDocument == null) {
            _users = querySnapshot.docs;
          } else {
            _users.addAll(querySnapshot.docs);
          }
          // Only set _lastDocument if we fetched exactly _pageSize documents
          if (querySnapshot.docs.length < _pageSize) {
            _lastDocument = null; // No more users to fetch
          } else {
            _lastDocument = querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;
          }
          _isLoading = false;
          _isFetchingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isFetchingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching users: $e')),
        );
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent &&
        !_isFetchingMore &&
        _lastDocument != null) {
      _fetchUsers();
    }
  }

  void _startChat(String userId, String firstName, String lastName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomPage(
          userId: userId,
          firstName: firstName,
          lastName: lastName,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _users.clear();
                  _lastDocument = null;
                  _isLoading = true;
                });
                await _fetchUsers();
              },
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _users.length + (_isFetchingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _users.length) {
                    return Padding(
                      padding: EdgeInsets.all(16.0.w),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }
                  final user = _users[index];
                  final firstName = user['firstName'] as String? ?? 'Unknown';
                  final lastName = user['lastName'] as String? ?? '';
                  final profileImageUrl = user['profileImageUrl'] as String? ?? '';
                  final userId = user['uid'] as String;

                  return ListTile(
                    leading: CircleAvatar(
                      radius: 20.r,
                      backgroundImage: profileImageUrl.isNotEmpty
                          ? NetworkImage(profileImageUrl)
                          : null,
                      backgroundColor: profileImageUrl.isEmpty ? AppColors.greyLight : null,
                      child: profileImageUrl.isEmpty
                          ? Icon(Icons.person, size: 20.r, color: AppColors.greyDark)
                          : null,
                    ),
                    title: Text(
                      '$firstName $lastName',
                      style: TextStyle(fontSize: 16.sp),
                    ),
                    onTap: () => _startChat(userId, firstName, lastName),
                  );
                },
              ),
            ),
    );
  }
}