import 'dart:io';

import 'package:chatapp/auth/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class MyDrawer extends StatefulWidget {
  const MyDrawer({super.key});

  @override
  _MyDrawerState createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  Future<String>? _profilePicFuture;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _profilePicFuture = _getProfilePicUrl();
  }

  Future<String> _getProfilePicUrl() async {
    final userId = AuthService().getCurrentUser()!.uid;
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('Users').doc(userId).get();
    final data = userDoc.data() as Map<String, dynamic>?;

    return data?['profilePic'] ?? '';
  }

  Future<void> _uploadImage() async {
    final pickerResult = await _picker.pickImage(source: ImageSource.gallery);

    if (pickerResult == null) return;

    File imageFile = File(pickerResult.path);
    String fileName = path.basename(imageFile.path);
    final userId = AuthService().getCurrentUser()!.uid;

    try {
      // Upload image to Firebase Storage
      Reference storageReference = FirebaseStorage.instance.ref().child('profile_pictures/$userId/$fileName');
      UploadTask uploadTask = storageReference.putFile(imageFile);

      await uploadTask.whenComplete(() async {
        // Get the download URL
        String downloadURL = await storageReference.getDownloadURL();

        // Update Firestore with the new profile picture URL
        await FirebaseFirestore.instance.collection('Users').doc(userId).update({
          'profilePic': downloadURL,
        });

        // Refresh profile picture
        setState(() {
          _profilePicFuture = _getProfilePicUrl();
        });
      });
    } catch (e) {
      // Handle errors
      print('Error uploading image: $e');
    }
  }

  void _showImageUploadDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Upload Profile Picture'),
          content: Text('Choose an option to upload your profile picture.'),
          actions: [
            TextButton(
              onPressed: () {
                _uploadImage();
                Navigator.of(context).pop();
              },
              child: Text('Upload Image'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void logout(BuildContext context) async {
    await AuthService().signOut();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            FutureBuilder<String>(
              future: _profilePicFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError || !snapshot.hasData) {
                  return Container(
                    padding: EdgeInsets.all(16.0),
                    child: GestureDetector(
                      onTap: _showImageUploadDialog,
                      child: CircleAvatar(
                        backgroundColor: Colors.grey,
                        radius: 40,
                        child: Icon(Icons.person, size: 40, color: Colors.white),
                      ),
                    ),
                  );
                } else {
                  String profilePicUrl = snapshot.data!;
                  return Container(
                    padding: EdgeInsets.all(16.0),
                    child: GestureDetector(
                      onTap: _showImageUploadDialog,
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(profilePicUrl),
                        radius: 40,
                      ),
                    ),
                  );
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.only(left: 25.0),
              child: ListTile(
                title: Text("H O M E"),
                leading: Icon(Icons.home),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 25.0),
              child: ListTile(
                title: Text("S E T T I N G"),
                leading: Icon(Icons.settings),
                onTap: () {},
              ),
            ),
 
          ],
        ),
      ),
    );
  }
}
