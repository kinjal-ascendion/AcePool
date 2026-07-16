import 'dart:io';

import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/core/utils/license_scanner.dart';
import 'package:acepool/features/auth/presentation/widgets/license_upload_box.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AccountSettingsPage extends StatefulWidget {
  final String fullName;
  final String employeeId;
  final bool? licenceVerified;
  final String? licenceNumber;

  const AccountSettingsPage({
    super.key,
    required this.fullName,
    required this.employeeId,
    required this.licenceVerified,
    this.licenceNumber,
  });

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _employeeIdController;
  late final TextEditingController _emailController;

  final _imagePicker = ImagePicker();

  File? _frontLicenseImage;
  File? _backLicenseImage;
  bool _isVerifyingFrontLicense = false;
  bool _isVerifyingBackLicense = false;
  bool? _frontLicenseValid;
  bool? _backLicenseValid;
  String? _licenseNumber;

  bool _isSaving = false;

  static final _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'acepool',
  );

  bool get _isLicenseVerified =>
      widget.licenceVerified == true ||
      _frontLicenseValid == true ||
      _backLicenseValid == true;

  @override
  void initState() {
    super.initState();

    _fullNameController = TextEditingController(text: widget.fullName);
    _employeeIdController = TextEditingController(text: widget.employeeId);
    _licenseNumber = widget.licenceNumber;

    _emailController = TextEditingController(
      text: FirebaseAuth.instance.currentUser?.email ?? '',
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _employeeIdController.dispose();
    _emailController.dispose();
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
    setState(() {
      final status = result.ocrFailed
          ? false
          : (result.licenseNumber != null ? true : null);
      if (isFront) {
        _isVerifyingFrontLicense = false;
        _frontLicenseValid = status;
      } else {
        _isVerifyingBackLicense = false;
        _backLicenseValid = status;
      }
      if (result.licenseNumber != null) _licenseNumber = result.licenseNumber;
    });
  }

  Future<void> _saveProfile() async {
    try {
      setState(() => _isSaving = true);

      final user = FirebaseAuth.instance.currentUser!;
      final newFullName = _fullNameController.text.trim();

      final data = <String, dynamic>{
        'fullName': newFullName,
        'email': _emailController.text.trim(),
      };

      if (_frontLicenseValid == true || _backLicenseValid == true) {
        data['licenceVerified'] = true;
        if (_licenseNumber != null) data['licenceNumber'] = _licenseNumber;
      }

      await _db.collection('users').doc(user.uid).update(data);

      // Home reads FirebaseAuth's displayName, not Firestore's fullName -
      // keep them in sync so the change shows up there too.
      if (newFullName != user.displayName) {
        await user.updateDisplayName(newFullName);
        await user.reload();
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
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

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Account settings',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
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
                        style: TextStyle(fontSize: 13, color: AppColors.black45),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SettingsField(
                      label: 'Full Name',
                      controller: _fullNameController,
                      enabled: true,
                    ),
                    const SizedBox(height: 16),
                    _SettingsField(
                      label: 'Asc ID',
                      controller: _employeeIdController,
                      enabled: false,
                    ),
                    const SizedBox(height: 16),
                    _SettingsField(
                      label: 'Email',
                      controller: _emailController,
                      enabled: false,
                    ),
                    const SizedBox(height: 20),
                    Divider(color: AppColors.grey200, height: 1),
                    const SizedBox(height: 20),
                    _buildLicenseSection(),
                    const SizedBox(height: 24),
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
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
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
                          color: AppColors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: _isSaving
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
          text: const TextSpan(
            text: "DRIVER'S LICENSE",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: AppColors.black87,
            ),
            children: [
              TextSpan(text: ' *', style: TextStyle(color: AppColors.red)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: const TextSpan(
            text: 'Upload license image (Front & Back)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.black87,
            ),
            children: [
              TextSpan(text: ' *', style: TextStyle(color: AppColors.red)),
            ],
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
      ],
    );
  }
}

class _SettingsField extends StatefulWidget {
  const _SettingsField({
    required this.label,
    required this.controller,
    required this.enabled,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.black87,
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
                  style: TextStyle(
                    color: widget.enabled
                        ? AppColors.black87
                        : AppColors.black45,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (widget.enabled)
                const Icon(Icons.edit, size: 16, color: AppColors.black45),
            ],
          ),
        ),
      ],
    );
  }
}
