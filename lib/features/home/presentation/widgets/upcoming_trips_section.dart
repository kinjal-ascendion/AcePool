import 'package:flutter/material.dart';
import 'package:acepool/features/home/domain/entities/upcoming_trip.dart';
import 'package:acepool/features/home/presentation/widgets/trip_card.dart';

class UpcomingTripsSection extends StatelessWidget {
  const UpcomingTripsSection({super.key, required this.trips, this.onViewAll});

  final List<UpcomingTrip> trips;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Upcoming trips',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // TODO: wire once a full trips-list page exists
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'View all',
                style: TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final trip in trips) ...[
          TripCard(trip: trip),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
