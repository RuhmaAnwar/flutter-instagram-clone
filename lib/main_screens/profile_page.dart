import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_instagram_clone/main_screens/edit_profile_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_instagram_clone/custom_widgets/insta_button.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final String currentUid = FirebaseAuth.instance.currentUser!.uid;
  bool _isSigningOut = false;

  Widget _buildStatColumn(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(currentUid)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username and profile picture row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage:
                                userData['profileImageUrl'] != null &&
                                        userData['profileImageUrl'].isNotEmpty
                                    ? NetworkImage(userData['profileImageUrl'])
                                    : null,
                            child:
                                userData['profileImageUrl'] == null ||
                                        userData['profileImageUrl'].isEmpty
                                    ? const Icon(Icons.person, size: 40)
                                    : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              userData['username'] ?? '',
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Stats row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Posts count
                          StreamBuilder<QuerySnapshot>(
                            stream:
                                FirebaseFirestore.instance
                                    .collection('posts')
                                    .where('userId', isEqualTo: currentUid)
                                    .snapshots(),
                            builder: (context, postSnapshot) {
                              final postCount =
                                  postSnapshot.data?.docs.length ?? 0;
                              return _buildStatColumn('Posts', postCount);
                            },
                          ),
                          // Followers count
                          StreamBuilder<QuerySnapshot>(
                            stream:
                                FirebaseFirestore.instance
                                    .collection('follows')
                                    .where('followingId', isEqualTo: currentUid)
                                    .snapshots(),
                            builder: (context, followersSnapshot) {
                              final followersCount =
                                  followersSnapshot.data?.docs.length ?? 0;
                              return _buildStatColumn(
                                'Followers',
                                followersCount,
                              );
                            },
                          ),
                          // Following count
                          StreamBuilder<QuerySnapshot>(
                            stream:
                                FirebaseFirestore.instance
                                    .collection('follows')
                                    .where('followerId', isEqualTo: currentUid)
                                    .snapshots(),
                            builder: (context, followingSnapshot) {
                              final followingCount =
                                  followingSnapshot.data?.docs.length ?? 0;
                              return _buildStatColumn(
                                'Following',
                                followingCount,
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Edit and Logout buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: InstaButton(
                              text: 'Edit Profile',
                              isFilled: false,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const EditProfileScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: InstaButton(
                              text:
                                  _isSigningOut ? 'Logging Out...' : 'Log Out',
                              isFilled: false,
                              onPressed: _isSigningOut ? null : _signOut,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(),
                StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('posts')
                          .where('userId', isEqualTo: currentUid)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final postDocs = snapshot.data!.docs;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 2,
                            mainAxisSpacing: 2,
                          ),
                      itemCount: postDocs.length,
                      itemBuilder: (context, index) {
                        final post = postDocs[index];
                        final mediaUrl = post['mediaUrl'] as String;
                        return Image.network(mediaUrl, fit: BoxFit.cover);
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
