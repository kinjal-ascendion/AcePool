import 'package:acepool/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class SsoButton extends StatelessWidget {
  const SsoButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
    this.label = 'Sign in with Microsoft',
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.grey300),
          foregroundColor: AppColors.black87,
          disabledForegroundColor: AppColors.grey500,
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _MicrosoftLogo(size: 18),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _MicrosoftLogo extends StatelessWidget {
  const _MicrosoftLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final cell = size / 2 - 1;
    Widget square(Color color) =>
        Container(width: cell, height: cell, color: color);

    return SizedBox(
      width: size,
      height: size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              square(const Color(0xFFF25022)),
              const SizedBox(width: 2),
              square(const Color(0xFF7FBA00)),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              square(const Color(0xFF00A4EF)),
              const SizedBox(width: 2),
              square(const Color(0xFFFFB900)),
            ],
          ),
        ],
      ),
    );
  }
}
