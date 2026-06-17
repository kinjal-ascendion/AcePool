import 'package:flutter/material.dart';
import '../widgets/email_field.dart';
import '../widgets/login_button.dart';
import '../widgets/login_header.dart';
import '../widgets/password_field.dart';
import '../widgets/signup_text.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 80),

              LoginHeader(),

              const SizedBox(height: 40),

              EmailField(),

              const SizedBox(height: 16),

              PasswordField(),

              const SizedBox(height: 24),

              LoginButton(),

              const SizedBox(height: 12),

              SignupText(),
            ],
          )
        ),
      ),
    );
  }
}