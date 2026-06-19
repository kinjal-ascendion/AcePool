import 'package:flutter/material.dart';

class HomeAppBarGreeting extends StatelessWidget {
  const HomeAppBarGreeting({
    super.key,
    required this.initials,
    required this.name,
    this.onAvatarTap,
  });

  final String initials;
  final String name;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onAvatarTap,
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey.shade500,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Hi, $name 👋',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
