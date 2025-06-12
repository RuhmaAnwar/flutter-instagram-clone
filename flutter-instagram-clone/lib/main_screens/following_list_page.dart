import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowingListPage extends StatelessWidget {
  final String userId;

  const FollowingListPage({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Following'),
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
          final following = (userData['following'] as List<dynamic>?) ?? [];

          if (following.isEmpty) {
            return const Center(child: Text('Not following anyone yet'));
          }

          return ListView.builder(
            itemCount: following.length,
            itemBuilder: (context, index) {
              final followingId = following[index];
              return StreamBuilder<DocumentSnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(followingId)
                        .snapshots(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const SizedBox();
                  }

                  final followingData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                  final isFollowing =
                      (followingData['followers'] as List<dynamic>?)?.contains(
                        currentUserId,
                      ) ??
                      false;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          followingData['profileImageUrl'] != null &&
                                  followingData['profileImageUrl'].isNotEmpty
                              ? NetworkImage(followingData['profileImageUrl'])
                              : null,
                      child:
                          followingData['profileImageUrl'] == null ||
                                  followingData['profileImageUrl'].isEmpty
                              ? const Icon(Icons.person)
                              : null,
                    ),
                    title: Text(followingData['username'] ?? 'User'),
                    subtitle: Text(
                      '${followingData['firstName'] ?? ''} ${followingData['lastName'] ?? ''}',
                    ),
                    trailing:
                        followingId != currentUserId
                            ? TextButton(
                              onPressed: () async {
                                final userRef = FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(currentUserId);
                                final followingRef = FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(followingId);

                                if (isFollowing) {
                                  await userRef.update({
                                    'following': FieldValue.arrayRemove([
                                      followingId,
                                    ]),
                                  });
                                  await followingRef.update({
                                    'followers': FieldValue.arrayRemove([
                                      currentUserId,
                                    ]),
                                  });
                                } else {
                                  await userRef.update({
                                    'following': FieldValue.arrayUnion([
                                      followingId,
                                    ]),
                                  });
                                  await followingRef.update({
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
