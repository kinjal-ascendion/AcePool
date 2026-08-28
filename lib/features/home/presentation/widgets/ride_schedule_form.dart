import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/core/utils/date_time_formatter.dart';
import 'package:acepool/core/utils/ride_matcher.dart';
import 'package:flutter/material.dart';
import 'package:acepool/features/home/presentation/bloc/home_bloc.dart';
import 'package:acepool/features/home/presentation/widgets/glass_card.dart';
import 'package:acepool/features/home/presentation/widgets/location_swap_row.dart';
import 'package:acepool/features/home/presentation/widgets/schedule_date_time_row.dart';
import 'package:acepool/features/home/presentation/widgets/schedule_ride_button.dart';
import 'package:acepool/features/home/presentation/widgets/vehicle_type_toggle.dart';
import 'package:google_fonts/google_fonts.dart';
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
    required this.shouldScheduleReturn,
    required this.returnTime,
    required this.returnSeatCount,
    required this.isScheduling,
    required this.isFormValid,
    required this.onVehicleTypeChanged,
    required this.onFromTap,
    required this.onToTap,
    required this.onSwap,
    required this.onDateTap,
    required this.onTimeTap,
    required this.onSeatCountChanged,
    required this.onScheduleReturnToggled,
    required this.onReturnTimeTap,
    required this.onReturnSeatCountChanged,
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
  final bool shouldScheduleReturn;
  final TimeOfDay? returnTime;
  final int returnSeatCount;
  final bool isScheduling;
  final bool isFormValid;
  final ValueChanged<VehicleType> onVehicleTypeChanged;
  final VoidCallback onFromTap;
  final VoidCallback onToTap;
  final VoidCallback onSwap;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;
  final ValueChanged<int> onSeatCountChanged;
  final ValueChanged<bool> onScheduleReturnToggled;
  final VoidCallback onReturnTimeTap;
  final ValueChanged<int> onReturnSeatCountChanged;
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
          if (rideMode == RideMode.offer) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, color: AppColors.grey300),
            ),
            _ReturnRideCheckbox(
              value: shouldScheduleReturn,
              onChanged: onScheduleReturnToggled,
            ),
            if (shouldScheduleReturn) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: AppColors.grey300),
              ),
              _ReturnRideSection(
                fromAddress: toAddress,
                toAddress: fromAddress,
                selectedTime: returnTime,
                seatCount: returnSeatCount,
                vehicleType: vehicleType,
                onTimeTap: onReturnTimeTap,
                onSeatCountChanged: onReturnSeatCountChanged,
              ),
            ],
          ],
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

class _ReturnRideCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ReturnRideCheckbox({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: value ? const Color(0xFF2E7D32) : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: value ? const Color(0xFF2E7D32) : const Color(0xFFBBBEC5),
                width: 1.5,
              ),
            ),
            child: value
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Text(
            'Schedule Return Ride',
            style: GoogleFonts.mulish(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 20 / 16,
              letterSpacing: 16 * 0.01,
              color: const Color(0xFF757474),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReturnRideSection extends StatelessWidget {
  final String? fromAddress;
  final String? toAddress;
  final TimeOfDay? selectedTime;
  final int seatCount;
  final VehicleType vehicleType;
  final VoidCallback onTimeTap;
  final ValueChanged<int> onSeatCountChanged;

  const _ReturnRideSection({
    required this.fromAddress,
    required this.toAddress,
    required this.selectedTime,
    required this.seatCount,
    required this.vehicleType,
    required this.onTimeTap,
    required this.onSeatCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    final maxSeats = vehicleType == VehicleType.bike ? 1 : 4;
    final TextStyle fieldStyle = GoogleFonts.mulish(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 20 / 16,
      letterSpacing: 16 * 0.01,
      color: const Color(0xFF1E1E1E),
    );

    return Column(
      children: [
        Row(
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
                  Text(
                    fromAddress ?? 'Enter start location',
                    style: fieldStyle.copyWith(
                      color: fromAddress != null ? const Color(0xFF1E1E1E) : AppColors.black45,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Divider(height: 1, color: AppColors.grey300),
                  const SizedBox(height: 10),
                  Text(
                    toAddress ?? 'Enter office location',
                    style: fieldStyle.copyWith(
                      color: toAddress != null ? const Color(0xFF1E1E1E) : AppColors.black45,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.swap_vert, color: AppColors.black54, size: 22),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onTimeTap,
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 18, color: AppColors.black87),
                    const SizedBox(width: 12),
                    Text(
                      selectedTime != null
                          ? DateTimeFormatter.time12h(selectedTime!)
                          : 'Choose time',
                      style: fieldStyle.copyWith(
                        color: selectedTime != null ? AppColors.black87 : const Color(0xFF757474),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              height: 18,
              width: 1,
              color: AppColors.grey300,
              margin: const EdgeInsets.symmetric(horizontal: 12),
            ),
            PopupMenuButton<int>(
              initialValue: seatCount,
              onSelected: onSeatCountChanged,
              itemBuilder: (context) => List.generate(
                maxSeats,
                (i) => PopupMenuItem(value: i + 1, child: Text('${i + 1}')),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 18, color: Color(0xFF757474)),
                  const SizedBox(width: 6),
                  Text(
                    '$seatCount',
                    style: GoogleFonts.mulish(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      height: 1.25,
                      letterSpacing: 16 * 0.01,
                      color: const Color(0xFF757474),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF757474)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
