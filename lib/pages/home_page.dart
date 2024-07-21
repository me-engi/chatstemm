import 'package:chatapp/auth/auth_service.dart';
import 'package:chatapp/auth/chat_service.dart';
import 'package:chatapp/pages/chat_Page.dart';
import 'package:chatapp/widget/drawer.dart';
import 'package:chatapp/widget/user_tile.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  void logout(BuildContext context) async {
    await _authService.signOut();
    // Optionally, you can add navigation to the login page or show a logout confirmation
    // Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          IconButton(
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: const MyDrawer(),
      body: _buildUserList(),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _chatService.getUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading users"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No users available"));
        }

        return ListView(
          children: snapshot.data!
              .where((userData) => userData["email"] != _authService.getCurrentUser()!.email)
              .map<Widget>((userData) => _buildUserListItem(userData, context))
              .toList(),
        );
      },
    );
  }

  Widget _buildUserListItem(Map<String, dynamic> userData, BuildContext context) {
    return UserTile(
      text: userData["email"],
      profilePicUrl: userData["profilePic"] ?? '',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              receiverEmail: userData["email"],
              receiverID: userData["uid"],
            ),
          ),
        );
      },
      onProfilePicTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenImage(imageUrl: userData["profilePic"] ?? ''),
          ),
        );
      },
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: InteractiveViewer(
          child: imageUrl.isNotEmpty
              ? Image.network(imageUrl)
              : const Icon(Icons.image_not_supported, color: Colors.white, size: 100),
        ),
      ),
    );
  }
}
