import 'package:flutter/material.dart';
import 'package:acepool/features/home/presentation/bloc/home_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class VehicleTypeToggle extends StatelessWidget {
  const VehicleTypeToggle({super.key, required this.selected, required this.onChanged, required this.rideMode});

  final VehicleType selected;
  final ValueChanged<VehicleType> onChanged;
  final RideMode rideMode;

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
        if (rideMode == RideMode.offer) ...[
          const SizedBox(width: 24),
          _RadioOption(
           label: 'Cab',
           selected: selected == VehicleType.cab,
           onTap: () => onChanged(VehicleType.cab),
          ),
        ],
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
    const Color activeColor = Color(0xFF1E1E1E);
    const Color inactiveColor = Color(0xFF757474);
    
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: selected ? activeColor : inactiveColor, width: 2),
            ),
            child: selected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(color: activeColor, shape: BoxShape.circle),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.mulish(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              height: 1.125, // 18px line-height / 16px font-size
              color: selected ? activeColor : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }
}
