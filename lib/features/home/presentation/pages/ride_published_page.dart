import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/features/home/presentation/widgets/glass_card.dart';
import 'package:acepool/features/home/presentation/widgets/schedule_ride_button.dart';
import 'package:flutter/material.dart';

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
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: AppColors.primaryGreen,
                        size: 56,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Ride Published!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Your ride from $fromAddress to $toAddress is now live. '
                      'Passengers can start booking.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.grey600, height: 1.4),
                    ),
                    const SizedBox(height: 28),
                    GlassCard(
                      borderRadius: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      child: Column(
                        children: [
                          _SummaryRow(
                            label: 'Fare per seat',
                            value: '₹${farePerSeat.toStringAsFixed(2)}',
                          ),
                          const SizedBox(height: 12),
                          _SummaryRow(label: 'Seats offered', value: '$seatsOffered'),
                          const SizedBox(height: 12),
                          _SummaryRow(
                            label: 'Est. earnings',
                            value: '₹${estimatedEarnings.toStringAsFixed(0)}',
                            valueColor: AppColors.primaryGreen,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ScheduleRideButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
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
  const _SummaryRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: AppColors.grey600)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.black87,
          ),
        ),
      ],
    );
  }
}
