import 'dart:io';

import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/core/utils/license_scanner.dart';
import 'package:acepool/di/injection.dart';
import 'package:acepool/features/onboarding/domain/onboarding_selection.dart';
import 'package:acepool/features/onboarding/domain/entities/travel_preference.dart';
import 'package:acepool/features/onboarding/domain/entities/vehicle_preference.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../bloc/signup_bloc.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/license_upload_box.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key, this.onboardingSelection});

  final OnboardingSelection? onboardingSelection;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SignupBloc>(),
      child: _SignupView(onboardingSelection: onboardingSelection),
    );
  }
}

class _SignupView extends StatefulWidget {
  const _SignupView({this.onboardingSelection});

  final OnboardingSelection? onboardingSelection;

  @override
  State<_SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<_SignupView> {
  final _fullNameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailUsernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _imagePicker = ImagePicker();

  bool get _showLicenseSection {
    final selection = widget.onboardingSelection;
    if (selection == null) return false;
    if (selection.travelPreference == TravelPreference.ride) return false;
    if (selection.vehicleType == VehiclePreference.bike) return false;
    return true;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _employeeIdController.dispose();
    _phoneController.dispose();
    _emailUsernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickLicenseImage(bool isFront) async {
    final source = await LicenseScanner.chooseImageSource(context);
    if (source == null) return;

    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked == null) return;
    if (!mounted) return;

    context.read<SignupBloc>().add(
      SignupLicenseImagePicked(isFront: isFront, imageFile: File(picked.path)),
    );
  }

  void _signup() {
    context.read<SignupBloc>().add(
      SignupSubmitted(
        fullName: _fullNameController.text,
        employeeId: _employeeIdController.text,
        phone: _phoneController.text,
        emailUsername: _emailUsernameController.text,
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        showLicenseSection: _showLicenseSection,
        onboardingSelection: widget.onboardingSelection,
      ),
    );
  }

  void _onFieldChanged(String _) =>
      context.read<SignupBloc>().add(const SignupFieldChanged());

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SignupBloc, SignupState>(
      listener: (context, state) {
        if (state.status == SignupStatus.success) {
          final user = state.user!;
          context.go('/otp', extra: {'email': user.email, 'uid': user.uid});
        } else if (state.status == SignupStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state.status == SignupStatus.submitting;

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
                    errorText: state.fullNameError,
                  ),
                  const SizedBox(height: 16),

                  AuthTextField(
                    label: 'Employee ID',
                    controller: _employeeIdController,
                    hintText: 'e.g. ASC12345',
                    onChanged: _onFieldChanged,
                    errorText: state.employeeIdError,
                  ),
                  const SizedBox(height: 16),

                  AuthTextField(
                    label: 'Phone Number',
                    controller: _phoneController,
                    hintText: '10-digit mobile number',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    onChanged: _onFieldChanged,
                    errorText: state.phoneError,
                  ),
                  const SizedBox(height: 16),

                  AuthTextField(
                    label: 'Work Email',
                    controller: _emailUsernameController,
                    hintText: 'Username',
                    keyboardType: TextInputType.emailAddress,
                    onChanged: _onFieldChanged,
                    errorText: state.emailError,
                    suffixWidget: const Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: Text(
                        '@ascendion.com',
                        style: TextStyle(color: AppColors.black54),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_showLicenseSection) ...[
                    const Text(
                      "DRIVER'S LICENSE",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: AppColors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Upload license image (Front & Back)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'A valid license is required before scheduling a ride. '
                      'Upload both sides to continue.',
                      style: TextStyle(fontSize: 12, color: AppColors.black45),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: LicenseUploadBox(
                            label: 'Front',
                            imageFile: state.frontLicenseImage,
                            isVerifying: state.isVerifyingFrontLicense,
                            isValid: state.frontLicenseValid,
                            onTap: () => _pickLicenseImage(true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: LicenseUploadBox(
                            label: 'Back',
                            imageFile: state.backLicenseImage,
                            isVerifying: state.isVerifyingBackLicense,
                            isValid: state.backLicenseValid,
                            onTap: () => _pickLicenseImage(false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(Icons.info_outline, size: 14, color: Colors.orange),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Required before you can schedule a ride',
                            style: TextStyle(fontSize: 12, color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  AuthTextField(
                    label: 'Password',
                    controller: _passwordController,
                    hintText: 'Minimum 6 characters',
                    obscureText: true,
                    onChanged: _onFieldChanged,
                    errorText: state.passwordError,
                  ),
                  const SizedBox(height: 16),

                  AuthTextField(
                    label: 'Confirm Password',
                    controller: _confirmPasswordController,
                    hintText: 'Re-enter your password',
                    obscureText: true,
                    onChanged: _onFieldChanged,
                    errorText: state.confirmPasswordError,
                  ),
                  const SizedBox(height: 32),

                  // ── Create Account button ────────────────────────────────
                  AuthButton(
                    onPressed: _signup,
                    isLoading: isLoading,
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
      },
    );
  }
}
