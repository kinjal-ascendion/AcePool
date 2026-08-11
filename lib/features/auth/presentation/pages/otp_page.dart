import 'dart:async';

import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/di/injection.dart';
import 'package:acepool/features/auth/presentation/widgets/auth_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/otp_bloc.dart';

class OtpPage extends StatelessWidget {
  final String email;
  final String uid;

  const OtpPage({super.key, required this.email, required this.uid});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OtpBloc>()..add(OtpStarted(email: email, uid: uid)),
      child: _OtpView(email: email),
    );
  }
}

class _OtpView extends StatefulWidget {
  const _OtpView({required this.email});

  final String email;

  @override
  State<_OtpView> createState() => _OtpViewState();
}

class _OtpViewState extends State<_OtpView> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _resendTimer = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
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

  void _verifyOtp() {
    final enteredOtp = _controllers.map((c) => c.text).join();
    context.read<OtpBloc>().add(OtpSubmitted(enteredOtp));
  }

  void _resendOtp() {
    if (_resendTimer > 0) return;
    context.read<OtpBloc>().add(const OtpResendRequested());
  }

  void _goBackToSignup() {
    context.read<OtpBloc>().add(const OtpCancelled());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OtpBloc, OtpState>(
      listener: (context, state) {
        if (state.status == OtpStatus.verified) {
          context.go('/home');
        } else if (state.status == OtpStatus.resent) {
          for (final c in _controllers) {
            c.clear();
          }
          _focusNodes.first.requestFocus();
          _startTimer();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP resent successfully')),
          );
        } else if (state.status == OtpStatus.cancelled) {
          context.go('/signup');
        }
      },
      builder: (context, state) {
        final isVerifying = state.status == OtpStatus.verifying;
        final isResending = state.status == OtpStatus.resending;

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
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.black45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, _buildOtpBox),
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(color: AppColors.red, fontSize: 13),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  AuthButton(
                    onPressed: _verifyOtp,
                    isLoading: isVerifying,
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
                            onTap: isResending ? null : _resendOtp,
                            child: Text(
                              isResending ? 'Resending...' : 'Resend OTP',
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
      },
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
          context.read<OtpBloc>().add(const OtpErrorCleared());
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
