import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/features/home/presentation/widgets/schedule_ride_button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RidePublishedPage extends StatelessWidget {
  const RidePublishedPage({
    super.key,
    required this.fromAddress,
    required this.toAddress,
    required this.farePerSeat,
    required this.seatsOffered,
    required this.estimatedEarnings,
  });

  final String fromAddress;
  final String toAddress;
  final double farePerSeat;
  final int seatsOffered;
  final double estimatedEarnings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x0A308666),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/tick_mark_with_circle.png',
                    width: 48, // Adjusted size to fit inside the 80x80 circle
                    height: 48,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.check_circle,
                      color: Color(0xFF1B8A3F),
                      size: 48,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Ride Published!',
                style: GoogleFonts.mulish(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 32 / 24,
                  color: const Color(0xFF0F1923),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your ride from $fromAddress to $toAddress is now live. Passengers can start booking.',
                textAlign: TextAlign.center,
                style: GoogleFonts.mulish(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 24 / 16,
                  color: const Color(0xFF7A8494),
                ),
              ),
              const SizedBox(height: 40),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                child: Column(
                  children: [
                    _SummaryRow(
                      label: 'Fare per seat',
                      value: '₹${farePerSeat.toStringAsFixed(2)}',
                      valueStyle: GoogleFonts.mulish(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 20 / 16,
                        color: const Color(0xFF1B8A3F),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SummaryRow(
                      label: 'Seats offered',
                      value: '$seatsOffered',
                      valueStyle: GoogleFonts.mulish(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 20 / 16,
                        color: const Color(0xFF0F1923),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: Color(0xFFF3F4F6), height: 1),
                    ),
                    _SummaryRow(
                      label: 'Est. earnings',
                      value: '₹${estimatedEarnings.toStringAsFixed(0)}',
                      valueStyle: GoogleFonts.mulish(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 20 / 16,
                        color: const Color(0xFF0F1923),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ScheduleRideButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                label: 'Back to Home',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle valueStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.mulish(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 20 / 16,
            color: const Color(0xFF7A8494),
          ),
        ),
        Text(value, style: valueStyle),
      ],
    );
  }
}
