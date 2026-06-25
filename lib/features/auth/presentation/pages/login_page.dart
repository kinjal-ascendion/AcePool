import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/login_button.dart';
import '../widgets/login_header.dart';
import '../widgets/signup_text.dart';
import '../widgets/auth_text_field.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

  Future<void> login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _emailError = email.isEmpty ? 'Username is required' : null;
      _passwordError = password.isEmpty
          ? 'Password is required'
          : password.length < 6
              ? 'Password must be at least 6 characters'
              : null;
    });

    if (_emailError != null || _passwordError != null) return;

    try {
      setState(() => _isLoading = true);

      final email = '${_emailController.text.trim()}@ascendion.com';
      final password = _passwordController.text.trim();

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (mounted) context.go('/home');
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'invalid-credential':
          errorMessage = 'Invalid username or password';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email';
          break;
        default:
          errorMessage = 'Login failed. Please try again.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
              const LoginHeader(),
              const SizedBox(height: 40),
              AuthTextField(
               label: 'Work Email',
               controller: _emailController,
               hintText: 'username',
               errorText: _emailError,
               onChanged: (_) => setState(() => _emailError = null),
               suffixWidget: const Padding(
                 padding: EdgeInsets.only(right: 16),
                 child: Text(
                  '@ascendion.com',
                   style: TextStyle(
                     color: Colors.black54,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AuthTextField(
               label: 'Password',
               controller: _passwordController,
               hintText: 'Minimum 6 characters',
               obscureText: true,
               errorText: _passwordError,
               onChanged: (_) => setState(() => _passwordError = null),
              ),
              const SizedBox(height: 24),
              LoginButton(onPressed: login, isLoading: _isLoading),
              const SizedBox(height: 12),
              const SignupText(),
            ],
          ),
        ),
      ),
    );
  }
}
