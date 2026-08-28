import 'package:acepool/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeAppBarGreeting extends StatelessWidget {
  const HomeAppBarGreeting({
    super.key,
    required this.initials,
    required this.name,
    this.onAvatarTap,
  });

  final String initials;
  final String name;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onAvatarTap,
          child: CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.black87,
            child: Text(
              initials,
              style: GoogleFonts.mulish(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Hi, $name 👋🏻',
          style: GoogleFonts.mulish(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            height: 1.0,
            color: const Color(0xFF1E1E1E),
          ),
        ),
      ],
    );
  }
}
