import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_instagram_clone/authentication/login_page.dart';
import 'package:flutter_instagram_clone/custom_widgets/insta_button.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String firstName = '';
  String lastName = '';
  String email = '';
  String username = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    String? userUID = FirebaseAuth.instance.currentUser?.uid;
    if (userUID != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userUID)
            .get();

        if (userDoc.exists) {
          setState(() {
            firstName = userDoc['First Name'];
            lastName = userDoc['Last Name'];
            email = userDoc['email'];
            username = userDoc['Username'];
            isLoading = false;
          });
        }
      } catch (e) {
        print("Error fetching user data: $e");
      }
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    double buttonWidth = screenWidth * 0.40;
    double buttonHeight = screenHeight * 0.060;

    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Custom top header with username
                      Row(
                        children: [
                          Text(
                            username,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 0.01),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey,
                            child: Icon(Icons.person, size: 40, color: Colors.white),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$firstName $lastName',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 0),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildStatColumn("10", "Posts"),
                                    _buildStatColumn("200", "Followers"),
                                    _buildStatColumn("20", "Following"),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: buttonWidth,
                            height: buttonHeight,
                            child: InstaButton(
                              text: 'Edit Profile',
                              isFilled: true,
                              onPressed: () {
                                print('Edit Profile Clicked');
                              },
                            ),
                          ),
                          SizedBox(
                            width: buttonWidth,
                            height: buttonHeight,
                            child: InstaButton(
                              text: 'Share Profile',
                              isFilled: false,
                              onPressed: () {
                                print('Share Profile Clicked');
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: _logout,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black87,
                      ),
                      child: const Icon(Icons.logout, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatColumn(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
