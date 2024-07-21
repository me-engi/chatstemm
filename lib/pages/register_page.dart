import 'package:chatapp/auth/auth_service.dart';
import 'package:chatapp/widget/custom_button.dart';
import 'package:chatapp/widget/textfield.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class RegisterPage extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();


  final void Function()? onTap;
  
RegisterPage({super.key, required this.onTap});
  void register(BuildContext context) async {
    final authService = AuthService();

    if (_passwordController.text == _confirmPasswordController.text) {
      try {
        await authService.signUpWithEmailPassword(
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
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Passwords do not match'),
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
            "Lets create an account for you!",
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
          CustomTextfield(
            hintText: " confirm password",
            obscureText: true,
            controller: _confirmPasswordController,
          ),

          Gap(10),
          CustomButtom(
            text: "Sign Up",
            onTap: () => register(context),
          ),
          Gap(10),

          Row(children: [
            Text("Already have an account??",
            style: TextStyle(color:Theme.of(context).colorScheme.primary),),

            GestureDetector(
              onTap: onTap,
              child: Text("Login",
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