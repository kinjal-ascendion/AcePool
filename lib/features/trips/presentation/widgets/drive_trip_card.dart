import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/features/home/domain/entities/upcoming_trip.dart';
import 'package:acepool/features/home/presentation/widgets/glass_card.dart';
import 'package:flutter/material.dart';

class DriveTripCard extends StatelessWidget {
  const DriveTripCard({
    super.key,
    required this.trip,
    this.showViewDetails = true,
    this.onChatTap,
    this.onTap,
    this.onStartRide,
    this.onEndRide,
    this.onCancel,
  });

  final UpcomingTrip trip;
  final bool showViewDetails;
  final VoidCallback? onChatTap;
  final VoidCallback? onTap;
  final VoidCallback? onStartRide;
  final VoidCallback? onEndRide;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final bool isInProgress = trip.status == 'in_progress';

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: seats-filled badge or status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    bottomRight: Radius.circular(20),
                  ),
                  child: ColoredBox(
                    color: isInProgress ? AppColors.primaryGreen : AppColors.primaryGreen,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isInProgress ? Icons.directions_car : Icons.person_outline,
                            color: AppColors.white,
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isInProgress ? 'Trip in Progress' : '${trip.seatsFilled}/${trip.seatsTotal} seats filled',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!isInProgress && onCancel != null)
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.more_vert, color: AppColors.grey600, size: 20),
                    onSelected: (val) {
                      if (val == 'cancel') onCancel!();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'cancel',
                        child: Row(
                          children: [
                            Icon(Icons.cancel_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Cancel Ride'),
                          ],
                        ),
                      ),
                    ],
                  ),
                if (isInProgress)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Text(
                      'Ride ID #${trip.id.substring(0, 5)}',
                      style: TextStyle(
                        color: AppColors.grey500,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
              ],
            ),

          // Card content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.dateLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  trip.timeLabel,
                  style: const TextStyle(color: AppColors.black45, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryGreen, width: 1.5),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        trip.fromAddress,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.black54),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      3,
                      (i) => Container(
                        width: 1.5,
                        height: 3,
                        margin: EdgeInsets.only(
                          top: i == 0 ? 0 : 1,
                          bottom: i == 2 ? 0 : 1,
                        ),
                        color: AppColors.black26,
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        trip.toAddress,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.black54),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(color: AppColors.grey200, height: 1),
                const SizedBox(height: 8),

                // Price + view details
                showViewDetails
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _fareLabel(trip.farePerSeat),
                          GestureDetector(
                            onTap: () {}, // Handled by parent
                            child: const Text(
                              'View Details',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.black54,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      )
                    : _fareLabel(trip.farePerSeat),
                const SizedBox(height: 8),

                // Group chat pill
                GestureDetector(
                  onTap: onChatTap,
                  child: Container(
                    padding: const EdgeInsets.only(
                        left: 16, right: 4, top: 4, bottom: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.grey200),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Start a group chat with all riders',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.grey500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: AppColors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Start/End Ride button
                if ((!isInProgress && onStartRide != null) || (isInProgress && onEndRide != null))
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isInProgress ? onEndRide : onStartRide,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.black,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: Text(
                        isInProgress ? 'End Ride' : 'Start Ride',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _fareLabel(double? farePerSeat) {
    return Text(
      farePerSeat != null ? '₹${farePerSeat.toStringAsFixed(2)} / seat' : 'Fare not set',
      style: TextStyle(
        color: farePerSeat != null ? AppColors.primaryGreen : AppColors.grey500,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
