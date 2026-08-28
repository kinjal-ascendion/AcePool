import 'package:acepool/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LocationSwapRow extends StatelessWidget {
  const LocationSwapRow({
    super.key,
    required this.fromAddress,
    required this.toAddress,
    required this.onSwap,
    this.onFromTap,
    this.onToTap,
  });

  final String? fromAddress;
  final String? toAddress;
  final VoidCallback onSwap;
  final VoidCallback? onFromTap;
  final VoidCallback? onToTap;

  @override
  Widget build(BuildContext context) {
    final addressStyle = GoogleFonts.mulish(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 20 / 16,
      letterSpacing: 16 * 0.01,
      color: const Color(0xFF1E1E1E),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Dots + dashed connector
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryGreen, width: 1.5),
              ),
            ),
            ...List.generate(
              4,
              (_) => Container(
                width: 1.5,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 2),
                color: AppColors.black26,
              ),
            ),
            Container(
              width: 11,
              height: 11,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGreen,
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        // Text fields
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: onFromTap,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 6),
                  child: Text(
                    fromAddress ?? 'Enter start location',
                    style: addressStyle.copyWith(
                      color: fromAddress != null ? const Color(0xFF1E1E1E) : AppColors.black45,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Divider(height: 1, color: AppColors.grey300),
              InkWell(
                onTap: onToTap,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 2),
                  child: Text(
                    toAddress ?? 'Enter office location',
                    style: addressStyle.copyWith(
                      color: toAddress != null ? const Color(0xFF1E1E1E) : AppColors.black45,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Swap icon
        GestureDetector(
          onTap: onSwap,
          child: const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Icon(Icons.swap_vert, color: AppColors.black54, size: 22),
          ),
        ),
      ],
    );
  }
}
