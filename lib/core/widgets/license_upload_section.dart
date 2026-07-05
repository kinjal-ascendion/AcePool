import 'dart:io';

import 'package:acepool/core/utils/license_ocr_validator.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class LicenseUploadSection extends StatefulWidget {
  const LicenseUploadSection({
    super.key,
    required this.frontImage,
    required this.backImage,
    required this.onFrontPicked,
    required this.onBackPicked,
    this.errorText,
  });

  final File? frontImage;
  final File? backImage;
  final ValueChanged<File> onFrontPicked;
  final ValueChanged<File> onBackPicked;
  final String? errorText;

  @override
  State<LicenseUploadSection> createState() => _LicenseUploadSectionState();
}

class _LicenseUploadSectionState extends State<LicenseUploadSection> {
  bool _frontProcessing = false;
  bool _backProcessing = false;

  Future<void> _pickImage(
    BuildContext context,
    ValueChanged<File> onPicked,
    void Function(bool) setProcessing,
  ) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
    );
    if (picked == null) return;

    final file = File(picked.path);
    setProcessing(true);
    final looksValid = await LicenseOcrValidator.looksLikeDrivingLicense(file);
    if (!mounted) return;
    setProcessing(false);

    if (looksValid) {
      onPicked(file);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "This doesn't look like a valid driving license. "
            'Please retake or choose a clearer photo.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "DRIVER'S LICENSE",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Upload license image (Front & Back)',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'A valid license is required before scheduling a ride. '
          'Upload both sides to continue.',
          style: TextStyle(fontSize: 13, color: Colors.black45),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _UploadBox(
                image: widget.frontImage,
                label: 'Front',
                processing: _frontProcessing,
                onTap: () => _pickImage(
                  context,
                  widget.onFrontPicked,
                  (v) => setState(() => _frontProcessing = v),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _UploadBox(
                image: widget.backImage,
                label: 'Back',
                processing: _backProcessing,
                onTap: () => _pickImage(
                  context,
                  widget.onBackPicked,
                  (v) => setState(() => _backProcessing = v),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: widget.errorText != null
                  ? Colors.red.shade400
                  : Colors.orange.shade800,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.errorText ?? 'Required before you can schedule a ride',
                style: TextStyle(
                  fontSize: 12,
                  color: widget.errorText != null
                      ? Colors.red.shade600
                      : Colors.orange.shade800,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _UploadBox extends StatelessWidget {
  const _UploadBox({
    required this.image,
    required this.label,
    required this.onTap,
    required this.processing,
  });

  final File? image;
  final String label;
  final VoidCallback onTap;
  final bool processing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: processing ? null : onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          clipBehavior: Clip.antiAlias,
          child: processing
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : image != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(image!, fit: BoxFit.cover),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.grey.shade500,
                      size: 26,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
