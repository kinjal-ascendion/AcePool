import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class RiderCountStepper extends StatelessWidget {
  const RiderCountStepper({
    super.key,
    required this.count,
    required this.onChanged,
    this.min = 1,
    this.max = 4,
  });

  final int count;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepperButton(
          icon: Icons.remove,
          onTap: count > min ? () => onChanged(count - 1) : null,
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$count',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        _StepperButton(
          icon: Icons.add,
          filled: true,
          onTap: count < max ? () => onChanged(count + 1) : null,
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap, this.filled = false});

  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled && !disabled ? AppTheme.scheduleButtonColor : AppColors.transparent,
          border: filled
              ? null
              : Border.all(color: disabled ? AppColors.grey300 : AppColors.grey400),
        ),
        child: Icon(
          icon,
          size: 16,
          color: filled && !disabled
              ? AppColors.white
              : (disabled ? AppColors.grey300 : AppColors.black87),
        ),
      ),
    );
  }
}
