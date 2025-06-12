import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AddStory extends StatefulWidget {
  const AddStory({Key? key}) : super(key: key);

  @override
  State<AddStory> createState() => _AddStoryState();
}

class _AddStoryState extends State<AddStory> {
  File? _mediaFile;
  bool _isUploading = false;
  String? _error;

  // Cloudinary credentials
  static const String _cloudName = 'dutzx1xqn';
  static const String _uploadPreset = 'insta_clone_unsigned';

  Future<void> _pickMedia(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      setState(() => _mediaFile = File(picked.path));
    }
  }

  Future<String> _uploadToCloudinary(File file) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );
    final request =
        http.MultipartRequest('POST', uri)
          ..fields['upload_preset'] = _uploadPreset
          ..files.add(await http.MultipartFile.fromPath('file', file.path));
    final response = await request.send().timeout(const Duration(seconds: 30));
    final responseBody = await response.stream.bytesToString();
    final jsonResponse = jsonDecode(responseBody);
    if (response.statusCode != 200) {
      throw Exception(
        'Cloudinary upload failed: ${jsonResponse['error']?['message'] ?? responseBody}',
      );
    }
    return jsonResponse['secure_url'] as String;
  }

  Future<void> _uploadStory() async {
    if (_mediaFile == null) return;
    setState(() => _isUploading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');
      final mediaUrl = await _uploadToCloudinary(_mediaFile!);
      await FirebaseFirestore.instance.collection('stories').add({
        'userId': user.uid,
        'mediaUrl': mediaUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 24)),
        ),
        'likes': [],
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Story')),
      body: Center(
        child:
            _isUploading
                ? const CircularProgressIndicator()
                : _mediaFile == null
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                      onPressed: () => _pickMedia(ImageSource.camera),
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                      onPressed: () => _pickMedia(ImageSource.gallery),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 300.h,
                      child: Image.file(_mediaFile!, fit: BoxFit.cover),
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: _uploadStory,
                      child: const Text('Confirm & Add Story'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _mediaFile = null),
                      child: const Text('Choose Another'),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
      ),
    );
  }
}
