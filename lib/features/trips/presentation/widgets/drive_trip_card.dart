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
  });

  final UpcomingTrip trip;
  final bool showViewDetails;
  final VoidCallback? onChatTap;


  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: seats-filled badge
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              bottomRight: Radius.circular(20),
            ),
            child: ColoredBox(
              color: AppColors.primaryGreen,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_outline,
                      color: AppColors.white,
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${trip.seatsFilled}/${trip.seatsTotal} seats filled',
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
                          const Text(
                            '₹ 600 / seat',
                            style: TextStyle(
                              color: AppColors.primaryGreen,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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
                    : const Text(
                        '₹ 600 / seat',
                        style: TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
