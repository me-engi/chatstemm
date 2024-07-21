import 'package:chatapp/auth/auth_service.dart';
import 'package:chatapp/widget/custom_button.dart';
import 'package:chatapp/widget/textfield.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
class LoginPage extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final void Function()? onTap;

  LoginPage({super.key, required this.onTap});

 void login(BuildContext context) async {
    final authService = AuthService();

    try {
      await authService.signInWithEmailPassword(
        _emailController.text,
        _passwordController.text,
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      
      
      body:Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          
          //logo
          Icon(
            Icons.message,
            size : 60,
            color:Theme.of(context).colorScheme.primary,
          ),
          Gap(10),

          //welcome back messege
          Text(
            "Welcome back!",
            style: TextStyle(
              color:Theme.of(context).colorScheme.primary,
              fontSize: 16,
            )
          ),
          Gap(10),
          CustomTextfield(
            hintText: "email",
            controller: _emailController,
            obscureText: false,
          ),
           Gap(10),
          CustomTextfield(
            hintText: "password",
            obscureText: true,
            controller: _passwordController,
          ),

          Gap(10),
          CustomButtom(
            text: "Login",
            onTap : () => login(context),
          ),
          Gap(10),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Text("Not a member??",
            style: TextStyle(color:Theme.of(context).colorScheme.primary),),

            GestureDetector(
              onTap: onTap,
              child: Text("Register now",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],)

          



          //email textfield

          //password textfield'

          //register now
          
        ],
      )
    );
  }
}