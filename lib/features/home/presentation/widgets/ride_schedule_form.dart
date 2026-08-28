import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/core/utils/ride_matcher.dart';
import 'package:flutter/material.dart';
import 'package:acepool/features/home/presentation/bloc/home_bloc.dart';
import 'package:acepool/features/home/presentation/widgets/glass_card.dart';
import 'package:acepool/features/home/presentation/widgets/location_swap_row.dart';
import 'package:acepool/features/home/presentation/widgets/schedule_date_time_row.dart';
import 'package:acepool/features/home/presentation/widgets/schedule_ride_button.dart';
import 'package:acepool/features/home/presentation/widgets/vehicle_type_toggle.dart';
import 'package:acepool/features/home/domain/entities/picked_location.dart';
import 'package:acepool/features/home/presentation/widgets/cab_booking_form.dart';

class RideScheduleForm extends StatelessWidget {
  const RideScheduleForm({
    super.key,
    required this.vehicleType,
    required this.fromAddress,
    required this.toAddress,
    this.fromLat,
    this.fromLng,
    this.toLat,
    this.toLng,
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
    required this.onCabLocationTap,
required this.onCabBookPressed,
  });

  final RideMode rideMode;
  final VehicleType vehicleType;
  final String? fromAddress;
  final String? toAddress;
  final double? fromLat;
  final double? fromLng;
  final double? toLat;
  final double? toLng;
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
final Future<PickedLocation?> Function(
  String title,
  String? current,
) onCabLocationTap;

final VoidCallback onCabBookPressed;
  @override
  Widget build(BuildContext context) {

if (vehicleType == VehicleType.cab) {
  return CabBookingForm(
    rideMode: rideMode,
    onVehicleTypeChanged: onVehicleTypeChanged,
    startAddress: fromAddress,
    destinationAddress: toAddress,
    onStartTap: onFromTap,
    onDestinationTap: onToTap,
    onLocationTap: onCabLocationTap,
    selectedDate: selectedDate,
    selectedTime: selectedTime,
    onDateTap: onDateTap,
    onTimeTap: onTimeTap,
     passengerCount: seatCount,
  onPassengerCountChanged: onSeatCountChanged,
    onBookPressed: onCabBookPressed,
  );
}

    double? distanceKm;
    if (fromLat != null && fromLng != null && toLat != null && toLng != null) {
      distanceKm = RideMatcher.distanceKm(fromLat!, fromLng!, toLat!, toLng!);
    }
    final isDistanceTooShort = distanceKm != null && distanceKm < 0.5;

    return GlassCard(
      borderRadius: 26,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VehicleTypeToggle(selected: vehicleType, rideMode: rideMode, onChanged: onVehicleTypeChanged),
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
            onPressed: isFormValid && !isScheduling && !isDistanceTooShort
                ? onSchedulePressed
                : null,
            label: rideMode == RideMode.find ? 'Find ride' : 'Schedule ride',
            isLoading: isScheduling,
          ),
          if (isDistanceTooShort) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Color(0xFFD97706), // amber-600 color
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'The distance between the pickup and drop-off locations must be at least 0.5 km.',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFFD97706),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
