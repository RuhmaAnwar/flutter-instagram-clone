import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowersListPage extends StatelessWidget {
  final String userId;

  const FollowersListPage({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Followers'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final followers = (userData['followers'] as List<dynamic>?) ?? [];

          if (followers.isEmpty) {
            return const Center(child: Text('No followers yet'));
          }

          return ListView.builder(
            itemCount: followers.length,
            itemBuilder: (context, index) {
              final followerId = followers[index];
              return StreamBuilder<DocumentSnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(followerId)
                        .snapshots(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const SizedBox();
                  }

                  final followerData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                  final isFollowing =
                      (followerData['followers'] as List<dynamic>?)?.contains(
                        currentUserId,
                      ) ??
                      false;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          followerData['profileImageUrl'] != null &&
                                  followerData['profileImageUrl'].isNotEmpty
                              ? NetworkImage(followerData['profileImageUrl'])
                              : null,
                      child:
                          followerData['profileImageUrl'] == null ||
                                  followerData['profileImageUrl'].isEmpty
                              ? const Icon(Icons.person)
                              : null,
                    ),
                    title: Text(followerData['username'] ?? 'User'),
                    subtitle: Text(
                      '${followerData['firstName'] ?? ''} ${followerData['lastName'] ?? ''}',
                    ),
                    trailing:
                        followerId != currentUserId
                            ? TextButton(
                              onPressed: () async {
                                final userRef = FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(currentUserId);
                                final followerRef = FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(followerId);

                                if (isFollowing) {
                                  await userRef.update({
                                    'following': FieldValue.arrayRemove([
                                      followerId,
                                    ]),
                                  });
                                  await followerRef.update({
                                    'followers': FieldValue.arrayRemove([
                                      currentUserId,
                                    ]),
                                  });
                                } else {
                                  await userRef.update({
                                    'following': FieldValue.arrayUnion([
                                      followerId,
                                    ]),
                                  });
                                  await followerRef.update({
                                    'followers': FieldValue.arrayUnion([
                                      currentUserId,
                                    ]),
                                  });
                                }
                              },
                              child: Text(isFollowing ? 'Unfollow' : 'Follow'),
                            )
                            : null,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
