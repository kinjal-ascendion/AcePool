import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  final String fullName;
  final String employeeId;
  final String mobile;

  const EditProfilePage({
    super.key,
    required this.fullName,
    required this.employeeId,
    required this.mobile,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _employeeIdController;
  late final TextEditingController _mobileController;
  late final TextEditingController _emailController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _nameController =
        TextEditingController(text: widget.fullName);

    _employeeIdController =
        TextEditingController(text: widget.employeeId);

    _mobileController =
        TextEditingController(text: widget.mobile);

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
    super.dispose();
  }

  Future<void> _saveProfile() async {
    try {
      setState(() => _isSaving = true);

      final uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'acepool',
      ).collection('users').doc(uid).update({
        'fullName': _nameController.text.trim(),
        'employeeId': _employeeIdController.text.trim(),
        'mobile': _mobileController.text.trim(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),

        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: Colors.lightBlue,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  keyboardType: keyboardType,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                ),
              ),

              if (enabled)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 18,
                    color: Colors.blue,
                  ),
                ),
            ],
          ),
        ),
      ],
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
                    "Edit Profile",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const Spacer(),

                  ElevatedButton(
                    onPressed:
                        _isSaving ? null : _saveProfile,
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
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
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
            ],
          ),
        ),
      ),
    );
  }
}