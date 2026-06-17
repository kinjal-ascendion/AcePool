import 'package:flutter/material.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/images/Ascendion_Primary_Logo_Black_RGB-1024x388.png',
          height: 90,
        ),
        SizedBox(height: 32),
        Text(
          "Welcome to Acepool",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        Text(
          "Sign in with your Ascendion account",
        ),
      ],
    );
  }
}