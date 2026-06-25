import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/auth_text_field.dart';
import '../widgets/login_button.dart';
import '../widgets/login_header.dart';
import '../widgets/signup_text.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _submitted = false;

  String? get _emailError {
    if (!_submitted) return null;
    final v = _emailController.text.trim();
    if (v.isEmpty) return 'Username is required';
    if (v.contains(' ')) return 'Username must not contain spaces';
    return null;
  }

  String? get _passwordError {
    if (!_submitted) return null;
    if (_passwordController.text.isEmpty) return 'Password is required';
    if (_passwordController.text.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  bool get _isFormValid =>
      _emailError == null &&
      _passwordError == null &&
      _emailController.text.isNotEmpty &&
      _passwordController.text.isNotEmpty;

  Future<void> login() async {
    setState(() => _submitted = true);
    if (!_isFormValid) return;

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
        case 'user-not-found':
          errorMessage = 'No account found with this username';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password';
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

  void _onFieldChanged(String _) {
    if (_submitted) setState(() {});
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
                onChanged: _onFieldChanged,
                errorText: _emailError,
                suffixWidget: const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Text(
                    '@ascendion.com',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AuthTextField(
                label: 'Password',
                controller: _passwordController,
                hintText: 'Minimum 6 characters',
                obscureText: true,
                onChanged: _onFieldChanged,
                errorText: _passwordError,
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
