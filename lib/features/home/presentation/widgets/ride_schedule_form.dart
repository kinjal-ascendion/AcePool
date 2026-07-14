import 'package:acepool/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:acepool/features/home/presentation/bloc/home_bloc.dart';
import 'package:acepool/features/home/presentation/widgets/glass_card.dart';
import 'package:acepool/features/home/presentation/widgets/location_swap_row.dart';
import 'package:acepool/features/home/presentation/widgets/schedule_date_time_row.dart';
import 'package:acepool/features/home/presentation/widgets/schedule_ride_button.dart';
import 'package:acepool/features/home/presentation/widgets/vehicle_type_toggle.dart';

class RideScheduleForm extends StatelessWidget {
  const RideScheduleForm({
    super.key,
    required this.vehicleType,
    required this.fromAddress,
    required this.toAddress,
    required this.selectedDate,
    required this.selectedTime,
    required this.seatCount,
    required this.isScheduling,
    required this.isFormValid,
    required this.onVehicleTypeChanged,
    required this.onFromTap,
    required this.onToTap,
    required this.onSwap,
    required this.onDateTap,
    required this.onTimeTap,
    required this.onSeatCountChanged,
    required this.onSchedulePressed,
    required this.rideMode,
  });

  final RideMode rideMode;
  final VehicleType vehicleType;
  final String? fromAddress;
  final String? toAddress;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final int seatCount;
  final bool isScheduling;
  final bool isFormValid;
  final ValueChanged<VehicleType> onVehicleTypeChanged;
  final VoidCallback onFromTap;
  final VoidCallback onToTap;
  final VoidCallback onSwap;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;
  final ValueChanged<int> onSeatCountChanged;
  final VoidCallback onSchedulePressed;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 26,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VehicleTypeToggle(selected: vehicleType, onChanged: onVehicleTypeChanged),
          const SizedBox(height: 16),
          LocationSwapRow(
            fromAddress: fromAddress,
            toAddress: toAddress,
            onSwap: onSwap,
            onFromTap: onFromTap,
            onToTap: onToTap,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: AppColors.grey300),
          ),
          ScheduleDateTimeRow(
            selectedDate: selectedDate,
            selectedTime: selectedTime,
            seatCount: seatCount,
            vehicleType: vehicleType,
            onDateTap: onDateTap,
            onTimeTap: onTimeTap,
            onSeatCountChanged: onSeatCountChanged,
          ),
          const SizedBox(height: 20),
          ScheduleRideButton(
            onPressed: isFormValid && !isScheduling ? onSchedulePressed : null,
            label: rideMode == RideMode.find ? 'Find ride' : 'Schedule ride',
            isLoading: isScheduling,
          ),
        ],
      ),
    );
  }
}
