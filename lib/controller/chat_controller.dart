import 'dart:async';

import 'package:chatapp/auth/chat_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatController extends GetxController {
  final String receiverID;
  final String receiverEmail;
  final ChatService chatService = ChatService();
  final TextEditingController messageController = TextEditingController();

  final FirebaseAuth authService = FirebaseAuth.instance;

  var messages = <QueryDocumentSnapshot>[].obs;
  var isBlocked = false.obs;
  late StreamSubscription<QuerySnapshot> messageSubscription;

  ChatController({
    required this.receiverID,
    required this.receiverEmail,
  });

  @override
  void onInit() {
    super.onInit();
    _loadMessages();
    _checkIfBlocked();
  }

  void _loadMessages() {
    final currentUser = authService.currentUser;
    if (currentUser == null) return;

    messageSubscription = chatService
        .getMessages(currentUser.uid, receiverID)
        .listen((snapshot) {
      messages.assignAll(snapshot.docs);
    });
  }

  void _checkIfBlocked() async {
    final currentUser = authService.currentUser;
    if (currentUser == null) return;

    isBlocked.value = await chatService.isUserBlocked(currentUser.uid, receiverID);
  }

  void sendMessage() {
    if (messageController.text.trim().isEmpty) return;

    final currentUser = authService.currentUser;
    if (currentUser == null) return;

    chatService.sendMessage(receiverID, messageController.text.trim());
    messageController.clear();
  }

  void pickMedia(String mediaType) {
    if (mediaType == 'image') {
      chatService.pickAndSendImage(receiverID);
    } else if (mediaType == 'video') {
      chatService.pickAndSendVideo(receiverID);
    } else if (mediaType == 'document') {
      chatService.pickAndSendDocument(receiverID, Get.context!);
    }
  }

  void deleteMessage(String messageID) {
    final currentUser = authService.currentUser;
    if (currentUser == null) return;

    List<String> ids = [currentUser.uid, receiverID];
    ids.sort();
    String chatRoomID = ids.join('_');

    chatService.deleteMessage(chatRoomID, messageID);
  }

  void blockUser() {
    chatService.blockUser(receiverID);
    isBlocked.value = true;
  }

  void unblockUser() {
    chatService.unblockUser(receiverID);
    isBlocked.value = false;
  }

  @override
  void dispose() {
    messageSubscription.cancel();
    messageController.dispose();
    super.dispose();
  }
}
