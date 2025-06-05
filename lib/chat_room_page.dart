import 'dart:async';
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
import 'package:photo_view/photo_view.dart';
import '../theme/colors.dart';

class ChatRoomPage extends StatefulWidget {
  final String userId;
  final String firstName;
  final String lastName;

  const ChatRoomPage({
    super.key,
    required this.userId,
    required this.firstName,
    required this.lastName,
  });

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
  bool _isOtherUserTyping = false;
  Timer? _typingTimer;
  StreamSubscription<DocumentSnapshot>? _typingSubscription;

  // Cloudinary credentials
  static const String _cloudinaryApiKey = '944496563675247';
  static const String _cloudinaryCloudName = 'dutzx1xqn';
  static const String _uploadPreset = 'insta_clone_unsigned';

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
    final chatRoomId = _getChatRoomId();
    // Initialize chat with members field
    _firestore.collection('chats').doc(chatRoomId).set({
      'members': [_auth.currentUser!.uid, widget.userId],
      'isTyping': {
        _auth.currentUser!.uid: false,
        widget.userId: false,
      },
      'lastMessage': '',
      'lastTimestamp': null,
    }, SetOptions(merge: true));

    // Subscribe to typing status updates
    _typingSubscription = _firestore.collection('chats').doc(chatRoomId).snapshots().listen((snapshot) {
      if (snapshot.exists && mounted) {
        final data = snapshot.data() as Map<String, dynamic>?;
        final isTyping = data?['isTyping'] ?? {};
        setState(() {
          _isOtherUserTyping = isTyping[widget.userId] == true;
        });
      }
    });
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
        'isDeletedFor': [],
      });

      final currentDoc = await _firestore.collection('chats').doc(chatRoomId).get();
      final currentIsTyping = currentDoc.data()?['isTyping'] as Map<String, dynamic>? ?? {};
      await _firestore.collection('chats').doc(chatRoomId).set({
        'members': [_auth.currentUser!.uid, widget.userId],
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
      'isDeletedFor': [],
    });

    await _firestore.collection('chats').doc(chatRoomId).set({
      'members': [_auth.currentUser!.uid, widget.userId],
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
      setState(() => _audioPath = null);
      final tempDir = await getTemporaryDirectory();
      _audioPath = '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';
      await _recorder.startRecorder(toFile: _audioPath, codec: Codec.aacADTS);
      setState(() => _isRecording = true);
    }
  }

  Future<String> _getAudioDuration(String url) async {
    try {
      await _audioPlayer.setSource(UrlSource(url));
      final duration = await _audioPlayer.getDuration();
      if (duration != null) {
        final minutes = duration.inMinutes;
        final seconds = duration.inSeconds % 60;
        return '$minutes:${seconds.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      // Handle error silently
    }
    return '0:00';
  }

  Future<void> _playAudio(String url) async {
    await _audioPlayer.play(UrlSource(url));
  }

  Future<void> _deleteMessage(String messageId, {bool forEveryone = false}) async {
    final chatRoomId = _getChatRoomId();
    await _firestore.runTransaction((transaction) async {
      final messageRef = _firestore.collection('chats').doc(chatRoomId).collection('messages').doc(messageId);
      final messageDoc = await transaction.get(messageRef);
      if (!messageDoc.exists) return;

      final messageData = messageDoc.data()!;
      final timestamp = (messageData['timestamp'] as Timestamp?)?.toDate();
      final senderId = messageData['senderId'] as String? ?? '';

      if (forEveryone) {
        if (senderId != _auth.currentUser!.uid) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Only the sender can delete for everyone')),
            );
          }
          return;
        }
        if (timestamp != null && DateTime.now().difference(timestamp).inHours > 1) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You can only delete for everyone within 1 hour')),
            );
          }
          return;
        }
        transaction.delete(messageRef);
        final messagesSnapshot = await _firestore
            .collection('chats')
            .doc(chatRoomId)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();
        if (messagesSnapshot.docs.isNotEmpty) {
          final lastMessage = messagesSnapshot.docs.first.data();
          transaction.update(_firestore.collection('chats').doc(chatRoomId), {
            'lastMessage': lastMessage['text'].isNotEmpty
                ? lastMessage['text']
                : lastMessage['mediaType'] == 'image'
                    ? 'Image'
                    : 'Audio',
            'lastTimestamp': lastMessage['timestamp'],
          });
        } else {
          transaction.update(_firestore.collection('chats').doc(chatRoomId), {
            'lastMessage': '',
            'lastTimestamp': null,
          });
        }
      } else {
        transaction.update(messageRef, {
          'isDeletedFor': FieldValue.arrayUnion([_auth.currentUser!.uid]),
        });
      }
    });
  }

  void _showDeleteOptions(String messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Choose an option:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(messageId, forEveryone: false);
            },
            child: const Text('Delete for Me'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(messageId, forEveryone: true);
            },
            child: const Text('Delete for Everyone'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImage(imageUrl: imageUrl),
      ),
    );
  }

  @override
  void dispose() {
    _typingSubscription?.cancel();
    _scrollController.dispose();
    _messageController.dispose();
    _audioPlayer.dispose();
    _recorder.closeRecorder();
    _typingTimer?.cancel();
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
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!.docs;
                for (var doc in messages) {
                  final seenBy = (doc['seenBy'] as Map<String, dynamic>?) ?? {};
                  if (doc['senderId'] != _auth.currentUser!.uid && !seenBy[widget.userId] == true) {
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
                    final isCurrentUser = (message['senderId'] as String? ?? '') == _auth.currentUser!.uid;
                    final seenBy = (message['seenBy'] as Map<String, dynamic>?) ?? {};
                    final isSeen = seenBy[widget.userId] == true && isCurrentUser;
                    final timestamp = (message['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                    final mediaUrl = message['mediaUrl'] as String?;
                    final mediaType = message['mediaType'] as String? ?? 'text';
                    final isDeletedFor = (message['isDeletedFor'] as List<dynamic>?) ?? [];

                    if (isDeletedFor.contains(_auth.currentUser!.uid)) {
                      return const SizedBox.shrink();
                    }

                    return GestureDetector(
                      onLongPress: () => _showDeleteOptions(message.id),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.h),
                        child: Align(
                          alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if (mediaType == 'image' && mediaUrl != null)
                                GestureDetector(
                                  onTap: () => _showFullScreenImage(mediaUrl),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12.r),
                                    child: Image.network(
                                      mediaUrl,
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
                                      errorBuilder: (context, error, stackTrace) => Column(
                                        children: [
                                          const Icon(Icons.error),
                                          TextButton(
                                            onPressed: () => setState(() {}),
                                            child: const Text('Retry'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              if (mediaType != 'image')
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
                                    child: Wrap(
                                      children: [
                                        if (mediaType == 'audio' && mediaUrl != null)
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
                                                onPressed: () => _playAudio(mediaUrl),
                                                padding: EdgeInsets.zero,
                                                constraints: BoxConstraints(),
                                              ),
                                              SizedBox(width: 8.w),
                                              FutureBuilder<String>(
                                                future: _getAudioDuration(mediaUrl),
                                                builder: (context, snapshot) {
                                                  return Text(
                                                    snapshot.data ?? '0:00',
                                                    style: TextStyle(
                                                      color: isCurrentUser
                                                          ? Colors.white
                                                          : isDarkMode
                                                              ? AppColors.textPrimaryDark
                                                              : AppColors.textPrimaryLight,
                                                      fontSize: 14.sp,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        if (message['text'] != null && (message['text'] as String).isNotEmpty)
                                          Padding(
                                            padding: EdgeInsets.only(top: mediaType != 'text' ? 8.h : 0),
                                            child: Text(
                                              message['text'] as String,
                                              style: TextStyle(
                                                color: isCurrentUser
                                                    ? Colors.white
                                                    : isDarkMode
                                                        ? AppColors.textPrimaryDark
                                                        : AppColors.textPrimaryLight,
                                                fontSize: 14.sp,
                                              ),
                                              softWrap: true,
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
                  if (_isOtherUserTyping)
                    Padding(
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
                                width: 1.0.w,
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
                            fillColor: isDarkMode ? AppColors.greyBorderDark : AppColors.greyBorderLight,
                            contentPadding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 13.5.h),
                            suffixIcon: Padding(
                              padding: EdgeInsets.only(right: 8.w),
                              child: Row(
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
                          ),
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: isDarkMode
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                          onChanged: (value) {
                            _typingTimer?.cancel();
                            _typingTimer = Timer(const Duration(milliseconds: 500), () {
                              final chatRoomId = _getChatRoomId();
                              _firestore.collection('chats').doc(chatRoomId).set({
                                'members': [_auth.currentUser!.uid, widget.userId],
                                'isTyping': {
                                  _auth.currentUser!.uid: value.isNotEmpty,
                                },
                              }, SetOptions(merge: true));
                              print('Typing status updated for ${_auth.currentUser!.uid}: ${value.isNotEmpty}');
                            });
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

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Stack(
        children: [
          Center(
            child: PhotoView(
              imageProvider: NetworkImage(imageUrl),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
              initialScale: PhotoViewComputedScale.contained,
              backgroundDecoration: BoxDecoration(
                color: isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
              ),
            ),
          ),
          Positioned(
            top: 40.h,
            left: 16.w,
            child: IconButton(
              icon: Icon(Icons.close, size: 28.sp, color: isDarkMode ? AppColors.textPrimaryDark : Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}