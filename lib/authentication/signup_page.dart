import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../custom_widgets/insta_textfield.dart';
import '../custom_widgets/insta_button.dart';
import 'package:flutter_instagram_clone/main_home_screen.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  DateTime? _selectedDate;
  File? _profileImage;
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  // Default placeholder image URL (replace with a valid public URL if needed)
  static const String _defaultProfileImageUrl = 'https://via.placeholder.com/150';

  // Cloudinary credentials
  static const String _cloudName = 'dutzx1xqn';
  static const String _apiKey = '944496563675247';
  static const String _uploadPreset = 'insta_clone_unsigned'; // Updated to match the actual preset name

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(() {
      final text = _usernameController.text;
      if (text.contains(' ')) {
        _usernameController.text = text.replaceAll(' ', '');
        _usernameController.selection = TextSelection.fromPosition(
          TextPosition(offset: _usernameController.text.length),
        );
      }
    });
  }

  Future<void> _pickImage() async {
    try {
      print('Opening image picker');
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (pickedFile == null) {
        print('No image selected');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image selected')),
        );
        return;
      }

      print('Image picked: ${pickedFile.path}');
      final file = File(pickedFile.path);
      try {
        final exists = await file.exists();
        if (!exists) {
          print('Image file does not exist: ${pickedFile.path}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selected image is not accessible')),
          );
          return;
        }
      } catch (e) {
        print('Error checking file existence: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to access image file')),
        );
        return;
      }

      setState(() {
        _profileImage = file;
        print('Image set successfully: ${pickedFile.path}');
      });
    } catch (e, stackTrace) {
      print('Error picking image: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to select image')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Colors.blue,
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(foregroundColor: Colors.blue),
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null && picked != _selectedDate) {
        setState(() => _selectedDate = picked);
      }
    } catch (e) {
      print('Error selecting date: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to select date')),
      );
    }
  }

  Future<String?> _uploadProfileImage(String uid) async {
    if (_profileImage == null) {
      print('No profile image to upload');
      return null;
    }

    try {
      print('Verifying image file: ${_profileImage!.path}');
      final exists = await _profileImage!.exists();
      if (!exists) {
        print('Profile image file does not exist: ${_profileImage!.path}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image is not accessible')),
        );
        return null;
      }

      print('Uploading image to Cloudinary for UID: $uid');
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri);

      // Add fields
      request.fields['upload_preset'] = _uploadPreset;
      request.fields['api_key'] = _apiKey;
      request.fields['public_id'] = 'profile_images/$uid'; // Store with UID as public_id

      // Add file
      final fileStream = http.ByteStream(_profileImage!.openRead());
      final fileLength = await _profileImage!.length();
      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: '$uid.jpg',
      );
      request.files.add(multipartFile);

      // Send request
      final response = await request.send().timeout(const Duration(seconds: 30));
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseBody);

      if (response.statusCode == 200 && jsonResponse['secure_url'] != null) {
        final imageUrl = jsonResponse['secure_url'] as String;
        print('Image uploaded successfully: $imageUrl');
        return imageUrl;
      } else {
        print('Upload failed with status: ${response.statusCode}');
        print('Response: $responseBody');
        throw Exception('Failed to upload image to Cloudinary: ${jsonResponse['error']?['message'] ?? 'Unknown error'}');
      }
    } catch (e, stackTrace) {
      print('Image upload failed: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload profile image')),
      );
      return null;
    }
  }

  Future<void> _signUp() async {
    if (_firstNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your first name')));
      return;
    }
    if (_lastNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your last name')));
      return;
    }
    if (_usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a username')));
      return;
    }
    if (_usernameController.text.contains(' ')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username cannot contain spaces')));
      return;
    }
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select your date of birth')));
      return;
    }
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your email')));
      return;
    }
    if (_passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a password')));
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    try {
      setState(() => _isLoading = true);
      print('Starting signup process');
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final uid = userCredential.user!.uid;
      print('User created with UID: $uid');

      final profileImageUrl = await _uploadProfileImage(uid);
      print('Profile image URL: ${profileImageUrl ?? 'null'}');

      print('Saving user data to Firestore');
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'email': _emailController.text.trim(),
        'username': _usernameController.text.trim().toLowerCase(),
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'dateOfBirth': Timestamp.fromDate(_selectedDate!),
        'profileImageUrl': profileImageUrl ?? _defaultProfileImageUrl,
        'createdAt': Timestamp.now(),
      });
      print('User data saved to Firestore');

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainHomeScreen()),
        );
      }
    } catch (e, stackTrace) {
      print('Signup failed: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signup failed. Please try again.')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            children: [
              SizedBox(height: 30.h),
              Text(
                'Vivir',
                style: TextStyle(
                  fontSize: 34.sp,
                  fontFamily: 'Pacifico',
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 20.h),
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50.r,
                  backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                  backgroundColor: Colors.grey[200],
                  child: _profileImage == null
                      ? Icon(Icons.add_a_photo, size: 30.r, color: Colors.grey[600])
                      : null,
                ),
              ),
              SizedBox(height: 20.h),
              InstaTextField(controller: _firstNameController, hintText: 'First Name'),
              SizedBox(height: 12.h),
              InstaTextField(controller: _lastNameController, hintText: 'Last Name'),
              SizedBox(height: 12.h),
              InstaTextField(controller: _usernameController, hintText: 'Username'),
              SizedBox(height: 12.h),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(5.r),
                    color: Colors.grey[50],
                  ),
                  width: double.infinity,
                  child: Text(
                    _selectedDate == null
                        ? 'Date of Birth'
                        : DateFormat('MMMM dd, yyyy').format(_selectedDate!),
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: _selectedDate == null ? Colors.grey[500] : (isDarkMode ? Colors.white : Colors.black),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              InstaTextField(controller: _emailController, hintText: 'Email'),
              SizedBox(height: 12.h),
              InstaTextField(
                controller: _passwordController,
                hintText: 'Password',
                obscureText: !_showPassword,
                prefixIcon: IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility : Icons.visibility_off,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                ),
              ),
              SizedBox(height: 12.h),
              InstaTextField(
                controller: _confirmPasswordController,
                hintText: 'Confirm Password',
                obscureText: !_showConfirmPassword,
                prefixIcon: IconButton(
                  icon: Icon(
                    _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                ),
              ),
              SizedBox(height: 20.h),
              InstaButton(
                text: _isLoading ? 'Signing Up...' : 'Sign Up',
                isFilled: true,
                onPressed: _isLoading ? null : _signUp,
              ),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Log in',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}