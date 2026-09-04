import 'dart:io';

import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/core/utils/license_scanner.dart';
import 'package:acepool/di/injection.dart';
import 'package:acepool/features/auth/presentation/widgets/license_upload_box.dart';
import 'package:acepool/features/profile/presentation/bloc/account_settings_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class AccountSettingsPage extends StatefulWidget {
  final String fullName;
  final String employeeId;
  final String? phone;
  final bool? licenceVerified;
  final String? licenceNumber;
  final bool fromOfferRide;

  const AccountSettingsPage({
    super.key,
    required this.fullName,
    required this.employeeId,
    this.phone,
    required this.licenceVerified,
    this.licenceNumber,
    this.fromOfferRide = false,
  });

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _employeeIdController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  final _imagePicker = ImagePicker();

  File? _frontLicenseImage;
  File? _backLicenseImage;
  bool _isVerifyingFrontLicense = false;
  bool _isVerifyingBackLicense = false;
  bool? _frontLicenseValid;
  bool? _backLicenseValid;
  String? _frontLicenseNumber;
  String? _backLicenseNumber;
  String? _licenseNumber;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final GlobalKey _licenseSectionKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  late final AccountSettingsBloc _bloc;

  bool get _isNewlyVerified =>
      _frontLicenseNumber != null &&
      _backLicenseNumber != null &&
      _frontLicenseNumber == _backLicenseNumber &&
      _frontLicenseValid == true &&
      _backLicenseValid == true;

  bool get _isLicenseVerified =>
      widget.licenceVerified == true || _isNewlyVerified;

  @override
  void initState() {
    super.initState();

    _bloc = sl<AccountSettingsBloc>();

    _fullNameController = TextEditingController(text: widget.fullName);
    _employeeIdController = TextEditingController(text: widget.employeeId);
    _phoneController = TextEditingController(text: widget.phone ?? '');
    _licenseNumber = widget.licenceNumber;

    _emailController = TextEditingController(
      text: FirebaseAuth.instance.currentUser?.email ?? '',
    );
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    if (widget.fromOfferRide) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_licenseSectionKey.currentContext != null) {
          Scrollable.ensureVisible(
            _licenseSectionKey.currentContext!,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _employeeIdController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _scrollController.dispose();
    _bloc.close();
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

    setState(() {
      if (isFront) {
        _frontLicenseImage = File(picked.path);
        _isVerifyingFrontLicense = true;
        _frontLicenseValid = null;
      } else {
        _backLicenseImage = File(picked.path);
        _isVerifyingBackLicense = true;
        _backLicenseValid = null;
      }
    });

    final result = await LicenseScanner.extractLicenseNumber(picked.path);

    if (!mounted) return;
    String? errorMessage;
    setState(() {
      final number = result.licenseNumber;
      final status = result.ocrFailed
          ? false
          : (number != null ? true : false);

      if (isFront) {
        _isVerifyingFrontLicense = false;
        _frontLicenseNumber = number;
        _frontLicenseValid = status;
        if (number == null) {
          errorMessage = 'Could not detect a valid license number on front image';
        } else if (_backLicenseNumber != null) {
          if (_frontLicenseNumber == _backLicenseNumber) {
            _backLicenseValid = true;
            _licenseNumber = number;
          } else {
            _frontLicenseValid = false;
            errorMessage = 'License numbers on front and back do not match';
          }
        }
      } else {
        _isVerifyingBackLicense = false;
        _backLicenseNumber = number;
        _backLicenseValid = status;
        if (number == null) {
          errorMessage = 'Could not detect a valid license number on back image';
        } else if (_frontLicenseNumber != null) {
          if (_frontLicenseNumber == _backLicenseNumber) {
            _frontLicenseValid = true;
            _licenseNumber = number;
          } else {
            _backLicenseValid = false;
            errorMessage = 'License numbers on front and back do not match';
          }
        }
      }
    });

    if (errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage!)),
      );
    }

    if (_isNewlyVerified && widget.fromOfferRide) {
      _saveProfile();
    }
  }

  void _saveProfile() {
    _bloc.add(AccountSettingsSaveRequested(
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      licenceVerified: _isLicenseVerified ? true : null,
      licenceNumber: _licenseNumber,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final initials = widget.fullName.trim().isNotEmpty
        ? widget.fullName
              .trim()
              .split(' ')
              .where((w) => w.isNotEmpty)
              .take(2)
              .map((w) => w[0].toUpperCase())
              .join()
        : '?';

    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<AccountSettingsBloc, AccountSettingsState>(
        listener: (context, state) {
          if (state.status == AccountSettingsStatus.success) {
            Navigator.pop(context, true);
          } else if (state.status == AccountSettingsStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message ?? 'Failed to save profile')),
            );
          }
        },
        builder: (context, state) => _buildScaffold(context, state, initials),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, AccountSettingsState state, String initials) {
    final isSaving = state.status == AccountSettingsStatus.saving;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.black, size: 26),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Account settings',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.black87,
                            child: Text(
                              initials,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Coming soon')),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.grey400,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 14,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        'Change your profile picture',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.subheadingGrey,
                          fontWeight: FontWeight.w600,
                          height: 1.285, // 18/14
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SettingsField(
                      label: 'Full Name',
                      controller: _fullNameController,
                      enabled: true,
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),
                    _SettingsField(
                      label: 'Employee ID',
                      controller: _employeeIdController,
                      enabled: false,
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),
                    _SettingsField(
                      label: 'Work Email',
                      controller: _emailController,
                      enabled: false,
                      isRequired: true,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Note : Email Id can be edited only once',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.subheadingGrey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SettingsField(
                      label: 'Phone No',
                      controller: _phoneController,
                      enabled: true,
                      isRequired: true,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Divider(color: AppColors.dividerGrey, height: 1),
                    const SizedBox(height: 20),
                    KeyedSubtree(
                      key: _licenseSectionKey,
                      child: _buildLicenseSection(),
                    ),
                    const SizedBox(height: 24),
                    _SettingsField(
                      label: 'Password',
                      controller: _passwordController,
                      enabled: true,
                      obscureText: _obscurePassword,
                      hintText: 'Minimum 6 characters',
                      onSuffixTap: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    const SizedBox(height: 16),
                    _SettingsField(
                      label: 'Confirm Password',
                      controller: _confirmPasswordController,
                      enabled: true,
                      obscureText: _obscureConfirmPassword,
                      hintText: 'Re-enter password',
                      onSuffixTap: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isSaving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppColors.grey300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppColors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLicenseSection() {
    if (_isLicenseVerified) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified, color: AppColors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Driver's License verified",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black87,
                  ),
                ),
                if (_licenseNumber != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _licenseNumber!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.black45,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: "DRIVER'S LICENSE",
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              height: 1.33,
              color: AppColors.black,
            ),
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            text: 'Upload license image (Front & Back)',
            style: GoogleFonts.mulish(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
              height: 1.5, // 24/16
            ),
            children: const [
              TextSpan(text: ' *', style: TextStyle(color: AppColors.red)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'A valid license is required before scheduling a ride. '
          'Upload both sides to continue.',
          style: GoogleFonts.mulish(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.subheadingGrey,
            height: 1.5, // 24/16
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: LicenseUploadBox(
                label: 'Front',
                imageFile: _frontLicenseImage,
                isVerifying: _isVerifyingFrontLicense,
                isValid: _frontLicenseValid,
                onTap: () => _pickLicenseImage(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LicenseUploadBox(
                label: 'Back',
                imageFile: _backLicenseImage,
                isVerifying: _isVerifyingBackLicense,
                isValid: _backLicenseValid,
                onTap: () => _pickLicenseImage(false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.info_outline, size: 14, color: Color(0xFFD97706)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Required before you can schedule a ride',
                style: GoogleFonts.mulish(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFFD97706),
                  height: 1.285, // 18/14
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingsField extends StatefulWidget {
  const _SettingsField({
    required this.label,
    required this.controller,
    required this.enabled,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.hintText,
    this.onSuffixTap,
    this.isRequired = false,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final String? hintText;
  final VoidCallback? onSuffixTap;
  final bool isRequired;

  @override
  State<_SettingsField> createState() => _SettingsFieldState();
}

class _SettingsFieldState extends State<_SettingsField> {
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TextStyle fieldStyle;
    if (widget.label.toUpperCase() == 'EMPLOYEE ID') {
      fieldStyle = GoogleFonts.mulish(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.subheadingGrey,
        height: 1.5, // 21/14
      );
    } else if (widget.label.toUpperCase() == 'WORK EMAIL' || !widget.enabled) {
      fieldStyle = GoogleFonts.mulish(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF1E1E1E),
        height: 1.0,
      );
    } else {
      fieldStyle = GoogleFonts.mulish(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF1E1E1E),
        height: 1.0,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: widget.label.toUpperCase(),
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
              height: 1.33, // 16/12
              letterSpacing: 0.3,
            ),
            children: [
              if (widget.isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.red),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: widget.enabled ? AppColors.white : AppColors.grey100,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isFocused ? AppColors.black : AppColors.grey300,
              width: _isFocused ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  keyboardType: widget.keyboardType,
                  inputFormatters: widget.inputFormatters,
                  obscureText: widget.obscureText,
                  style: fieldStyle,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    hintText: widget.hintText,
                    hintStyle: GoogleFonts.mulish(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: AppColors.subheadingGrey,
                    ),
                  ),
                ),
              ),
              if (widget.onSuffixTap != null)
                GestureDetector(
                  onTap: widget.onSuffixTap,
                  child: Icon(
                    widget.obscureText ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                    color: AppColors.black45,
                  ),
                )
              else if (widget.enabled)
                const Icon(Icons.edit, size: 16, color: AppColors.black45),
            ],
          ),
        ),
      ],
    );
  }
}
