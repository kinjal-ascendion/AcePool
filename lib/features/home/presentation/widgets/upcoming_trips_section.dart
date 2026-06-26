import 'package:acepool/features/home/domain/entities/upcoming_trip.dart';
import 'package:acepool/features/home/presentation/widgets/trip_card.dart';
import 'package:acepool/features/rides/presentation/pages/drives_detail_page.dart';
import 'package:flutter/material.dart';

class UpcomingTripsSection extends StatelessWidget {
  const UpcomingTripsSection({
    super.key,
    required this.trips,
    this.isLoading = false,
    this.onViewAll,
  });

  final List<UpcomingTrip> trips;
  final bool isLoading;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upcoming trips',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'View all',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (trips.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No upcoming trips.\nSchedule a ride to get started!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black45),
              ),
            ),
          )
        else
          for (final trip in trips.take(3)) ...[
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DrivesDetailPage(trip: trip),
                ),
              ),
              child: TripCard(trip: trip),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}
