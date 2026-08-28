import 'package:acepool/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:acepool/core/utils/date_time_formatter.dart';
import 'package:acepool/features/home/presentation/bloc/home_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class ScheduleDateTimeRow extends StatelessWidget {
  const ScheduleDateTimeRow({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.seatCount,
    required this.vehicleType,
    required this.onDateTap,
    required this.onTimeTap,
    required this.onSeatCountChanged,
  });

  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final int seatCount;
  final VehicleType vehicleType;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;
  final ValueChanged<int> onSeatCountChanged;

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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onDateTap,
          child: Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.black87),
              const SizedBox(width: 12),
              Text(
                selectedDate != null
                    ? DateTimeFormatter.monthDayYear(selectedDate!)
                    : 'Select date',
                style: fieldStyle.copyWith(
                  color: selectedDate != null ? const Color(0xFF1E1E1E) : const Color(0xFF757474),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Divider(height: 1, color: AppColors.grey300),
        ),
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
                        color: selectedTime != null ? const Color(0xFF1E1E1E) : const Color(0xFF757474),
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
                      height: 1.25, // 20px / 16px
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
