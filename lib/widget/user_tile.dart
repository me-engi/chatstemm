import 'package:chatapp/auth/auth_service.dart';
import 'package:chatapp/pages/home_page.dart';
import 'package:flutter/material.dart';

class UserTile extends StatelessWidget {
  final String text;
  final String profilePicUrl;
  final void Function()? onTap;
  final void Function()? onProfilePicTap;

  const UserTile({
    super.key,
    required this.text,
    required this.profilePicUrl,
    required this.onTap,
    required this.onProfilePicTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 25),
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (profilePicUrl.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenImage(imageUrl: profilePicUrl),
                    ),
                  );
                }
              },
              child: CircleAvatar(
                backgroundImage: profilePicUrl.isNotEmpty
                    ? NetworkImage(profilePicUrl)
                    : null,
                child: profilePicUrl.isEmpty
                    ? Icon(Icons.person, size: 40)
                    : null,
                radius: 30,
              ),
            ),
            const SizedBox(width: 20),
            Text(text),
          ],
        ),
      ),
    );
  }
}
