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
    _initializeRecorder();
    final chatRoomId = _getChatRoomId();
    _firestore.collection('chats').doc(chatRoomId).set({
      'isTyping': {
        _auth.currentUser!.uid: false,
        widget.userId: false,
      },
    }, SetOptions(merge: true));
  }

  Future<void> _initializeRecorder() async {
    final micStatus = await Permission.microphone.request();
    final storageStatus = await Permission.storage.request();
    if (micStatus.isDenied || storageStatus.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone and storage permissions are required')),
        );
      }
      return;
    }
    await _recorder.openRecorder();
  }

  String _getChatRoomId() => ([_auth.currentUser!.uid, widget.userId]..sort()).join('_');

  void _scrollToBottom() {
    if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isNotEmpty || _audioPath != null) {
      final chatRoomId = _getChatRoomId();
      String? mediaUrl;
      String mediaType = 'text';

      if (_audioPath != null) {
        final audioFile = File(_audioPath!);
        if (!(await audioFile.exists()) || (await audioFile.length()) == 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to upload audio: File not found or empty')),
            );
          }
          setState(() => _audioPath = null);
          return;
        }

        final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/upload');
        final request = http.MultipartRequest('POST', url)
          ..fields['upload_preset'] = _uploadPreset
          ..fields['api_key'] = _cloudinaryApiKey
          ..files.add(await http.MultipartFile.fromPath('file', _audioPath!));
        final response = await request.send().timeout(const Duration(seconds: 30));
        final responseBody = await response.stream.bytesToString();
        final jsonMap = jsonDecode(responseBody);
        if (response.statusCode == 200 && jsonMap['secure_url'] != null) {
          mediaUrl = jsonMap['secure_url'] as String;
          mediaType = 'audio';
        } else {
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
        'senderId': _auth.currentUser!.uid,
        'receiverId': widget.userId,
        'timestamp': FieldValue.serverTimestamp(),
        'seenBy': {_auth.currentUser!.uid: true},
        'mediaType': mediaType,
        'mediaUrl': mediaUrl,
      });

      final currentDoc = await _firestore.collection('chats').doc(chatRoomId).get();
      final currentIsTyping = currentDoc.data()?['isTyping'] as Map<String, dynamic>? ?? {};
      await _firestore.collection('chats').doc(chatRoomId).set({
        'lastMessage': _messageController.text.isNotEmpty ? _messageController.text : 'Audio',
        'lastTimestamp': FieldValue.serverTimestamp(),
        'isTyping': {
          _auth.currentUser!.uid: false,
          widget.userId: currentIsTyping[widget.userId] ?? false,
        },
      }, SetOptions(merge: true));

      _messageController.clear();
      setState(() => _audioPath = null);
      _scrollToBottom();
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxHeight: 800,
      maxWidth: 800,
    );
    if (pickedFile != null) {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['api_key'] = _cloudinaryApiKey
        ..files.add(await http.MultipartFile.fromPath('file', pickedFile.path));
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonMap = jsonDecode(responseData);
        final imageUrl = jsonMap['secure_url'] as String;
        _sendMedia('image', imageUrl);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image')),
          );
        }
      }
    }
  }

  Future<void> _sendMedia(String mediaType, String mediaUrl) async {
    final chatRoomId = _getChatRoomId();
    await _firestore.collection('chats').doc(chatRoomId).collection('messages').add({
      'text': '',
      'senderId': _auth.currentUser!.uid,
      'receiverId': widget.userId,
      'timestamp': FieldValue.serverTimestamp(),
      'seenBy': {_auth.currentUser!.uid: true},
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
      final recordedPath = await _recorder.stopRecorder();
      if (recordedPath == null) {
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
      final recordedFile = File(recordedPath);
      if (await recordedFile.exists()) {
        await recordedFile.copy(_audioPath!);
      } else {
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
      await _recorder.startRecorder(toFile: _audioPath, codec: Codec.aacADTS);
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
    final chatRoomId = _getChatRoomId();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.firstName} ${widget.lastName}',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
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
                for (var doc in messages) {
                  if (doc['senderId'] != _auth.currentUser!.uid && !doc['seenBy'][widget.userId]) {
                    doc.reference.update({'seenBy.${widget.userId}': true});
                  }
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isCurrentUser = message['senderId'] == _auth.currentUser!.uid;
                    final seenBy = (message['seenBy'] as Map<String, dynamic>?) ?? {};
                    final isSeen = seenBy[widget.userId] == true && isCurrentUser;
                    final timestamp = (message['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                    final mediaUrl = message['mediaUrl'] as String?;

                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Align(
                        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (message['mediaType'] == 'image')
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12.r),
                                child: Image.network(
                                  mediaUrl!,
                                  width: 200.w,
                                  height: 200.h,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                (loadingProgress.expectedTotalBytes ?? 1)
                                            : null,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                                ),
                              ),
                            if (message['mediaType'] != 'image')
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                                ),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                  decoration: BoxDecoration(
                                    color: isCurrentUser
                                        ? AppColors.primaryTeal
                                        : isDarkMode
                                            ? AppColors.greyDark
                                            : AppColors.greyLight,
                                    border: Border.all(
                                      color: isCurrentUser
                                          ? AppColors.primaryTeal
                                          : isDarkMode
                                              ? AppColors.greyBorderDark
                                              : AppColors.greyBorderLight,
                                      width: 1.5.w,
                                    ),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      if (message['mediaType'] == 'audio')
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                Icons.play_arrow,
                                                size: 24.sp,
                                                color: isCurrentUser
                                                    ? Colors.white
                                                    : isDarkMode
                                                        ? AppColors.greyBorderDark
                                                        : AppColors.greyBorderLight,
                                              ),
                                              onPressed: () => _playAudio(mediaUrl!),
                                              padding: EdgeInsets.zero,
                                              constraints: BoxConstraints(),
                                            ),
                                            SizedBox(width: 8.w),
                                            Text(
                                              '1:02',
                                              style: TextStyle(
                                                color: isCurrentUser
                                                    ? Colors.white
                                                    : isDarkMode
                                                        ? AppColors.textPrimaryDark
                                                        : AppColors.textPrimaryLight,
                                                fontSize: 14.sp,
                                              ),
                                            ),
                                          ],
                                        ),
                                      if (message['text'] != null && message['text'].isNotEmpty)
                                        Padding(
                                          padding: EdgeInsets.only(top: message['mediaType'] != 'text' ? 8.h : 0),
                                          child: Text(
                                            message['text'],
                                            style: TextStyle(
                                              color: isCurrentUser
                                                  ? Colors.white
                                                  : isDarkMode
                                                      ? AppColors.textPrimaryDark
                                                      : AppColors.textPrimaryLight,
                                              fontSize: 14.sp,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            if (isSeen)
                              Padding(
                                padding: EdgeInsets.only(
                                  top: 2.h,
                                  left: isCurrentUser ? 0 : 16.w,
                                  right: isCurrentUser ? 16.w : 0,
                                ),
                                child: Text(
                                  'Seen at ${timestamp.toLocal().toString().substring(0, 16)}',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: isCurrentUser
                                        ? Colors.white70
                                        : isDarkMode
                                            ? AppColors.greyBorderDark
                                            : AppColors.greyBorderLight,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            color: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: SafeArea(
              child: Column(
                children: [
                  StreamBuilder<DocumentSnapshot>(
                    stream: _firestore.collection('chats').doc(chatRoomId).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final data = snapshot.data!.data() as Map<String, dynamic>?;
                        final isTyping = data?['isTyping'] as Map<String, dynamic>?;
                        final isOtherUserTyping = isTyping?[widget.userId] == true;
                        if (isOtherUserTyping) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: 8.h),
                            child: Row(
                              children: [
                                Text(
                                  'Typing...',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: isDarkMode
                                        ? AppColors.greyBorderDark
                                        : AppColors.greyBorderLight,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type a message or emoji...',
                            hintStyle: TextStyle(
                              color: isDarkMode
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                              fontSize: 14.sp,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: BorderSide(
                                color: isDarkMode
                                    ? AppColors.greyBorderDark
                                    : AppColors.greyBorderLight,
                                width: 1.5.w,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: BorderSide(
                                color: isDarkMode
                                    ? AppColors.greyBorderDark
                                    : AppColors.greyBorderLight,
                                width: 1.5.w,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: BorderSide(
                                color: isDarkMode
                                    ? AppColors.greyBorderDark
                                    : AppColors.greyBorderLight,
                                width: 1.5.w,
                              ),
                            ),
                            filled: true,
                            fillColor: isDarkMode ? AppColors.greyDark : AppColors.greyLight,
                            contentPadding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 13.5.h),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.image,
                                    size: 24.sp,
                                    color: AppColors.primaryTeal,
                                  ),
                                  onPressed: _pickImage,
                                ),
                                IconButton(
                                  icon: Icon(
                                    _isRecording ? Icons.stop : Icons.mic,
                                    size: 24.sp,
                                    color: AppColors.primaryTeal,
                                  ),
                                  onPressed: _toggleRecording,
                                ),
                              ],
                            ),
                          ),
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: isDarkMode
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                          onChanged: (value) {
                            final chatRoomId = _getChatRoomId();
                            _firestore.collection('chats').doc(chatRoomId).set({
                              'isTyping': {
                                _auth.currentUser!.uid: value.isNotEmpty,
                                widget.userId: false,
                              },
                            }, SetOptions(merge: true));
                          },
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Material(
                        color: AppColors.primaryTeal,
                        borderRadius: BorderRadius.circular(8.r),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8.r),
                          onTap: _sendMessage,
                          child: Container(
                            padding: EdgeInsets.all(8.w),
                            child: Icon(Icons.send, size: 24.sp, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}