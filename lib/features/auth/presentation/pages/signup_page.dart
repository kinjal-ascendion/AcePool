import 'package:acepool/core/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _fullNameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _emailUsernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  String? _fullNameError;
  String? _employeeIdError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  bool _validate() {
    final password = _passwordController.text;

    setState(() {
      _fullNameError = _fullNameController.text.trim().isEmpty
          ? 'Full name is required'
          : null;
      _employeeIdError = _employeeIdController.text.trim().isEmpty
          ? 'Employee ID is required'
          : null;
      _emailError = _emailUsernameController.text.trim().isEmpty
          ? 'Work email username is required'
          : null;
      _passwordError = password.isEmpty
          ? 'Password is required'
          : password.length < 6
          ? 'Password must be at least 6 characters'
          : null;
      _confirmPasswordError = _confirmPasswordController.text.isEmpty
          ? 'Please confirm your password'
          : _confirmPasswordController.text != password
          ? 'Passwords do not match'
          : null;
    });

    return _fullNameError == null &&
        _employeeIdError == null &&
        _emailError == null &&
        _passwordError == null &&
        _confirmPasswordError == null;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _employeeIdController.dispose();
    _emailUsernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);

    try {
      final fullName = _fullNameController.text.trim();
      final email = '${_emailUsernameController.text.trim()}@ascendion.com';
      final password = _passwordController.text;

      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = credential.user!.uid;

      // Update display name so home screen shows the correct name immediately
      await credential.user!.updateDisplayName(fullName);

      await FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'acepool',
      ).collection('users').doc(uid).set({
        'fullName': fullName,
        'employeeId': _employeeIdController.text.trim(),
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        context.go('/otp', extra: {'email': email, 'uid': uid});
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'An account with this email already exists.';
          break;
        case 'weak-password':
          message = 'Password is too weak. Use at least 6 characters.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        default:
          message = 'Sign up failed. Please try again.';
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign up failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onFieldChanged(String _) => setState(() {
    _fullNameError = null;
    _employeeIdError = null;
    _emailError = null;
    _passwordError = null;
    _confirmPasswordError = null;
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Back button ──────────────────────────────────────────
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.chevron_left,
                    color: AppColors.black87,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Logo + Heading (centered) ────────────────────────────
              Center(
                child: Image.asset(
                  'assets/images/Ascendion_Primary_Logo_Black_RGB-1024x388.png',
                  height: 75,
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Create Your Account',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'Only Ascendion employees can sign up',
                  style: TextStyle(fontSize: 14, color: AppColors.black45),
                ),
              ),
              const SizedBox(height: 28),

              // ── Form fields ─────────────────────────────────────────
              AuthTextField(
                label: 'Full Name',
                controller: _fullNameController,
                hintText: 'e.g. Rahul Sharma',
                keyboardType: TextInputType.name,
                onChanged: _onFieldChanged,
                errorText: _fullNameError,
              ),
              const SizedBox(height: 16),

              AuthTextField(
                label: 'Employee ID',
                controller: _employeeIdController,
                hintText: 'e.g. ASC12345',
                onChanged: _onFieldChanged,
                errorText: _employeeIdError,
              ),
              const SizedBox(height: 16),

              AuthTextField(
                label: 'Work Email',
                controller: _emailUsernameController,
                hintText: 'Username',
                keyboardType: TextInputType.emailAddress,
                onChanged: _onFieldChanged,
                errorText: _emailError,
                suffixWidget: const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Text(
                    '@ascendion.com',
                    style: TextStyle(color: AppColors.black54),
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
              const SizedBox(height: 16),

              AuthTextField(
                label: 'Confirm Password',
                controller: _confirmPasswordController,
                hintText: 'Re-enter your password',
                obscureText: true,
                onChanged: _onFieldChanged,
                errorText: _confirmPasswordError,
              ),
              const SizedBox(height: 32),

              // ── Create Account button ────────────────────────────────
              AuthButton(
                onPressed: _signup,
                isLoading: _isLoading,
                label: 'Create Account',
              ),
              const SizedBox(height: 20),

              // ── "Already have an account?" link ─────────────────────
              Center(
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: RichText(
                    text: const TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(color: AppColors.black54, fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Log in',
                          style: TextStyle(
                            color: AppColors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
