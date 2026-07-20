import 'package:flutter/material.dart';
import 'package:acepool/core/theme/app_colors.dart';

class RideCard extends StatelessWidget {
  final String date;
  final String time;
  final String pickup;
  final String drop;
  final double rating;
  final int reviews;
  final Widget? trailing;
  final VoidCallback? onReview;

  const RideCard({
    super.key,
    required this.date,
    required this.time,
    required this.pickup,
    required this.drop,
    required this.rating,
    required this.reviews,
    this.trailing,
    this.onReview,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.grey200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        date,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(time, style: TextStyle(color: AppColors.grey700)),
                    ],
                  ),
                ),

                trailing ??
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: List.generate(
                            5,
                            (index) => Icon(
                              index < rating.round()
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$reviews reviews",
                          style: TextStyle(
                            color: AppColors.grey600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
              ],
            ),

            const SizedBox(height: 18),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green, width: 2),
                        shape: BoxShape.circle,
                      ),
                    ),

                    Container(
                      width: 2,
                      height: 32,
                      color: Colors.green.shade300,
                    ),

                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pickup, style: const TextStyle(fontSize: 15)),

                      const SizedBox(height: 18),

                      Text(drop, style: const TextStyle(fontSize: 15)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
