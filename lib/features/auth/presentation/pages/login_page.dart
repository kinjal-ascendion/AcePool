import 'package:acepool/core/constants/api_keys.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/auth_button.dart';
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
  bool _isLoading = false;
  String? _emailError;

  Future<void> _loginWithMicrosoft() async {
    final username = _emailController.text.trim();
    setState(() {
      _emailError = username.isEmpty ? 'Username is required' : null;
    });
    if (_emailError != null) return;

    setState(() => _isLoading = true);
    try {
      final provider = OAuthProvider('microsoft.com')
        ..setCustomParameters({
          'tenant': ApiKeys.microsoftTenantId,
          'login_hint': '$username@ascendion.com',
        });

      final credential =
          await FirebaseAuth.instance.signInWithProvider(provider);

      if (!mounted) return;

      if (credential.additionalUserInfo?.isNewUser == true) {
        context.push('/complete-profile', extra: credential);
      } else {
        context.go('/home');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Sign-in failed. Please try again.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in failed: $e')),
        );
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
                hintText: 'Username',
                errorText: _emailError,
                onChanged: (_) => setState(() => _emailError = null),
                suffixWidget: const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Text(
                    '@ascendion.com',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AuthButton(
                onPressed: _loginWithMicrosoft,
                isLoading: _isLoading,
                label: 'Log In',
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () => context.push('/login/password'),
                  child: const Text(
                    'Log In with password',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const SignupText(),
            ],
          ),
        ),
      ),
    );
  }
}
