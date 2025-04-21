import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_instagram_clone/insta_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
final user = FirebaseAuth.instance.currentUser;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Home Page',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            
            InstaButton(
                    text: "Log Out",
                    isFilled: true,
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                    },
                  ),
          ],
        ),
      )
    );
  }
}