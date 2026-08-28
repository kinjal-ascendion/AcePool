import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/features/home/presentation/widgets/schedule_ride_button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RideSummary {
  final String label; // "Going" or "Return"
  final String fromAddress;
  final String toAddress;
  final double farePerSeat;
  final int seatsOffered;
  final double estimatedEarnings;

  const RideSummary({
    required this.label,
    required this.fromAddress,
    required this.toAddress,
    required this.farePerSeat,
    required this.seatsOffered,
    required this.estimatedEarnings,
  });
}

class RidePublishedPage extends StatelessWidget {
  const RidePublishedPage({
    super.key,
    required this.rides,
  });

  final List<RideSummary> rides;

  @override
  Widget build(BuildContext context) {
    final isBoth = rides.length > 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
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
                    width: 48,
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
                isBoth ? 'Both Rides Published!' : 'Ride Published!',
                style: GoogleFonts.mulish(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 32 / 24,
                  color: const Color(0xFF0F1923),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ...rides.map((ride) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _RideCard(ride: ride),
                  )),
              const SizedBox(height: 24),
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

class _RideCard extends StatelessWidget {
  final RideSummary ride;

  const _RideCard({required this.ride});

  @override
  Widget build(BuildContext context) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1F1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              ride.label,
              style: GoogleFonts.mulish(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF757474),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${ride.fromAddress.toUpperCase()} - ${ride.toAddress.toUpperCase()}',
            style: GoogleFonts.mulish(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F1923),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFF3F4F6), height: 1),
          ),
          _SummaryRow(
            label: 'Fare per seat',
            value: '₹${ride.farePerSeat.toStringAsFixed(0)}',
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
            value: '${ride.seatsOffered}',
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
            value: '₹${ride.estimatedEarnings.toStringAsFixed(0)}',
            valueStyle: GoogleFonts.mulish(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 20 / 16,
              color: const Color(0xFF0F1923),
            ),
          ),
        ],
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
