import 'package:flutter/material.dart';
import 'package:acepool/core/theme/app_theme.dart';
import 'package:acepool/features/home/presentation/bloc/home_bloc.dart';

class RideModeToggle extends StatelessWidget {
  const RideModeToggle({super.key, required this.selected, required this.onChanged});

  final RideMode selected;
  final ValueChanged<RideMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PillButton(
            label: 'Find ride',
            selected: selected == RideMode.find,
            color: AppTheme.scheduleButtonColor,
            onTap: () => onChanged(RideMode.find),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PillButton(
            label: 'Offer ride',
            selected: selected == RideMode.offer,
            color: AppTheme.scheduleButtonColor,
            onTap: () => onChanged(RideMode.offer),
          ),
        ),
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color : Colors.grey.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
