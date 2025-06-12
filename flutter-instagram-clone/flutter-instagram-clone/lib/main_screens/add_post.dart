import 'package:flutter/material.dart';

class AddPost extends StatefulWidget {
  const AddPost({super.key});

  @override
  State<AddPost> createState() => _AddPostState();
}

class _AddPostState extends State<AddPost> {
  @override
  Widget build(BuildContext context) {
   return Scaffold(
      body: Center(
        child: const Text('Add Post', style: TextStyle(fontSize: 14)),
      ),
    );
  }
}