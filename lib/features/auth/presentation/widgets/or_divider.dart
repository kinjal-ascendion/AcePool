import 'package:acepool/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.grey300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: const Text(
            'OR',
            style: TextStyle(
              color: AppColors.black45,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.grey300)),
      ],
    );
  }
}
