import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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
  bool _submitted = false;

  // Validation errors
  String? get _fullNameError {
    if (!_submitted) return null;
    final v = _fullNameController.text.trim();
    if (v.isEmpty) return 'Full name is required';
    if (v.length < 2) return 'Enter a valid full name';
    return null;
  }

  String? get _employeeIdError {
    if (!_submitted) return null;
    if (_employeeIdController.text.trim().isEmpty) return 'Employee ID is required';
    return null;
  }

  String? get _emailError {
    if (!_submitted) return null;
    final v = _emailUsernameController.text.trim();
    if (v.isEmpty) return 'Work email username is required';
    if (v.contains(' ')) return 'Username must not contain spaces';
    if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(v)) {
      return 'Username can only contain letters, numbers, dots and underscores';
    }
    return null;
  }

  String? get _passwordError {
    if (!_submitted) return null;
    if (_passwordController.text.isEmpty) return 'Password is required';
    if (_passwordController.text.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? get _confirmPasswordError {
    if (!_submitted) return null;
    if (_confirmPasswordController.text.isEmpty) return 'Please confirm your password';
    if (_confirmPasswordController.text != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? get _mobileError {
    if (!_submitted) return null;
    final mobile = _mobileController.text.trim();
    if (mobile.isEmpty) return 'Mobile number is required';
    if (!RegExp(r'^\d{10}$').hasMatch(mobile)) return 'Enter a valid 10-digit mobile number';
    return null;
  }

  bool get _isFormValid =>
      _fullNameError == null &&
      _employeeIdError == null &&
      _emailError == null &&
      _passwordError == null &&
      _confirmPasswordError == null &&
      _mobileError == null &&
      _fullNameController.text.isNotEmpty &&
      _employeeIdController.text.isNotEmpty &&
      _emailUsernameController.text.isNotEmpty &&
      _passwordController.text.isNotEmpty &&
      _confirmPasswordController.text.isNotEmpty &&
      _mobileController.text.isNotEmpty;

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
    setState(() => _submitted = true);
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

      await credential.user!.updateDisplayName(fullName);

      await FirebaseFirestore.instanceFor(
              app: Firebase.app(), databaseId: 'acepool')
          .collection('users')
          .doc(uid)
          .set({
        'fullName': fullName,
        'employeeId': _employeeIdController.text.trim(),
        'email': email,
        'mobile': _mobileController.text.trim(),
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
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

  void _onFieldChanged(String _) {
    if (_submitted) setState(() {});
  }

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
              const SizedBox(height: 16),
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
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'Only Ascendion employees can sign up',
                  style: TextStyle(fontSize: 14, color: Colors.black45),
                ),
              ),
              const SizedBox(height: 28),
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
                hintText: 'username',
                keyboardType: TextInputType.emailAddress,
                onChanged: _onFieldChanged,
                errorText: _emailError,
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
                errorText: _mobileError,
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signup,
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
