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
    required this.onVehicleTypeChanged,
    required this.onSwap,
    required this.onDateTap,
    required this.onTimeTap,
    required this.onSeatCountChanged,
    required this.onSchedulePressed,
  });

  final VehicleType vehicleType;
  final String? fromAddress;
  final String? toAddress;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final int seatCount;
  final ValueChanged<VehicleType> onVehicleTypeChanged;
  final VoidCallback onSwap;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;
  final ValueChanged<int> onSeatCountChanged;
  final VoidCallback onSchedulePressed;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      opacity: 1,
      borderRadius: 26,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VehicleTypeToggle(selected: vehicleType, onChanged: onVehicleTypeChanged),
          const SizedBox(height: 16),
          LocationSwapRow(fromAddress: fromAddress, toAddress: toAddress, onSwap: onSwap),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1),
          ),
          ScheduleDateTimeRow(
            selectedDate: selectedDate,
            selectedTime: selectedTime,
            seatCount: seatCount,
            onDateTap: onDateTap,
            onTimeTap: onTimeTap,
            onSeatCountChanged: onSeatCountChanged,
          ),
          const SizedBox(height: 20),
          ScheduleRideButton(onPressed: onSchedulePressed),
        ],
      ),
    );
  }
}
