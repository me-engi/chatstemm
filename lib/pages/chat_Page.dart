import 'dart:io';

import 'package:chatapp/auth/auth_service.dart';
import 'package:chatapp/auth/chat_service.dart';
import 'package:chatapp/widget/drawer.dart';
import 'package:chatapp/widget/textfield.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this package
import 'package:video_player/video_player.dart';

import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart';
import 'package:dio/dio.dart';


class ChatPage extends StatefulWidget {
  final String receiverEmail;
  final String receiverID;

  ChatPage({super.key, required this.receiverEmail, required this.receiverID});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  bool _isBlocked = false;

  @override
  void initState() {
    super.initState();
    _checkBlockStatus();
  }

  Future<void> _checkBlockStatus() async {
    final String currentUserID = _authService.getCurrentUser()!.uid;
    bool isBlocked = await _chatService.isUserBlocked(currentUserID, widget.receiverID);
    setState(() {
      _isBlocked = isBlocked;
    });
  }

  void sendMessage({String? mediaUrl, String? mediaType}) async {
    if (_messageController.text.isNotEmpty || mediaUrl != null) {
      if (!_isBlocked) {
        await _chatService.sendMessage(
          widget.receiverID,
          _messageController.text,
          mediaUrl: mediaUrl,
          mediaType: mediaType,
        );
        _messageController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("You cannot send messages to this user."),
        ));
      }
    }
  }

  Future<void> _pickMedia(String mediaType) async {
    if (mediaType == 'image') {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        final String url = await _uploadFile(file);
        sendMessage(mediaUrl: url, mediaType: mediaType);
      }
    } else if (mediaType == 'video') {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickVideo(source: ImageSource.gallery);
      if (file != null) {
        final String url = await _uploadFile(file);
        sendMessage(mediaUrl: url, mediaType: mediaType);
      }
    } else if (mediaType == 'document') {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        int fileSize = await file.length();

        if (fileSize <= 200 * 1024) { // Check if the file size is less than or equal to 200 KB
          try {
            final String url = await _uploadFile(XFile(file.path));
            sendMessage(mediaUrl: url, mediaType: mediaType);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Error uploading file: ${e.toString()}"),
            ));
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("File size exceeds 200 KB. Please select a smaller file."),
          ));
        }
      }
    }
  }

  Future<String> _uploadFile(XFile file) async {
    final String fileName = file.name;
    final Reference storageRef = FirebaseStorage.instance.ref().child('chat_media').child(fileName);
    final UploadTask uploadTask = storageRef.putFile(File(file.path));
    final TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  }

  void deleteMessage(String messageID) async {
    final String currentUserID = _authService.getCurrentUser()!.uid;
    List<String> ids = [currentUserID, widget.receiverID];
    ids.sort();
    String chatRoomID = ids.join('_');
    await _chatService.deleteMessage(chatRoomID, messageID);
  }

  void blockUser() async {
    await _chatService.blockUser(widget.receiverID);
    setState(() {
      _isBlocked = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("User blocked successfully."),
    ));
  }

  void unblockUser() async {
    await _chatService.unblockUser(widget.receiverID);
    setState(() {
      _isBlocked = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("User unblocked successfully."),
    ));
  }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverEmail),
        actions: [
          
          if (_isBlocked)
            IconButton(
              icon: Icon(Icons.circle),
              onPressed: () => _showUnblockConfirmationDialog(),
            ),
          if (!_isBlocked)
            IconButton(
              icon: Icon(Icons.block),
              onPressed: () => _showBlockConfirmationDialog(),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildUserInput(),
        ],
      ),
       // Add the drawer to the Scaffold
    );
  }


  Widget _buildMessageList() {
    String senderID = _authService.getCurrentUser()!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getMessages(senderID, widget.receiverID),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No messages yet."));
        }

        return ListView(
          children: snapshot.data!.docs.map((doc) {
            return _buildMessageItem(doc);
          }).toList(),
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String messageID = doc.id;

    bool isCurrentUser = data['senderId'] == _authService.getCurrentUser()!.uid;

    return GestureDetector(
      onLongPress: () {
        _showDeleteConfirmationDialog(messageID);
      },
      child: Align(
        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isCurrentUser ? Colors.blue[100] : Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data['mediaUrl'] != null)
                _buildMediaContent(data['mediaUrl'], data['mediaType']),
              if (data['message'] != null && data['message'].isNotEmpty)
                Text(data['message']),
              SizedBox(height: 5),
              Text(
                data['senderEmail'],
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaContent(String mediaUrl, String mediaType) {
    if (mediaType == 'image') {
      return Image.network(mediaUrl);
    } else if (mediaType == 'video') {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => VideoPlayerScreen(videoUrl: mediaUrl)),
          );
        },
        child: Container(
          color: Colors.black12,
          child: Center(
            child: Icon(Icons.play_circle_filled, color: Colors.white, size: 50),
          ),
        ),
      );
    } else if (mediaType == 'document') {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DocumentViewerScreen(documentUrl: mediaUrl)),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Document:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(mediaUrl, style: TextStyle(color: Colors.blue)),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _downloadDocument(mediaUrl),
              child: Text('Download Document'),
            ),
          ],
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  void _downloadDocument(String url) async {
    try {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not download the document.'),
        ),
      );
    }
  }

  Widget _buildUserInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.image),
            onPressed: () => _pickMedia('image'),
          ),
          IconButton(
            icon: Icon(Icons.videocam),
            onPressed: () => _pickMedia('video'),
          ),
          
          Expanded(
            child: IgnorePointer(
              ignoring: _isBlocked,
              child: CustomTextfield(
                controller: _messageController,
                hintText: "Type a message",
                obscureText: false,
              ),
            ),
          ),
          IconButton(
            onPressed: () => sendMessage(),
            icon: Icon(Icons.arrow_upward),
            color: _isBlocked ? Colors.grey : null,
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(String messageID) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Message"),
          content: Text("Are you sure you want to delete this message?"),
          actions: [
            TextButton(
              onPressed: () {
                deleteMessage(messageID);
                Navigator.of(context).pop();
              },
              child: Text("Delete"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  void _showBlockConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Block User"),
          content: Text("Are you sure you want to block this user?"),
          actions: [
            TextButton(
              onPressed: () {
                blockUser();
                Navigator.of(context).pop();
              },
              child: Text("Block"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  void _showUnblockConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Unblock User"),
          content: Text("Are you sure you want to unblock this user?"),
          actions: [
            TextButton(
              onPressed: () {
                unblockUser();
                Navigator.of(context).pop();
              },
              child: Text("Unblock"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }
}

class VideoPlayerScreen extends StatelessWidget {
  final String videoUrl;

  VideoPlayerScreen({required this.videoUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Video Player')),
      body: Center(
        child: VideoPlayerWidget(videoUrl: videoUrl),
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  VideoPlayerWidget({required this.videoUrl});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        : Center(child: CircularProgressIndicator());
  }
}

class DocumentViewerScreen extends StatelessWidget {
  final String documentUrl;

  DocumentViewerScreen({required this.documentUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Document Viewer')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Document URL: $documentUrl'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _openDocument(context),
              child: Text('Open Document'),
            ),
          ],
        ),
      ),
    );
  }

  void _openDocument(BuildContext context) async {
    try {
      if (await canLaunch(documentUrl)) {
        await launch(documentUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open the document.'),
          ),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open the document.'),
        ),
      );
    }
  }
}

class PDFViewWidget extends StatefulWidget {
  final String pdfUrl;

  PDFViewWidget({required this.pdfUrl});

  @override
  _PDFViewWidgetState createState() => _PDFViewWidgetState();
}

class _PDFViewWidgetState extends State<PDFViewWidget> {
  String? _localFilePath;

  @override
  void initState() {
    super.initState();
    _downloadAndSavePDF();
  }

Future<void> _downloadAndSavePDF() async {
  try {
    final dio = Dio();
    final response = await dio.get(
      widget.pdfUrl,
      options: Options(responseType: ResponseType.bytes),
    );

    if (response.statusCode == 200) {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);

      // Write the bytes to the file
      await file.writeAsBytes(response.data as List<int>);
      
      setState(() {
        _localFilePath = filePath;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download PDF.'),
        ),
      );
    }
  } catch (e) {
    print('Error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error downloading PDF: $e'),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return _localFilePath == null
        ? Center(child: CircularProgressIndicator())
        : Container(
            height: 600, // Adjust height according to your needs
            child: PDFView(
              filePath: _localFilePath,
              enableSwipe: true,
              swipeHorizontal: true,
              autoSpacing: false,
              pageFling: true,
              pageSnap: true,
              defaultPage: 0,
              fitPolicy: FitPolicy.BOTH,
              onRender: (_pages) {},
              onError: (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error loading PDF: $error'),
                  ),
                );
              },
              onPageError: (page, error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error loading page $page: $error'),
                  ),
                );
              },
            ),
          );
  }
}

