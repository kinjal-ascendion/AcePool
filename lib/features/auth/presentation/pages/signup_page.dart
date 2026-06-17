import 'package:acepool/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

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
  final _mobileController = TextEditingController();

  bool _isLoading = false;

  bool get _isFormValid {
    final mobile = _mobileController.text.trim();
    return _fullNameController.text.trim().isNotEmpty &&
        _employeeIdController.text.trim().isNotEmpty &&
        _emailUsernameController.text.trim().isNotEmpty &&
        _passwordController.text.length >= 6 &&
        _passwordController.text == _confirmPasswordController.text &&
        RegExp(r'^\d{10}$').hasMatch(mobile);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _employeeIdController.dispose();
    _emailUsernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_isFormValid) return;

    setState(() => _isLoading = true);

    try {
      final fullName = _fullNameController.text.trim();
      final email = '${_emailUsernameController.text.trim()}@ascendion.com';
      final password = _passwordController.text;

      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      await Future.wait([
        credential.user!.updateDisplayName(fullName),
        FirebaseFirestore.instance.collection('users').doc(uid).set({
          'fullName': fullName,
          'employeeId': _employeeIdController.text.trim(),
          'email': email,
          'mobile': _mobileController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        }),
      ]);

      if (mounted) {
        context.go('/home');
        scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Welcome to Acepool.'),
            duration: Duration(seconds: 3),
          ),
        );
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onFieldChanged(String _) => setState(() {});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1B8A3F);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: back button + ASCENDION brand ──────────────
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.chevron_left,
                    color: Colors.black87,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Heading ─────────────────────────────────────────────
              const Text(
                'Create Your Account',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Only Ascendion employees can sign up',
                style: TextStyle(fontSize: 14, color: Colors.black45),
              ),
              const SizedBox(height: 28),

              // ── Form fields ─────────────────────────────────────────
              AuthTextField(
                label: 'Full Name',
                controller: _fullNameController,
                hintText: 'e.g. Rahul Sharma',
                keyboardType: TextInputType.name,
                onChanged: _onFieldChanged,
              ),
              const SizedBox(height: 16),

              AuthTextField(
                label: 'Employee ID',
                controller: _employeeIdController,
                hintText: 'e.g. ASC12345',
                onChanged: _onFieldChanged,
              ),
              const SizedBox(height: 16),

              AuthTextField(
                label: 'Work Email',
                controller: _emailUsernameController,
                hintText: 'username',
                keyboardType: TextInputType.emailAddress,
                onChanged: _onFieldChanged,
                suffixWidget: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '@ascendion.com',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
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
                onChanged: _onFieldChanged,
              ),
              const SizedBox(height: 16),

              AuthTextField(
                label: 'Confirm Password',
                controller: _confirmPasswordController,
                hintText: 'Re-enter your password',
                obscureText: true,
                onChanged: _onFieldChanged,
              ),
              const SizedBox(height: 16),

              AuthTextField(
                label: 'Mobile Number',
                controller: _mobileController,
                hintText: '10-digit mobile number',
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                onChanged: _onFieldChanged,
                prefixWidget: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 18,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFD6D6D6),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '+91',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Create Account button ────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _isFormValid && !_isLoading ? _signup : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Create Account',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // ── "Already have an account?" link ─────────────────────
              Center(
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: RichText(
                    text: const TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Log in',
                          style: TextStyle(
                            color: primaryGreen,
                            fontWeight: FontWeight.w600,
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
