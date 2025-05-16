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

  Future<void> _fetchUsers([String query = '']) async {
    if (_isFetchingMore) return;

    setState(() => _isFetchingMore = true);
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThan: query + 'z')
          .limit(_pageSize)
          .get();

      final filteredDocs = querySnapshot.docs.where((doc) => doc['uid'] != _auth.currentUser!.uid).toList();
      if (mounted) {
        setState(() {
          if (_lastDocument == null) {
            _users = filteredDocs;
          } else {
            _users.addAll(filteredDocs);
          }
          _lastDocument = filteredDocs.isNotEmpty ? filteredDocs.last : null;
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
      _fetchUsers(_searchController.text);
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
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: InstaTextField(
          controller: _searchController,
          hintText: 'Search users...',
          onChanged: (value) {
            setState(() {
              _users.clear();
              _lastDocument = null;
              _fetchUsers(value);
            });
          },
        ),
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
                await _fetchUsers(_searchController.text);
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