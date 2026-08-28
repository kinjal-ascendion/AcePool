import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/features/home/domain/entities/upcoming_trip.dart';
import 'package:acepool/features/home/presentation/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    this.onEditFare,
    this.onEditPayment,
  });

  final UpcomingTrip trip;
  final bool showViewDetails;
  final VoidCallback? onChatTap;
  final VoidCallback? onTap;
  final VoidCallback? onStartRide;
  final VoidCallback? onEndRide;
  final VoidCallback? onCancel;
  final VoidCallback? onEditFare;
  final VoidCallback? onEditPayment;

  @override
  Widget build(BuildContext context) {
    final bool isInProgress = trip.status == 'in_progress';

    return GlassCard(
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
                  color: AppColors.primaryGreen, // Match brand green (arrow mark color)
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/person_icon.png',
                          width: 15,
                          height: 15,
                          color: Colors.white,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.person_outline,
                            color: Colors.white,
                            size: 15,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${trip.seatsFilled}/${trip.seatsTotal} seats filled',
                          style: GoogleFonts.mulish(
                            color: const Color(0xFFFEFEFE),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.125, // 18/16
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
            ],
          ),

          // Card content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.dateLabel,
                  style: GoogleFonts.mulish(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    height: 1.125, // 18/16
                    color: const Color(0xFF1D1D1D),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      trip.timeLabel,
                      style: GoogleFonts.mulish(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.125, // 18/16
                        color: const Color(0xFF1E1E1E),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            trip.vehicleType == 'bike'
                                ? Icons.two_wheeler
                                : Icons.directions_car,
                            size: 16,
                            color: const Color(0xFF1E1E1E),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            trip.vehicleType == 'bike' ? 'Bike' : 'Car',
                            style: GoogleFonts.mulish(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E1E1E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        _dot(filled: false),
                        Container(
                          width: 1.5,
                          height: 24,
                          color: AppColors.black26,
                        ),
                        _dot(filled: true),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.fromAddress,
                            style: GoogleFonts.mulish(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              height: 1.125, // 18/16
                              color: const Color(0xFF757474),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            trip.toAddress,
                            style: GoogleFonts.mulish(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              height: 1.125, // 18/16
                              color: const Color(0xFF757474),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/universal_currency.png',
                          width: 24,
                          height: 24,
                          color: const Color(0xFF1E1E1E),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          trip.farePerSeat != null ? '₹${trip.farePerSeat!.toStringAsFixed(0)} / seat' : 'Fare not set',
                          style: GoogleFonts.mulish(
                            color: const Color(0xFF1B8A3F),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.125, // 18/16
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: onEditFare,
                      child: Text(
                        'Edit',
                        style: GoogleFonts.mulish(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.28, // 18/14
                          color: const Color(0xFF757474),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFFDDDDDD), height: 1),
                const SizedBox(height: 12),
                const SizedBox(height: 12),
                
                // Payment Method section
                Text(
                  'Payment Method',
                  style: GoogleFonts.mulish(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.125, // 18/16
                    color: const Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/currency_rupee_circle.png',
                          width: 20,
                          height: 20,
                          color: const Color(0xFF1E1E1E),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'UPI',
                          style: GoogleFonts.mulish(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E1E1E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.payments_outlined, size: 16, color: Color(0xFF1E1E1E)),
                        const SizedBox(width: 4),
                        Text(
                          'Cash',
                          style: GoogleFonts.mulish(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E1E1E),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onEditPayment,
                      child: Text(
                        'Edit',
                        style: GoogleFonts.mulish(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.28, // 18/14
                          color: const Color(0xFF616874),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),

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
                            style: GoogleFonts.mulish(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              height: 1.125, // 18/16
                              color: const Color(0xFF757474),
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
                        style: GoogleFonts.mulish(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                          color: const Color(0xFFFEFEFE),
                        ),
                      ),
                    ),
                  ),
                
                // Figma also has one at the bottom
                if (showViewDetails) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: GestureDetector(
                      onTap: onTap,
                      child: Text(
                        'View Ride Details',
                        style: GoogleFonts.mulish(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.28, // 18/14
                          color: const Color(0xFF616874),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot({required bool filled}) {
    return Container(
      width: 10,
      height: 10,
      decoration: filled
          ? const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryGreen,
            )
          : BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryGreen, width: 1.5),
            ),
    );
  }
}
