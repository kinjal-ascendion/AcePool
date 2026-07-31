import 'package:flutter/material.dart';
import 'package:acepool/core/theme/app_colors.dart';

class RideCard extends StatelessWidget {
  final String date;
  final String time;
  final String pickup;
  final String drop;
  final double rating;
  final int reviews;
  final bool showReviews;
  final Widget? trailing;
  final VoidCallback? onReview;
  final bool showReviewCount;

  const RideCard({
    super.key,
    required this.date,
    required this.time,
    required this.pickup,
    required this.drop,
    required this.rating,
    required this.reviews,
    this.showReviews = true,
    this.trailing,
    this.onReview,
    this.showReviewCount = true,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.grey300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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

                      Text(
  time,
 style: const TextStyle(
    color: Colors.black,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  ),
),
                    ],
                  ),
                ),

                trailing ??
                   Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
  children: List.generate(
    5,
    (index) => Icon(
      index < rating.round()
          ? Icons.star
          : Icons.star_border,
      color: index < rating.round()
          ? Colors.amber
          : const Color.fromARGB(255, 191, 191, 191),
      size: 22,
    ),
  ),
),
                        if (showReviews && reviews > 0) ...[
  const SizedBox(height: 4),
  if (showReviewCount)
  Text(
    "$reviews review${reviews == 1 ? '' : 's'}",
    style: TextStyle(
      color: AppColors.grey600,
      fontSize: 12,
    ),
  ),
],
                      ],
                    ),
              ],
            ),

            const SizedBox(height: 12),

           Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
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
                      height: 26,
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
    ),

                const SizedBox(width: 12),

                Expanded(
  child: Padding(
    padding: const EdgeInsets.only(top: 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
  pickup,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: TextStyle(
    fontSize: 15,
    color: AppColors.grey600,
  ),
),

                      const SizedBox(height: 10),

Text(
  drop,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: TextStyle(
    fontSize: 15,
    color: AppColors.grey600,
  ),
),
                    ],
                  ),
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

