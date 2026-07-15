import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/core/utils/ride_matcher.dart';
import 'package:acepool/features/rides/domain/entities/ride_match.dart';
import 'package:acepool/features/rides/presentation/widgets/ride_result_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FindRideResultsSection extends StatelessWidget {
  const FindRideResultsSection({
    super.key,
    required this.results,
    required this.isLoading,
    required this.hasSearched,
    required this.riderFromAddress,
    required this.riderTime,
    required this.db,
    required this.onRequested,
    this.onViewAll,
    this.riderFromLat,
    this.riderFromLng,
    this.currentLat,
    this.currentLng,
  });

  final List<RideMatch> results;
  final bool isLoading;
  final bool hasSearched;
  final String riderFromAddress;
  final TimeOfDay riderTime;
  final FirebaseFirestore db;
  final VoidCallback onRequested;
  final VoidCallback? onViewAll;
  final double? riderFromLat;
  final double? riderFromLng;
  final double? currentLat;
  final double? currentLng;

  @override
  Widget build(BuildContext context) {
    if (!hasSearched && !isLoading) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Matching rides',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (results.isNotEmpty)
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
        if (currentLat != null &&
            currentLng != null &&
            riderFromLat != null &&
            riderFromLng != null) ...[
          const SizedBox(height: 4),
          Text(
            'Your pickup point is ${RideMatcher.formatDistance(RideMatcher.distanceKm(
              currentLat!,
              currentLng!,
              riderFromLat!,
              riderFromLng!,
            ))} from your current location',
            style: TextStyle(fontSize: 12.5, color: AppColors.grey600),
          ),
        ],
        const SizedBox(height: 12),
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (results.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No rides available for this date',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.grey500, fontSize: 15),
              ),
            ),
          )
        else
          for (final result in results.take(3)) ...[
            RideResultCard(
              result: result,
              riderFromAddress: riderFromAddress,
              riderTime: riderTime,
              db: db,
              onRequested: onRequested,
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}
