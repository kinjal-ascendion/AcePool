import 'package:acepool/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:acepool/core/theme/app_theme.dart';
import 'package:acepool/features/home/presentation/bloc/home_bloc.dart';

class VehicleTypeToggle extends StatelessWidget {
  const VehicleTypeToggle({super.key, required this.selected, required this.onChanged});

  final VehicleType selected;
  final ValueChanged<VehicleType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RadioOption(
          label: 'Car',
          selected: selected == VehicleType.car,
          onTap: () => onChanged(VehicleType.car),
        ),
        const SizedBox(width: 24),
        _RadioOption(
          label: 'Bike',
          selected: selected == VehicleType.bike,
          onTap: () => onChanged(VehicleType.bike),
        ),
      ],
    );
  }
}

class _RadioOption extends StatelessWidget {
  const _RadioOption({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const active = AppTheme.scheduleButtonColor;
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: selected ? active : AppColors.black38, width: 2),
            ),
            child: selected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(color: active, shape: BoxShape.circle),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? AppColors.black87 : AppColors.grey600,
            ),
          ),
        ],
      ),
    );
  }
}
