import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../custom_widgets/insta_button.dart';
import '../custom_widgets/insta_textfield.dart';
import '../theme/colors.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  File? _newProfileImage;
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;

  // Cloudinary credentials (same as signup_page.dart)
  static const String _cloudName = 'dutzx1xqn';
  static const String _apiKey = '944496563675247';
  static const String _uploadPreset = 'insta_clone_unsigned';
  static const String _defaultProfileImageUrl = 'https://via.placeholder.com/150';

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      if (await file.exists()) {
        setState(() => _newProfileImage = file);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected image is not accessible')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to select image')),
      );
    }
  }

  Future<String?> _uploadProfileImage(String uid) async {
    if (_newProfileImage == null) return null;

    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['api_key'] = _apiKey
        ..fields['public_id'] = 'profile_images/$uid'
        ..files.add(await http.MultipartFile.fromPath('file', _newProfileImage!.path, filename: '$uid.jpg'));

      final response = await request.send().timeout(const Duration(seconds: 30));
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseBody);

      if (response.statusCode == 200 && jsonResponse['secure_url'] != null) {
        return jsonResponse['secure_url'] as String;
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload profile image')),
      );
      return null;
    }
  }

  Future<void> _saveProfile(String uid, String currentUsername) async {
    setState(() => _isLoading = true);
    try {
      final newUsername = _usernameController.text.trim().toLowerCase();
      if (newUsername.isEmpty || newUsername.contains(' ')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username cannot be empty or contain spaces')),
        );
        return;
      }

      final profileImageUrl = await _uploadProfileImage(uid);
      final updates = <String, dynamic>{};
      if (newUsername != currentUsername) {
        updates['username'] = newUsername;
      }
      if (_bioController.text.trim().isNotEmpty) {
        updates['bio'] = _bioController.text.trim();
      } else {
        updates['bio'] = null;
      }
      if (profileImageUrl != null) {
        updates['profileImageUrl'] = profileImageUrl;
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update(updates);
        setState(() {
          _newProfileImage = null;
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      } else {
        setState(() => _isEditing = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login'); // Adjust route name as needed
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to sign out')),
      );
    }
  }

  void _showEditProfileDialog(Map<String, dynamic> data) {
    _usernameController.text = data['username'] ?? '';
    _bioController.text = data['bio'] ?? '';
    _newProfileImage = null;

    showDialog(
      context: context,
      builder: (context) {
        bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          title: Text('Edit Profile', style: TextStyle(fontSize: 18.sp)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 40.r,
                    backgroundImage: _newProfileImage != null
                        ? FileImage(_newProfileImage!)
                        : data['profileImageUrl'] != null
                            ? NetworkImage(data['profileImageUrl'])
                            : null,
                    backgroundColor: AppColors.greyLight,
                    child: _newProfileImage == null && data['profileImageUrl'].isEmpty
                        ? Icon(Icons.add_a_photo, size: 25.r, color: AppColors.greyDark)
                        : null,
                  ),
                ),
                SizedBox(height: 12.h),
                InstaTextField(
                  controller: _usernameController,
                  hintText: 'Username',
                ),
                SizedBox(height: 12.h),
                InstaTextField(
                  controller: _bioController,
                  hintText: 'Bio',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(fontSize: 14.sp, color: AppColors.greyDark)),
            ),
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () => _saveProfile(_auth.currentUser!.uid, data['username']),
              child: Text(
                _isLoading ? 'Saving...' : 'Save',
                style: TextStyle(fontSize: 14.sp, color: AppColors.primaryTeal),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Please log in',
            style: TextStyle(fontSize: 16.sp, color: isDarkMode ? Colors.white : Colors.black),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, size: 24.sp, color: AppColors.greyDark),
            onPressed: _signOut,
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _firestore.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading profile',
                style: TextStyle(fontSize: 16.sp, color: isDarkMode ? Colors.white : Colors.black),
              ),
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                'Profile not found',
                style: TextStyle(fontSize: 16.sp, color: isDarkMode ? Colors.white : Colors.black),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final username = data['username'] ?? 'Unknown';
          final firstName = data['firstName'] ?? '';
          final lastName = data['lastName'] ?? '';
          final profileImageUrl = data['profileImageUrl'] ?? _defaultProfileImageUrl;
          final bio = data['bio'] ?? '';
          final dateOfBirth = (data['dateOfBirth'] as Timestamp?)?.toDate();
          final age = dateOfBirth != null
              ? DateTime.now().year - dateOfBirth.year - (DateTime.now().month < dateOfBirth.month || (DateTime.now().month == dateOfBirth.month && DateTime.now().day < dateOfBirth.day) ? 1 : 0)
              : null;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 40.r,
                        backgroundImage: profileImageUrl.isNotEmpty
                            ? NetworkImage(profileImageUrl)
                            : null,
                        backgroundColor: AppColors.greyLight,
                        child: profileImageUrl.isEmpty
                            ? Icon(Icons.person, size: 40.r, color: AppColors.greyDark)
                            : null,
                      ),
                      SizedBox(width: 20.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username,
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStatColumn('Posts', '0'),
                                _buildStatColumn('Followers', '0'),
                                _buildStatColumn('Following', '0'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$firstName $lastName',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      if (bio.isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Text(
                          bio,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                      if (age != null) ...[
                        SizedBox(height: 4.h),
                        Text(
                          'Age: $age',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: InstaButton(
                    text: 'Edit Profile',
                    isFilled: false,
                    onPressed: () => _showEditProfileDialog(data),
                  ),
                ),
                SizedBox(height: 16.h),
                // Posts Section
                Divider(color: isDarkMode ? AppColors.greyBorderDark : AppColors.greyBorderLight),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Text(
                    'Posts',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.grid_off,
                        size: 40.r,
                        color: isDarkMode ? AppColors.greyDark : AppColors.greyLight,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'No posts yet',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}