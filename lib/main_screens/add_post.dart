import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/colors.dart';

class AddPost extends StatefulWidget {
  const AddPost({super.key});

  @override
  State<AddPost> createState() => _AddPostState();
}

class _AddPostState extends State<AddPost> with SingleTickerProviderStateMixin {
  late List<CameraDescription> _cameras;
  CameraController? _cameraController;
  VideoPlayerController? _videoController;
  late AnimationController _pulseController;

  File? _mediaFile;
  bool _isVideo = false;
  bool _isRecording = false;
  bool _cameraReady = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      lowerBound: 1.0,
      upperBound: 1.2,
    )..repeat(reverse: true);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameraPermission = await Permission.camera.request();
    final micPermission = await Permission.microphone.request();

    if (!cameraPermission.isGranted || !micPermission.isGranted) {
      setState(() => _error = "Camera or microphone permission not granted.");
      return;
    }

    _cameras = await availableCameras();
    if (_cameras.isNotEmpty) {
      await _startCamera(_cameras.first);
    }
  }

  Future<void> _startCamera(CameraDescription camera) async {
    setState(() => _cameraReady = false);

    if (_cameraController != null) {
      await _cameraController!.dispose();
      _cameraController = null;
    }

    final controller = CameraController(camera, ResolutionPreset.high);

    try {
      await controller.initialize();
      setState(() {
        _cameraController = controller;
        _cameraReady = true;
      });
    } catch (e) {
      setState(() => _error = "Camera init error: $e");
    }
  }

  Future<void> _takePhoto() async {
    if (!_cameraReady || _cameraController == null) return;
    try {
      final file = await _cameraController!.takePicture();
      setState(() {
        _mediaFile = File(file.path);
        _isVideo = false;
      });
    } catch (e) {
      setState(() => _error = "Photo error: $e");
    }
  }

  Future<void> _startVideoRecording() async {
    if (!_cameraReady || _cameraController == null) return;
    try {
      await _cameraController!.startVideoRecording();
      setState(() => _isRecording = true);
    } catch (e) {
      setState(() => _error = "Video start error: $e");
    }
  }

  Future<void> _stopVideoRecording() async {
    if (!_isRecording || _cameraController == null) return;
    try {
      final file = await _cameraController!.stopVideoRecording();
      setState(() {
        _mediaFile = File(file.path);
        _isVideo = true;
        _isRecording = false;
      });
      await _initializeVideoPlayer(_mediaFile!);
    } catch (e) {
      setState(() => _error = "Video stop error: $e");
    }
  }

  Future<void> _initializeVideoPlayer(File file) async {
    _videoController?.dispose();
    _videoController = VideoPlayerController.file(file);
    await _videoController!.initialize();
    _videoController!.play();
    setState(() {});
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      final file = File(picked.path);
      final isVideo = picked.path.endsWith('.mp4') || picked.path.endsWith('.mov');

      setState(() {
        _mediaFile = file;
        _isVideo = isVideo;
      });

      if (isVideo) {
        await _initializeVideoPlayer(file);
      }
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2 || _cameraController == null) return;

    final currentIndex = _cameras.indexOf(_cameraController!.description);
    final nextIndex = (currentIndex + 1) % _cameras.length;

    await _startCamera(_cameras[nextIndex]);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _videoController?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderScale = _isRecording ? _pulseController.value : 1.0;
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            if (_mediaFile == null && _cameraReady)
              LayoutBuilder(
                builder: (context, constraints) {
                  if (!_cameraController!.value.isInitialized) {
                    return Container(
                      color: Theme.of(context).colorScheme.background,
                    );
                  }

                  final previewSize = _cameraController!.value.previewSize!;
                  final screenRatio = constraints.maxWidth / constraints.maxHeight;
                  final previewRatio = previewSize.height / previewSize.width;

                  return Transform.scale(
                    scale: screenRatio / previewRatio,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: previewRatio,
                        child: CameraPreview(_cameraController!),
                      ),
                    ),
                  );
                },
              ),
            if (_mediaFile != null)
              Center(
                child: _isVideo
                    ? (_videoController != null && _videoController!.value.isInitialized)
                        ? AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          )
                        : const CircularProgressIndicator()
                    : Image.file(_mediaFile!),
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: SizedBox(
                  width: double.infinity,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Gallery Icon
                      Positioned(
                        left: 30,
                        child: IconButton(
                          icon: Icon(
                            Icons.photo_library,
                            color: isDarkMode ? Colors.white : AppColors.textPrimaryLight,
                          ),
                          onPressed: _pickFromGallery,
                        ),
                      ),

                      // Capture Button
                      GestureDetector(
                        onTap: _takePhoto,
                        onLongPress: _startVideoRecording,
                        onLongPressUp: _stopVideoRecording,
                        child: ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return AppColors.primaryGradient.createShader(bounds);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 70 * borderScale,
                            height: 70 * borderScale,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDarkMode ? Colors.white : AppColors.textPrimaryLight,
                                width: 4,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Flip Camera Icon
                      Positioned(
                        right: 30,
                        child: IconButton(
                          icon: Icon(
                            Icons.flip_camera_android,
                            color: isDarkMode ? Colors.white : AppColors.textPrimaryLight,
                          ),
                          onPressed: _flipCamera,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_error != null)
              Positioned(
                top: 20,
                left: 20,
                right: 20,
                child: Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}