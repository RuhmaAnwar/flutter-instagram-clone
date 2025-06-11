import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'add_story.dart';
import '../custom_widgets/story_viewer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    print('HomePage initialized');
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    print('Building HomePage');

    return FutureBuilder<QuerySnapshot>(
      future:
          FirebaseFirestore.instance
              .collection('follows')
              .where('followerId', isEqualTo: currentUserId)
              .get(),
      builder: (context, followSnapshot) {
        if (followSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (followSnapshot.hasError) {
          return Center(child: Text('Error loading follows'));
        }
        // Get the list of user IDs the current user follows (including themselves)
        final followingIds = <String>{currentUserId!};
        for (final doc in followSnapshot.data?.docs ?? []) {
          final data = doc.data() as Map<String, dynamic>;
          followingIds.add(data['followingId'] as String);
        }
        return Scaffold(
          body: Column(
            children: [
              // STORIES BAR: Only show stories from followingIds
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('stories')
                        .where('expiresAt', isGreaterThan: Timestamp.now())
                        .where('userId', whereIn: followingIds.toList())
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    print('Stories StreamBuilder error: \\${snapshot.error}');
                    return SizedBox(
                      height: 100,
                      child: Center(
                        child: Text(
                          'Error loading stories: \\${snapshot.error}',
                        ),
                      ),
                    );
                  }
                  final docs = snapshot.data?.docs ?? [];
                  return FutureBuilder<List<Map<String, String>?>>(
                    future: Future.wait(
                      docs.map((doc) async {
                        try {
                          final data = doc.data() as Map<String, dynamic>;
                          final userId = data['userId'] as String?;
                          final mediaUrl = data['mediaUrl'] as String?;
                          if (userId == null || mediaUrl == null) return null;
                          // Fetch user info
                          final userSnap =
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(userId)
                                  .get();
                          final userData = userSnap.data() ?? {};
                          return <String, String>{
                            'userId': userId,
                            'mediaUrl': mediaUrl,
                            'username':
                                userData['username']?.toString() ?? 'Unknown',
                            'profileImageUrl':
                                userData['profileImageUrl']?.toString() ?? '',
                          };
                        } catch (e) {
                          print(
                            'Error processing story doc: \\${e.toString()}',
                          );
                          return null;
                        }
                      }),
                    ),
                    builder: (context, userSnaps) {
                      final stories =
                          (userSnaps.data ?? [])
                              .whereType<Map<String, String>>()
                              .toList();
                      final currentUserId =
                          FirebaseAuth.instance.currentUser?.uid;
                      // Group stories by userId
                      final Map<String, Map<String, String>> userStoryMap = {};
                      for (final story in stories) {
                        userStoryMap[story['userId']!] = story;
                      }
                      final myStory = userStoryMap[currentUserId ?? ''];
                      final otherStories =
                          userStoryMap.entries
                              .where((e) => e.key != currentUserId)
                              .map((e) => e.value)
                              .toList();
                      return StoriesBar(
                        currentUserId: currentUserId,
                        myStory: myStory,
                        otherStories: otherStories,
                        onAddStory: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddStory(),
                            ),
                          );
                          if (result == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Story added!')),
                            );
                            setState(() {});
                          }
                        },
                      );
                    },
                  );
                },
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('posts')
                          .where('userId', whereIn: followingIds.toList())
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                  builder: (context, snapshot) {
                    print('StreamBuilder state: ${snapshot.connectionState}');
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      print('Loading posts...');
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      print('HomePage error: ${snapshot.error}');
                      return Center(
                        child: Text('Error loading posts: ${snapshot.error}'),
                      );
                    }
                    if (!snapshot.hasData) {
                      print('No snapshot data');
                      return const Center(child: Text('No posts available'));
                    }
                    if (snapshot.data!.docs.isEmpty) {
                      print('No posts found in snapshot');
                      return const Center(child: Text('No posts available'));
                    }

                    final posts = snapshot.data!.docs;
                    print('Found ${posts.length} posts');

                    return ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        final postData = post.data() as Map<String, dynamic>;
                        final userId = postData['userId'] as String;
                        final mediaUrl = postData['mediaUrl'] as String;
                        final caption = postData['caption'] as String? ?? '';
                        print(
                          'Post $index: userId=$userId, mediaUrl=$mediaUrl, caption=$caption',
                        );

                        return FutureBuilder<DocumentSnapshot>(
                          future:
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(userId)
                                  .get(),
                          builder: (context, userSnapshot) {
                            if (!userSnapshot.hasData) {
                              return const SizedBox.shrink();
                            }
                            final userData =
                                userSnapshot.data!.data()
                                    as Map<String, dynamic>;
                            final username = userData['username'] ?? 'Unknown';
                            final profileImageUrl =
                                userData['profileImageUrl'] ?? '';
                            print('User for post $index: username=$username');

                            return Card(
                              margin: EdgeInsets.symmetric(
                                vertical: 8.h,
                                horizontal: 16.w,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    leading: CircleAvatar(
                                      radius: 20.r,
                                      backgroundImage:
                                          profileImageUrl.isNotEmpty
                                              ? NetworkImage(profileImageUrl)
                                              : null,
                                      backgroundColor: Colors.grey[200],
                                      child:
                                          profileImageUrl.isEmpty
                                              ? Icon(
                                                Icons.person,
                                                size: 20.r,
                                                color: Colors.grey[600],
                                              )
                                              : null,
                                    ),
                                    title: Text(
                                      username,
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            isDarkMode
                                                ? Colors.white
                                                : Colors.black,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 300.h,
                                    width: double.infinity,
                                    child: Image.network(
                                      mediaUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        print(
                                          'Image load error for $mediaUrl: $error',
                                        );
                                        return const Center(
                                          child: Text('Image failed to load'),
                                        );
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.w),
                                    child: Text(
                                      caption,
                                      style: TextStyle(fontSize: 14.sp),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class StoriesBar extends StatelessWidget {
  final String? currentUserId;
  final Map<String, String>? myStory;
  final List<Map<String, String>> otherStories;
  final VoidCallback onAddStory;

  const StoriesBar({
    Key? key,
    required this.currentUserId,
    required this.myStory,
    required this.otherStories,
    required this.onAddStory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Debug: Print myStory and otherStories
    print('myStory: ' + (myStory != null ? myStory.toString() : 'null'));
    print('otherStories: ' + otherStories.toString());
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Current user's story circle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: GestureDetector(
              onTap:
                  myStory != null
                      ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => StoryViewer(
                                  userId: myStory!["userId"]!,
                                  username: "Your Story",
                                  initialStoryId: myStory!["storyId"],
                                ),
                          ),
                        );
                      }
                      : onAddStory,
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                myStory != null ? Colors.purple : Colors.grey,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 36,
                          backgroundImage:
                              myStory != null &&
                                      myStory!["profileImageUrl"]!.isNotEmpty
                                  ? NetworkImage(myStory!["profileImageUrl"]!)
                                  : null,
                          backgroundColor: Colors.grey[300],
                          child:
                              myStory == null ||
                                      myStory!["profileImageUrl"]!.isEmpty
                                  ? Icon(
                                    Icons.person,
                                    size: 36,
                                    color: Colors.grey[600],
                                  )
                                  : null,
                        ),
                      ),
                      // + icon overlay if user can add another story
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: onAddStory,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (myStory != null &&
                            myStory!["username"] != null &&
                            myStory!["username"]!.isNotEmpty)
                        ? myStory!["username"]!
                        : "Your Story",
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 2),
          // Other users' stories
          ...otherStories.map(
            (story) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => StoryViewer(
                            userId: story["userId"]!,
                            username: story["username"] ?? "User",
                            initialStoryId: story["storyId"],
                          ),
                    ),
                  );
                },
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.purple, width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 36,
                        backgroundImage:
                            story["profileImageUrl"]!.isNotEmpty
                                ? NetworkImage(story["profileImageUrl"]!)
                                : null,
                        backgroundColor: Colors.grey[300],
                        child:
                            story["profileImageUrl"]!.isEmpty
                                ? Icon(
                                  Icons.person,
                                  size: 36,
                                  color: Colors.grey[600],
                                )
                                : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (story["username"] != null &&
                              story["username"]!.isNotEmpty)
                          ? story["username"]!
                          : "User",
                      style: const TextStyle(fontSize: 12, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
