import 'package:flutter/material.dart';
import 'package:acepool/features/home/domain/entities/upcoming_trip.dart';
import 'package:acepool/features/home/presentation/widgets/glass_card.dart';
import 'package:acepool/features/home/presentation/widgets/location_field.dart';

class TripCard extends StatelessWidget {
  const TripCard({super.key, required this.trip, this.onMenuTap});

  final UpcomingTrip trip;
  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).colorScheme.secondary;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: secondary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${trip.seatsFilled}/${trip.seatsTotal} seats filled',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // TODO: wire to trip detail/cancel actions once that feature exists
              IconButton(
                onPressed: onMenuTap,
                icon: const Icon(Icons.more_vert, color: Colors.black54),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(trip.dateLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(trip.timeLabel, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 12),
          LocationField(address: trip.fromAddress, placeholder: '', isFilled: false),
          const SizedBox(height: 8),
          LocationField(address: trip.toAddress, placeholder: '', isFilled: true),
        ],
      ),
    );
  }
}
