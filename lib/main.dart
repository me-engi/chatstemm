import 'package:chatapp/auth/auth_gate.dart';
import 'package:chatapp/auth/login%20or%20register.dart';
import 'package:chatapp/firebase_options.dart';
import 'package:chatapp/pages/login_page.dart';
import 'package:chatapp/themes/light_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main()async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
      theme: LightMode,
    );
  }
}