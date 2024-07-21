import 'dart:io';

import 'package:chatapp/models/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get users stream
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection("Users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        // Ensure required fields are included and provide default values if not present
        return {
          'email': data['email'] ?? '',
          'uid': data['uid'] ?? '',
          'profilePic': data['profilePic'] ?? '', // Default empty string if profilePic is not present
        };
      }).toList();
    }).handleError((error) {
      // Handle any errors that occur while fetching or processing the data
      print('Error in getUsersStream: $error');
      return []; // Return an empty list on error
    });
  }

  // Send message
  Future<void> sendMessage(String receiverID, String message,
      {String? mediaUrl, String? mediaType}) async {
    final String currentUserID = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    Message newMessage = Message(
      senderId: currentUserID,
      senderEmail: currentUserEmail,
      receiverId: receiverID,
      message: message,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      timestamp: timestamp.toDate(),
    );

    List<String> ids = [currentUserID, receiverID];
    ids.sort();
    String chatRoomID = ids.join('_');

    await _firestore.collection('chat_rooms').doc(chatRoomID).collection('messages').add(newMessage.toMap());
  }

  // Get messages stream
  Stream<QuerySnapshot> getMessages(String userID, String otherUserID) {
    List<String> ids = [userID, otherUserID];
    ids.sort();
    String chatRoomID = ids.join('_');
    return _firestore.collection('chat_rooms').doc(chatRoomID).collection('messages').orderBy('timestamp', descending: false).snapshots();
  }

  // Report a user
  Future<void> reportUser(String reportedUserID, String reason) async {
    final String reporterID = _auth.currentUser!.uid;
    final Timestamp timestamp = Timestamp.now();

    await _firestore.collection('user_reports').add({
      'reporterId': reporterID,
      'reportedUserId': reportedUserID,
      'reason': reason,
      'timestamp': timestamp,
    });
  }

  // Block a user
  Future<void> blockUser(String userID) async {
    final String currentUserID = _auth.currentUser!.uid;

    await _firestore.collection('users').doc(currentUserID).collection('blocked_users').doc(userID).set({
      'blockedAt': Timestamp.now(),
    });
  }

  // Unblock a user
  Future<void> unblockUser(String userID) async {
    final String currentUserID = _auth.currentUser!.uid;

    await _firestore.collection('users').doc(currentUserID).collection('blocked_users').doc(userID).delete();
  }

  // Get blocked users
  Stream<List<Map<String, dynamic>>> getBlockedUsers() {
    final String currentUserID = _auth.currentUser!.uid;

    return _firestore.collection('users').doc(currentUserID).collection('blocked_users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();
        return user;
      }).toList();
    });
  }

  // Delete a message
  Future<void> deleteMessage(String chatRoomID, String messageID) async {
    await _firestore.collection('chat_rooms').doc(chatRoomID).collection('messages').doc(messageID).delete();
  }

  // Check if a user is blocked
  Future<bool> isUserBlocked(String userID, String otherUserID) async {
    final userDoc = await _firestore
        .collection('users')
        .doc(userID)
        .collection('blocked_users')
        .doc(otherUserID)
        .get();
    return userDoc.exists;
  }

  // Pick and upload media
  Future<String> _uploadFile(XFile file) async {
    final String fileName = file.name;
    final Reference storageRef = _storage.ref().child('chat_media').child(fileName);
    final UploadTask uploadTask = storageRef.putFile(File(file.path));
    final TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  }

  // Pick and send image
  Future<void> pickAndSendImage(String receiverID) async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final String url = await _uploadFile(file);
      sendMessage(receiverID, '', mediaUrl: url, mediaType: 'image');
    }
  }

  // Pick and send video
  Future<void> pickAndSendVideo(String receiverID) async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickVideo(source: ImageSource.gallery);
    if (file != null) {
      final String url = await _uploadFile(file);
      sendMessage(receiverID, '', mediaUrl: url, mediaType: 'video');
    }
  }

  // Pick and send document
  Future<void> pickAndSendDocument(String receiverID, BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      int fileSize = await file.length();

      if (fileSize <= 200 * 1024) { // Check if the file size is less than or equal to 200 KB
        try {
          final String url = await _uploadFile(XFile(file.path)); // Convert File to XFile
          sendMessage(receiverID, '', mediaUrl: url, mediaType: 'document');
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Error uploading file: ${e.toString()}"),
          ));
        }
      } else {
        // Handle the case where the file is larger than 200 KB
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("File size exceeds 200 KB. Please select a smaller file."),
        ));
      }
    }
  }
}
