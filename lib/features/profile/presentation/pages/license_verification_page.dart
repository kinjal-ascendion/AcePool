import 'dart:io';

import 'package:acepool/core/widgets/license_upload_section.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class LicenseVerificationPage extends StatefulWidget {
  const LicenseVerificationPage({super.key});

  @override
  State<LicenseVerificationPage> createState() =>
      _LicenseVerificationPageState();
}

class _LicenseVerificationPageState extends State<LicenseVerificationPage> {
  File? _frontImage;
  File? _backImage;
  String? _error;
  bool _isSaving = false;

  Future<String> _uploadLicenseImage(Reference ref, File file) async {
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<void> _save() async {
    if (_frontImage == null || _backImage == null) {
      setState(
        () => _error = "Please upload both sides of your driver's license",
      );
      return;
    }

    setState(() {
      _error = null;
      _isSaving = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final storageRef = FirebaseStorage.instance.ref('driver_licenses/$uid');
      final licenseFrontUrl = await _uploadLicenseImage(
        storageRef.child('front.jpg'),
        _frontImage!,
      );
      final licenseBackUrl = await _uploadLicenseImage(
        storageRef.child('back.jpg'),
        _backImage!,
      );

      await FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'acepool',
      ).collection('users').doc(uid).update({
        'licenseFrontUrl': licenseFrontUrl,
        'licenseBackUrl': licenseBackUrl,
        'licenseStatus': 'verified',
      });

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save license: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    "Driver's License",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
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
                        : const Text('Save'),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              LicenseUploadSection(
                frontImage: _frontImage,
                backImage: _backImage,
                errorText: _error,
                onFrontPicked: (file) => setState(() {
                  _frontImage = file;
                  _error = null;
                }),
                onBackPicked: (file) => setState(() {
                  _backImage = file;
                  _error = null;
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
