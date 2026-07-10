import 'package:acepool/core/theme/app_colors.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:acepool/core/constants/api_keys.dart';
import 'package:acepool/features/auth/presentation/widgets/auth_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

class OtpPage extends StatefulWidget {
  final String email;
  final String uid;

  const OtpPage({super.key, required this.email, required this.uid});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isResending = false;
  int _resendTimer = 60;
  Timer? _timer;
  String? _errorMessage;

  FirebaseFirestore get _db => FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'acepool',
      );

  @override
  void initState() {
    super.initState();
    _sendOtp();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _resendTimer = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_resendTimer == 0) {
        t.cancel();
      } else {
        setState(() => _resendTimer--);
      }
    });
  }

  String _generateOtp() {
    final rng = Random.secure();
    return List.generate(6, (_) => rng.nextInt(10)).join();
  }

  Future<void> _sendOtp() async {
    final otp = _generateOtp();
    final expiry = DateTime.now().add(const Duration(minutes: 10));

    try {
      await _db.collection('otps').doc(widget.uid).set({
        'otp': otp,
        'expiresAt': Timestamp.fromDate(expiry),
        'email': widget.email,
      });

      await _sendOtpEmail(widget.email, otp);
    } catch (e) {
      debugPrint('OTP send error: $e');
    }
  }

  Future<void> _sendOtpEmail(String email, String otp) async {
    debugPrint('Sending OTP $otp to $email');

    final response = await http.post(
      Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'service_id': ApiKeys.emailJsServiceId,
        'template_id': ApiKeys.emailJsTemplateId,
        'user_id': ApiKeys.emailJsPublicKey,
        'accessToken': ApiKeys.emailJsPrivateKey,
        'template_params': {
          'to_email': email,
          'otp': otp,
          'passcode': otp,
          'otp_code': otp,
          'company_name': 'AcePool',
          'valid_minutes': '15',
        },
      }),
    );

    if (response.statusCode != 200) {
      debugPrint('EmailJS error ${response.statusCode}: ${response.body}');
      throw Exception('Failed to send OTP email');
    }
  }

  Future<void> _verifyOtp() async {
    final enteredOtp = _controllers.map((c) => c.text).join();
    if (enteredOtp.length != 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit OTP');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final doc = await _db.collection('otps').doc(widget.uid).get();

      if (!doc.exists) {
        setState(() => _errorMessage = 'OTP not found. Please resend.');
        return;
      }

      final data = doc.data()!;
      final storedOtp = data['otp'] as String;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();

      if (DateTime.now().isAfter(expiresAt)) {
        setState(() => _errorMessage = 'OTP has expired. Please resend.');
        return;
      }

      if (enteredOtp != storedOtp) {
        setState(() => _errorMessage = 'Incorrect OTP. Please try again.');
        return;
      }

      await doc.reference.delete();

      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _errorMessage = 'Verification failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_resendTimer > 0 || _isResending) return;
    setState(() => _isResending = true);
    await _sendOtp();
    if (mounted) {
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes.first.requestFocus();
      _startTimer();
      setState(() {
        _isResending = false;
        _errorMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP resent successfully')),
      );
    }
  }

  Future<void> _goBackToSignup() async {
    try {
      await _db.collection('otps').doc(widget.uid).delete();
      await _db.collection('users').doc(widget.uid).delete();
      await FirebaseAuth.instance.currentUser?.delete();
    } catch (_) {}
    if (mounted) context.go('/signup');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _goBackToSignup,
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
              const SizedBox(height: 40),
              Center(
                child: Image.asset(
                  'assets/images/Ascendion_Primary_Logo_Black_RGB-1024x388.png',
                  height: 75,
                ),
              ),
              const SizedBox(height: 32),
              const Center(
                child: Text(
                  'Verify Your Email',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Enter the 6-digit OTP sent to\n${widget.email}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppColors.black45),
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, _buildOtpBox),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.red, fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              AuthButton(
                onPressed: _verifyOtp,
                isLoading: _isVerifying,
                label: 'Verify OTP',
              ),
              const SizedBox(height: 24),
              Center(
                child: _resendTimer > 0
                    ? Text(
                        'Resend OTP in ${_resendTimer}s',
                        style: const TextStyle(
                          color: AppColors.black45,
                          fontSize: 14,
                        ),
                      )
                    : GestureDetector(
                        onTap: _isResending ? null : _resendOtp,
                        child: Text(
                          _isResending ? 'Resending...' : 'Resend OTP',
                          style: const TextStyle(
                            color: AppColors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.black87,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppColors.white,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.grey300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.grey300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.black, width: 2),
          ),
        ),
        onChanged: (value) {
          setState(() => _errorMessage = null);
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }
}
