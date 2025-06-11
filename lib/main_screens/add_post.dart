import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_instagram_clone/main_screens/post_preview.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/colors.dart';

class AddPost extends StatefulWidget {
  const AddPost({super.key});

  @override
  State<AddPost> createState() => _AddPostState();
}

class _AddPostState extends State<AddPost> {
  late List<CameraDescription> _cameras;
  CameraController? _cameraController;
  File? _mediaFile;
  String? _error;
  bool _cameraReady = false;
  bool _showCamera = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    print('AddPost initialized');
  }

  Future<void> _initializeCamera() async {
    final cameraPermission = await Permission.camera.request();
    if (!cameraPermission.isGranted) {
      setState(() => _error = "Camera permission not granted.");
      return;
    }

    _cameras = await availableCameras();
    if (_cameras.isNotEmpty) {
      await _startCamera(_cameras.first);
    }
  }

  Future<void> _startCamera(CameraDescription camera) async {
    // Check if the widget is still mounted before proceeding
    if (!mounted) return;

    setState(() => _cameraReady = false);

    if (_cameraController != null) {
      await _cameraController!.dispose();
      _cameraController = null;
    }

    final controller = CameraController(camera, ResolutionPreset.high);

    try {
      await controller.initialize();
      if (!mounted) return; // Check mounted again after async operation
      setState(() {
        _cameraController = controller;
        _cameraReady = true;
      });
    } catch (e) {
      if (!mounted) return; // Avoid setting state if disposed
      setState(() => _error = "Camera init error: $e");
    }
  }

  Future<void> _takePhoto() async {
    if (!_cameraReady || _cameraController == null) return;
    try {
      final file = await _cameraController!.takePicture();
      if (!mounted) return; // Check mounted before setting state
      setState(() {
        _mediaFile = File(file.path);
        _showCamera = false;
      });
      _navigateToPreview();
    } catch (e) {
      if (!mounted) return; // Avoid setting state if disposed
      setState(() => _error = "Photo error: $e");
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      if (!mounted) return; // Check mounted before setting state
      setState(() {
        _mediaFile = File(picked.path);
      });
      _navigateToPreview();
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2 || _cameraController == null) return;

    final currentIndex = _cameras.indexOf(_cameraController!.description);
    final nextIndex = (currentIndex + 1) % _cameras.length;

    await _startCamera(_cameras[nextIndex]);
  }

  void _navigateToPreview() {
    if (_mediaFile != null) {
      print('Navigating to PostPreviewScreen');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostPreviewScreen(mediaFile: _mediaFile!),
        ),
      ).then((_) {
        if (!mounted) return; // Check mounted before setting state
        setState(() {
          _mediaFile = null;
          _showCamera = false;
        });
      });
    }
  }

  Future<void> _showMediaSourceDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Media Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                if (mounted) setState(() => _showCamera = true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: _showCamera && _cameraReady && _cameraController != null
            ? Stack(
                children: [
                  CameraPreview(_cameraController!),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 40.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.flip_camera_android,
                              color: isDarkMode ? Colors.white : AppColors.textPrimaryLight,
                              size: 30.sp,
                            ),
                            onPressed: _flipCamera,
                          ),
                          GestureDetector(
                            onTap: _takePhoto,
                            child: Container(
                              width: 70.w,
                              height: 70.h,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDarkMode ? Colors.white : AppColors.textPrimaryLight,
                                  width: 4.w,
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  width: 50.w,
                                  height: 50.h,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 30),
                        ],
                      ),
                    ),
                  ),
                  if (_error != null)
                    Positioned(
                      top: 20.h,
                      left: 20.w,
                      right: 20.w,
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 14.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _showMediaSourceDialog,
                      child: Container(
                        width: 343.w,
                        height: 200.h,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDarkMode ? Colors.white : AppColors.textPrimaryLight,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8.r),
                          color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 50.sp,
                              color: isDarkMode ? Colors.white : AppColors.textPrimaryLight,
                            ),
                            SizedBox(height: 10.h),
                            Text(
                              'Add your Post!!!',
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: isDarkMode ? Colors.white : AppColors.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_error != null)
                      Padding(
                        padding: EdgeInsets.only(top: 20.h),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 14.sp,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}