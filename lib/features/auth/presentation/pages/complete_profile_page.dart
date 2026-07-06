import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key, required this.credential});

  final UserCredential credential;

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  late final TextEditingController _fullNameController;
  final _employeeIdController = TextEditingController();

  bool _isLoading = false;
  String? _fullNameError;
  String? _employeeIdError;

  @override
  void initState() {
    super.initState();
    final profile = widget.credential.additionalUserInfo?.profile;
    final displayName = (profile?['displayName'] as String?) ??
        (profile?['givenName'] as String?) ??
        widget.credential.user?.displayName ??
        '';
    _fullNameController = TextEditingController(text: displayName);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _employeeIdController.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _fullNameError =
          _fullNameController.text.trim().isEmpty ? 'Full name is required' : null;
      _employeeIdError = _employeeIdController.text.trim().isEmpty
          ? 'Employee ID is required'
          : null;
    });
    return _fullNameError == null && _employeeIdError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = widget.credential.user!;
      final fullName = _fullNameController.text.trim();

      await user.updateDisplayName(fullName);

      await FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'acepool',
      ).collection('users').doc(user.uid).set({
        'fullName': fullName,
        'employeeId': _employeeIdController.text.trim(),
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) context.go('/onboarding/travel-preference');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Image.asset(
                  'assets/images/Ascendion_Primary_Logo_Black_RGB-1024x388.png',
                  height: 75,
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Complete Your Profile',
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
                  'Just a couple more details to get you started',
                  style: TextStyle(fontSize: 14, color: Colors.black45),
                ),
              ),
              const SizedBox(height: 28),
              AuthTextField(
                label: 'Full Name',
                controller: _fullNameController,
                hintText: 'e.g. Rahul Sharma',
                keyboardType: TextInputType.name,
                onChanged: (_) => setState(() => _fullNameError = null),
                errorText: _fullNameError,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                label: 'Employee ID',
                controller: _employeeIdController,
                hintText: 'e.g. ASC12345',
                onChanged: (_) => setState(() => _employeeIdError = null),
                errorText: _employeeIdError,
              ),
              const SizedBox(height: 32),
              AuthButton(
                onPressed: _submit,
                isLoading: _isLoading,
                label: 'Continue',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
