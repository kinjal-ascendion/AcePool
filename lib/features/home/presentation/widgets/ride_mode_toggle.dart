import 'package:acepool/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:acepool/features/home/presentation/bloc/home_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class RideModeToggle extends StatelessWidget {
  const RideModeToggle({super.key, required this.selected, required this.onChanged});

  final RideMode selected;
  final ValueChanged<RideMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: 240,
        height: 40,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F1F2), // Updated to match requested neutral background
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _PillButton(
                label: 'Find ride',
                selected: selected == RideMode.find,
                onTap: () => onChanged(RideMode.find),
                fontWeight: FontWeight.w600,
                textColor: const Color(0xFF1E1E1E),
              ),
            ),
            Expanded(
              child: _PillButton(
                label: 'Offer ride',
                selected: selected == RideMode.offer,
                onTap: () => onChanged(RideMode.offer),
                fontWeight: FontWeight.w700,
                textColor: const Color(0xFF1E1E1E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.fontWeight,
    required this.textColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final FontWeight fontWeight;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1E1E1E) : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(
          label,
          style: GoogleFonts.mulish(
            color: selected ? (label == 'Offer ride' ? const Color(0xFFF0F1F2) : Colors.white) : textColor,
            fontWeight: fontWeight,
            fontSize: 14,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
