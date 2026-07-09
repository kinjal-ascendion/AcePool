import 'package:acepool/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

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
              5,
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
            children: [
              InkWell(
                onTap: onFromTap,
                child: SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      fromAddress ?? 'Enter start location',
                      style: TextStyle(
                        color: fromAddress != null ? AppColors.black87 : AppColors.black38,
                        fontWeight:
                            fromAddress != null ? FontWeight.w500 : FontWeight.normal,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              Divider(height: 1, color: AppColors.grey300),
              InkWell(
                onTap: onToTap,
                child: SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      toAddress ?? 'Enter office location',
                      style: TextStyle(
                        color: toAddress != null ? AppColors.black87 : AppColors.black38,
                        fontWeight:
                            toAddress != null ? FontWeight.w500 : FontWeight.normal,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
