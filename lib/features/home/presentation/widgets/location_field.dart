import 'package:acepool/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LocationField extends StatelessWidget {
  const LocationField({
    super.key,
    required this.address,
    required this.placeholder,
    required this.isFilled,
    this.onTap,
  });

  final String? address;
  final String placeholder;
  final bool isFilled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final green = Theme.of(context).colorScheme.primary;
    final hasAddress = address != null;
    final content = Row(
      children: [
        isFilled
            ? Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: green, shape: BoxShape.circle),
              )
            : Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: green, width: 1.5),
                ),
              ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            address ?? placeholder,
            style: GoogleFonts.mulish(
              color: hasAddress ? AppColors.black87 : const Color(0xFF757474),
              fontWeight: hasAddress ? FontWeight.w600 : FontWeight.w400,
              fontSize: 16,
              height: 1.25, // 20px line-height / 16px font-size
              letterSpacing: 16 * 0.01, // 1%
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    if (onTap == null) return content;
    return InkWell(onTap: onTap, child: content);
  }
}
