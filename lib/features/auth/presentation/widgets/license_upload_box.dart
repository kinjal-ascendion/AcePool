import 'dart:io';

import 'package:acepool/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class LicenseUploadBox extends StatelessWidget {
  const LicenseUploadBox({
    super.key,
    required this.label,
    required this.imageFile,
    required this.onTap,
    this.isVerifying = false,
    this.isValid,
  });

  final String label;
  final File? imageFile;
  final VoidCallback onTap;
  final bool isVerifying;
  final bool? isValid;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isVerifying ? null : onTap,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1.3,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grey300),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageFile != null)
                    Image.file(imageFile!, fit: BoxFit.cover)
                  else
                    const Center(
                      child: Icon(
                        Icons.camera_alt_outlined,
                        color: AppColors.black45,
                        size: 28,
                      ),
                    ),
                  if (isVerifying)
                    Container(
                      color: AppColors.black.withValues(alpha: 0.35),
                      child: const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    )
                  else if (isValid != null)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Icon(
                        isValid! ? Icons.check_circle : Icons.error,
                        color: isValid! ? Colors.green : Colors.redAccent,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.black54),
          ),
        ],
      ),
    );
  }
}
