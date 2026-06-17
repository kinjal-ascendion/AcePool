import 'package:flutter/material.dart';

class HomeAppBarGreeting extends StatelessWidget {
  const HomeAppBarGreeting({super.key, required this.initials, required this.name});

  final String initials;
  final String name;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
          child: Text(
            initials,
            style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Hi, $name 👋',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
