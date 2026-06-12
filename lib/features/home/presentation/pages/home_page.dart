import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: Text(
          'AcePool',
          style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Text(
          'Home Screen',
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 18),
        ),
      ),
    );
  }
}
