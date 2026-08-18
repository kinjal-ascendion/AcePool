import 'package:acepool/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:acepool/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class ScheduleRideButton extends StatelessWidget {
  const ScheduleRideButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.scheduleButtonColor,
          disabledBackgroundColor: AppColors.grey300,
          foregroundColor: const Color(0xFFFEFEFE),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFEFEFE)),
              )
            : Text(
                label,
                style: GoogleFonts.mulish(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  height: 1.0,
                ),
              ),
      ),
    );
  }
}
