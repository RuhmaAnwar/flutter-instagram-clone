import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';

class AddPost extends StatefulWidget {
  const AddPost({super.key});

  @override
  State<AddPost> createState() => _AddPostState();
}

class _AddPostState extends State<AddPost> with SingleTickerProviderStateMixin {
  late List<CameraDescription> _cameras;
  CameraController? _controller;
  VideoPlayerController? _videoController;

  File? _mediaFile;
  bool _isVideo = false;
  bool _isRecording = false;
  bool _cameraReady = false;
  String? _error;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      lowerBound: 1.0,
      upperBound: 1.2,
    )..repeat(reverse: true);
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameraPermission = await Permission.camera.request();
    final micPermission = await Permission.microphone.request();

    if (!cameraPermission.isGranted || !micPermission.isGranted) {
      setState(() {
        _error = "Camera or microphone permission not granted.";
      });
      return;
    }

    _cameras = await availableCameras();
    if (_cameras.isNotEmpty) {
      _startCamera(_cameras.first);
    }
  }

  Future<void> _startCamera(CameraDescription camera) async {
    _controller?.dispose();
    _controller = CameraController(camera, ResolutionPreset.high);
    await _controller!.initialize();
    setState(() {
      _cameraReady = true;
    });
  }

  Future<void> _takePhoto() async {
    if (!_cameraReady || _controller == null) return;
    try {
      final file = await _controller!.takePicture();
      setState(() {
        _mediaFile = File(file.path);
        _isVideo = false;
      });
    } catch (e) {
      setState(() => _error = "Photo error: $e");
    }
  }

  Future<void> _startVideo() async {
    if (!_cameraReady || _controller == null) return;
    try {
      await _controller!.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      setState(() => _error = "Video start error: $e");
    }
  }

  Future<void> _stopVideo() async {
    if (!_isRecording || _controller == null) return;
    try {
      final file = await _controller!.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _mediaFile = File(file.path);
        _isVideo = true;
      });
      _videoController?.dispose();
      _videoController = VideoPlayerController.file(_mediaFile!)
        ..initialize().then((_) {
          setState(() {});
          _videoController!.play();
        });
    } catch (e) {
      setState(() => _error = "Video stop error: $e");
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      final file = File(picked.path);
      final isVideo =
          picked.path.endsWith('.mp4') || picked.path.endsWith('.mov');

      setState(() {
        _mediaFile = file;
        _isVideo = isVideo;
      });

      if (isVideo) {
        _videoController?.dispose();
        _videoController = VideoPlayerController.file(file)
          ..initialize().then((_) {
            setState(() {});
            _videoController!.play();
          });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _videoController?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderScale = _isRecording ? _pulseController.value : 1.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (_mediaFile == null && _cameraReady)
              LayoutBuilder(
                builder: (context, constraints) {
                  if (!_controller!.value.isInitialized)
                    return Container(color: Colors.black);

                  final previewSize = _controller!.value.previewSize!;
                  final screenRatio =
                      constraints.maxWidth / constraints.maxHeight;
                  final previewRatio = previewSize.height / previewSize.width;

                  return Transform.scale(
                    scale: screenRatio / previewRatio,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: previewRatio,
                        child: CameraPreview(_controller!),
                      ),
                    ),
                  );
                },
              ),

            if (_mediaFile != null)
              Center(
                child:
                    _isVideo
                        ? (_videoController != null &&
                                _videoController!.value.isInitialized)
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
                      // Gallery Icon (Left)
                      Positioned(
                        left: 30,
                        child: IconButton(
                          icon: const Icon(
                            Icons.photo_library,
                            color: Colors.white,
                          ),
                          onPressed: _pickFromGallery,
                        ),
                      ),

                      // Capture Button (Center)
                      GestureDetector(
                        onTap: _takePhoto,
                        onLongPress: _startVideo,
                        onLongPressUp: _stopVideo,
                        child: ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return const LinearGradient(
                              colors: [
                                Color(0xFFFFFFFF),
                                Color(0xFF006262),
                                Color(0xFFFF7F50),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width:
                                70 *
                                (_isRecording ? _pulseController.value : 1.0),
                            height:
                                70 *
                                (_isRecording ? _pulseController.value : 1.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                          ),
                        ),
                      ),

                      // Flip Camera Icon (Right)
                      Positioned(
                        right: 30,
                        child: IconButton(
                          icon: const Icon(
                            Icons.flip_camera_android,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            if (_cameras.length > 1) {
                              final nextIndex =
                                  (_cameras.indexOf(_controller!.description) +
                                      1) %
                                  _cameras.length;
                              _startCamera(_cameras[nextIndex]);
                            }
                          },
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
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
