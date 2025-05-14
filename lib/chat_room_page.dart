import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../theme/colors.dart';

class ChatRoomPage extends StatefulWidget {
  final String userId;
  final String firstName;
  final String lastName;

  const ChatRoomPage({
    Key? key,
    required this.userId,
    required this.firstName,
    required this.lastName,
  }) : super(key: key);

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  String? _audioPath;

  // Cloudinary credentials
  static const String _cloudinaryApiKey = '944496563675247';
  static const String _cloudinaryCloudName = 'dutzx1xqn';
  static const String _uploadPreset = 'insta_clone_unsigned';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollToBottom);
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    // Request microphone and storage permissions
    final micStatus = await Permission.microphone.request();
    final storageStatus = await Permission.storage.request();
    if (micStatus.isDenied || storageStatus.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone and storage permissions are required to record audio')),
        );
      }
      return;
    }
    await _recorder.openRecorder();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isNotEmpty || _audioPath != null) {
      final currentUserId = _auth.currentUser!.uid;
      final chatRoomId = ([currentUserId, widget.userId]..sort()).join('_');

      String? mediaUrl;
      String mediaType = 'text';

      if (_audioPath != null) {
        try {
          // Verify the audio file exists and is accessible
          final audioFile = File(_audioPath!);
          final exists = await audioFile.exists();
          if (!exists || (await audioFile.length()) == 0) {
            print('Audio file does not exist or is empty: $_audioPath');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to upload audio: File not found or empty')),
              );
            }
            setState(() => _audioPath = null);
            return;
          }

          print('Uploading audio to Cloudinary: $_audioPath');
          final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/auto/upload');
          final request = http.MultipartRequest('POST', url)
            ..fields['upload_preset'] = _uploadPreset
            ..fields['api_key'] = _cloudinaryApiKey
            ..files.add(await http.MultipartFile.fromPath('file', _audioPath!));
          final response = await request.send().timeout(const Duration(seconds: 30));

          if (response.statusCode == 200) {
            final responseData = await response.stream.toBytes();
            final responseString = String.fromCharCodes(responseData);
            final jsonMap = jsonDecode(responseString);
            mediaUrl = jsonMap['secure_url'] as String;
            mediaType = 'audio';
            print('Audio uploaded successfully: $mediaUrl');
          } else {
            final responseBody = await response.stream.bytesToString();
            print('Audio upload failed with status: ${response.statusCode}, Response: $responseBody');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to upload audio')),
              );
            }
            setState(() => _audioPath = null);
            return;
          }
        } catch (e, stackTrace) {
          print('Error uploading audio: $e');
          print('Stack trace: $stackTrace');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to upload audio')),
            );
          }
          setState(() => _audioPath = null);
          return;
        }
      }

      await _firestore.collection('chats').doc(chatRoomId).collection('messages').add({
        'text': _messageController.text,
        'senderId': currentUserId,
        'receiverId': widget.userId,
        'timestamp': FieldValue.serverTimestamp(),
        'seenBy': {currentUserId: true},
        'mediaType': mediaType,
        'mediaUrl': mediaUrl,
      });

      await _firestore.collection('chats').doc(chatRoomId).set({
        'lastMessage': _messageController.text.isNotEmpty ? _messageController.text : 'Audio',
        'lastTimestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _messageController.clear();
      setState(() => _audioPath = null);
      _scrollToBottom();
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxHeight: 200,
      maxWidth: 200,
    );
    if (pickedFile != null) {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['api_key'] = _cloudinaryApiKey
        ..files.add(await http.MultipartFile.fromPath('file', pickedFile.path));
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString);
        final imageUrl = jsonMap['secure_url'] as String;
        _sendMedia('image', imageUrl);
      } else {
        print('Image upload failed with status: ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image')),
          );
        }
      }
    }
  }

  Future<void> _sendMedia(String mediaType, String mediaUrl) async {
    final currentUserId = _auth.currentUser!.uid;
    final userIds = [currentUserId, widget.userId];
    userIds.sort();
    final chatRoomId = userIds.join('_');

    await _firestore.collection('chats').doc(chatRoomId).collection('messages').add({
      'text': '',
      'senderId': currentUserId,
      'receiverId': widget.userId,
      'timestamp': FieldValue.serverTimestamp(),
      'seenBy': {currentUserId: true},
      'mediaType': mediaType,
      'mediaUrl': mediaUrl,
    });

    await _firestore.collection('chats').doc(chatRoomId).set({
      'lastMessage': mediaType == 'image' ? 'Image' : 'Audio',
      'lastTimestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _scrollToBottom();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // Stop recording and ensure the file is properly saved
      final recordedPath = await _recorder.stopRecorder();
      if (recordedPath == null) {
        print('Recording failed: No audio file path returned');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to record audio')),
          );
        }
        setState(() => _isRecording = false);
        return;
      }

      final tempDir = await getTemporaryDirectory();
      _audioPath = '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';

      // Copy the recorded file to the specified path if necessary
      final recordedFile = File(recordedPath);
      if (await recordedFile.exists()) {
        await recordedFile.copy(_audioPath!);
        print('Audio file saved to: $_audioPath');
      } else {
        print('Recorded file does not exist: $recordedPath');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save recorded audio')),
          );
        }
        setState(() {
          _isRecording = false;
          _audioPath = null;
        });
        return;
      }

      setState(() => _isRecording = false);
      _sendMessage();
    } else {
      final tempDir = await getTemporaryDirectory();
      _audioPath = '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';
      await _recorder.startRecorder(
        toFile: _audioPath,
        codec: Codec.aacADTS,
      );
      setState(() => _isRecording = true);
    }
  }

  Future<void> _playAudio(String url) async {
    await _audioPlayer.play(UrlSource(url));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _audioPlayer.dispose();
    _recorder.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatRoomId = ([widget.userId, _auth.currentUser!.uid]..sort()).join('_');

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.firstName} ${widget.lastName}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isCurrentUser = message['senderId'] == _auth.currentUser!.uid;
                    final seenBy = (message['seenBy'] as Map<String, dynamic>?) ?? {};
                    final isSeen = seenBy[widget.userId] == true && !isCurrentUser;
                    final timestamp = (message['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                    final mediaUrl = message['mediaUrl'] as String?;

                    return ListTile(
                      title: Align(
                        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: EdgeInsets.all(8.0.w),
                          decoration: BoxDecoration(
                            color: isCurrentUser ? AppColors.primaryTeal : AppColors.greyLight,
                            borderRadius: BorderRadius.circular(8.0.r),
                          ),
                          child: Column(
                            crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if (message['mediaType'] == 'image')
                                Image.network(mediaUrl!, width: 200.w, height: 200.h, fit: BoxFit.cover),
                              if (message['mediaType'] == 'audio')
                                IconButton(
                                  icon: const Icon(Icons.play_arrow),
                                  onPressed: () => _playAudio(mediaUrl!),
                                ),
                              Text(
                                message['text'] ?? '',
                                style: TextStyle(
                                  color: isCurrentUser ? Colors.white : AppColors.textPrimaryLight,
                                  fontSize: 14.sp,
                                ),
                              ),
                              if (isSeen)
                                Text(
                                  'Seen at ${timestamp.toLocal().toString().substring(0, 16)}',
                                  style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0.w),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message or emoji...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0.r),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.greyDark
                          : AppColors.greyLight,
                    ),
                    style: TextStyle(fontSize: 14.sp),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.image, size: 24.0.w),
                  onPressed: _pickImage,
                ),
                IconButton(
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic, size: 24.0.w),
                  onPressed: _toggleRecording,
                ),
                IconButton(
                  icon: Icon(Icons.send, size: 24.0.w),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}