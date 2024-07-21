import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      _firestore.collection("Users").doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
      }, SetOptions(merge: true)); // Merge to avoid overwriting
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception('Failed to sign in: ${e.message}');
    } catch (e) {
      throw Exception('An unknown error occurred');
    }
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      _firestore.collection("Users").doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
      }, SetOptions(merge: true)); // Merge to avoid overwriting
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception('Failed to sign up: ${e.message}');
    } catch (e) {
      throw Exception('An unknown error occurred');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Update profile picture
  Future<void> updateProfilePic(File imageFile) async {
    try {
      String userId = _auth.currentUser!.uid;
      Reference storageRef = _storage.ref().child('profile_pics').child('$userId.jpg');

      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection('Users').doc(userId).update({
        'profilePic': downloadUrl,
      });
    } catch (e) {
      throw Exception('Failed to upload profile picture: ${e.toString()}');
    }
  }

  // Pick image from gallery
  Future<File?> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      return File(pickedFile.path);
    } else {
      return null;
    }
  }

  // Function to handle image picking and uploading
  Future<void> pickAndUploadProfilePicture() async {
    File? imageFile = await pickImage();
    if (imageFile != null) {
      await updateProfilePic(imageFile);
    }
  }
}
