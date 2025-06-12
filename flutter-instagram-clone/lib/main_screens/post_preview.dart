import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_instagram_clone/main_home_screen.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../custom_widgets/insta_button.dart';
import '../custom_widgets/insta_textfield.dart';

class PostPreviewScreen extends StatefulWidget {
  final File mediaFile;

  const PostPreviewScreen({super.key, required this.mediaFile});

  @override
  _PostPreviewScreenState createState() => _PostPreviewScreenState();
}

class _PostPreviewScreenState extends State<PostPreviewScreen> {
  final TextEditingController _captionController = TextEditingController();
  bool _isUploading = false;

  // Cloudinary credentials
  static const String _cloudName = 'dutzx1xqn';
  static const String _uploadPreset = 'insta_clone_unsigned';

  Future<String> _uploadToCloudinary() async {
    try {
      final exists = await widget.mediaFile.exists();
      if (!exists)
        throw Exception('Image file does not exist: ${widget.mediaFile.path}');

      print('Uploading to Cloudinary: ${widget.mediaFile.path}');
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );
      final request =
          http.MultipartRequest('POST', uri)
            ..fields['upload_preset'] = _uploadPreset
            ..files.add(
              await http.MultipartFile.fromPath('file', widget.mediaFile.path),
            );

      final response = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseBody);

      if (response.statusCode != 200) {
        throw Exception(
          'Cloudinary upload failed: ${response.statusCode} - ${jsonResponse['error']?['message'] ?? responseBody}',
        );
      }

      final mediaUrl = jsonResponse['secure_url'] as String;
      print('Cloudinary upload successful: $mediaUrl');
      return mediaUrl;
    } catch (e) {
      print('Cloudinary upload error: $e');
      throw Exception('Cloudinary upload error: $e');
    }
  }

  Future<void> _saveToFirestore(String mediaUrl) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      print('Saving post to Firestore for user: ${user.uid}');
      DocumentReference postRef = await FirebaseFirestore.instance
          .collection('posts')
          .add({
            'userId': user.uid,
            'mediaUrl': mediaUrl,
            'caption': _captionController.text,
            'timestamp': FieldValue.serverTimestamp(),
            'likes': [], // Array of user IDs who liked the post
            'comments': [], // Array of comment objects
          });
      print('Post saved successfully with ID: ${postRef.id}');

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'postCount': FieldValue.increment(1)},
      );
      print('User post count updated for user: ${user.uid}');
    } catch (e) {
      print('Firestore save error: $e');
      throw Exception('Firestore save error: $e');
    }
  }

  Future<void> _uploadPost() async {
    setState(() => _isUploading = true);
    try {
      print('Starting post upload process...');
      final mediaUrl = await _uploadToCloudinary();
      await _saveToFirestore(mediaUrl);
      print('Post upload completed successfully');

      if (mounted) {
        // Navigate back to MainHomeScreen and switch to HomePage tab (index 0)
        print('Navigating to MainHomeScreen with HomePage tab...');
        Navigator.popUntil(
          context,
          (route) => route.isFirst,
        ); // Return to MainHomeScreen
        // Use GlobalKey to switch to HomePage tab
        final state = MainHomeScreen.mainKey.currentState;
        if (state != null) {
          state.switchToHomeTab(); // Call the public method
        }
      }
    } catch (e) {
      print('Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading post: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'New Post',
          style: TextStyle(
            fontSize: 20.sp,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 300.h,
              child: Image.file(widget.mediaFile, fit: BoxFit.cover),
            ),
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: InstaTextField(
                controller: _captionController,
                hintText: 'Write a caption...',
              ),
            ),
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: InstaButton(
                text: _isUploading ? 'Posting...' : 'Confirm',
                onPressed: _isUploading ? null : _uploadPost,
                isFilled: true,
              ),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}
