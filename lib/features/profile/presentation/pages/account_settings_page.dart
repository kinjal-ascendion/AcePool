import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:validifydart/validify_dart.dart';

class AccountSettingsPage extends StatefulWidget {
  final String fullName;
  final String employeeId;
  final String mobile;
  final String role;
  final bool? licenceVerified;

  const AccountSettingsPage({
    super.key,
    required this.fullName,
    required this.employeeId,
    required this.mobile,
    required this.role,
    required this.licenceVerified,
  });

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _employeeIdController;
  late final TextEditingController _mobileController;
  late final TextEditingController _emailController;
  late final TextEditingController _roleController;

  final ImagePicker _imagePicker = ImagePicker();
  bool? _isLicenceValid;
  bool _isVerifyingLicence = false;

  bool _isSaving = false;

  static final _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'acepool',
  );

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.fullName);
    _employeeIdController = TextEditingController(text: widget.employeeId);
    _mobileController = TextEditingController(text: widget.mobile);
    _roleController = TextEditingController(text: widget.role);
    _isLicenceValid = widget.licenceVerified;

    _emailController = TextEditingController(
      text: FirebaseAuth.instance.currentUser?.email ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _employeeIdController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _pickAndVerifyLicence() async {
    final XFile? pickedImage = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedImage == null) return;

    setState(() {
      _isLicenceValid = null;
      _isVerifyingLicence = true;
    });

    final TextRecognizer textRecognizer = TextRecognizer(
      script: TextRecognitionScript.latin,
    );

    try {
      final InputImage inputImage = InputImage.fromFilePath(pickedImage.path);

      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      final String fullText = recognizedText.text;

      final RegExp licenceRegex = RegExp(r'\b[A-Z]{2}\d{2}\s?\d{11}\b');
      final RegExpMatch? match = licenceRegex.firstMatch(fullText);

      bool isValid = false;

      if (match != null) {
        final String extractedLicenceNumber = match.group(0)!;
        final String cleanedLicenceNumber =
            extractedLicenceNumber.replaceAll(' ', '');

        isValid = ValidifyDart.isValidDrivingLicense(cleanedLicenceNumber);
      }

      if (!mounted) return;

      setState(() {
        _isLicenceValid = isValid;
      });

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await _db
            .collection('users')
            .doc(uid)
            .update({'licenceVerified': isValid});
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLicenceValid = false;
      });
    } finally {
      textRecognizer.close();
      if (mounted) {
        setState(() {
          _isVerifyingLicence = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    try {
      setState(() => _isSaving = true);

      final uid = FirebaseAuth.instance.currentUser!.uid;

      await _db.collection('users').doc(uid).update({
        'fullName': _nameController.text.trim(),
        'employeeId': _employeeIdController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'role': _roleController.text.trim(),
      });

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

  Widget _buildField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return _ProfileField(
      label: label,
      icon: icon,
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    "Account Settings",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade100,
                      foregroundColor: Colors.blue,
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Save"),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _buildField(
                label: "Full Name",
                icon: Icons.person,
                controller: _nameController,
              ),
              const SizedBox(height: 20),
              _buildField(
                label: "Mobile Number",
                icon: Icons.phone,
                controller: _mobileController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              _buildField(
                label: "Email ID",
                icon: Icons.email,
                controller: _emailController,
                enabled: false,
              ),
              const SizedBox(height: 20),
              _buildField(
                label: "Employee ID",
                icon: Icons.badge,
                controller: _employeeIdController,
              ),
              const SizedBox(height: 20),
              _buildField(
                label: "Role",
                icon: Icons.work_outline,
                controller: _roleController,
              ),
              const SizedBox(height: 30),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Driving Licence',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed:
                            _isVerifyingLicence ? null : _pickAndVerifyLicence,
                        icon: const Icon(Icons.upload_file),
                        label: Text(
                          _isVerifyingLicence
                              ? 'Verifying...'
                              : 'Upload Driving Licence',
                        ),
                      ),
                      if (_isVerifyingLicence) ...[
                        const SizedBox(height: 16),
                        const Center(child: CircularProgressIndicator()),
                      ],
                      if (_isLicenceValid != null && !_isVerifyingLicence) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isLicenceValid!
                                  ? Icons.verified
                                  : Icons.cancel,
                              color:
                                  _isLicenceValid! ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isLicenceValid! ? 'Valid Licence' : 'Invalid Licence',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _isLicenceValid!
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileField extends StatefulWidget {
  const _ProfileField({
    required this.label,
    required this.icon,
    required this.controller,
    required this.enabled,
    required this.keyboardType,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final bool enabled;
  final TextInputType keyboardType;

  @override
  State<_ProfileField> createState() => _ProfileFieldState();
}

class _ProfileFieldState extends State<_ProfileField> {
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
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isFocused ? Colors.black : Colors.grey.shade200,
              width: _isFocused ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: Colors.lightBlue),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  keyboardType: widget.keyboardType,
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),
              if (widget.enabled)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, size: 18, color: Colors.blue),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
