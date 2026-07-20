import 'package:flutter/material.dart';
import 'package:acepool/core/theme/app_colors.dart';

class RatingSummaryCard extends StatelessWidget {
  const RatingSummaryCard({super.key});

  Widget _ratingBar(int stars, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: Text("$stars", style: const TextStyle(fontSize: 12)),
          ),
          const Icon(Icons.star, color: Colors.amber, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: count / 5,
                minHeight: 8,
                backgroundColor: Colors.grey.shade300,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text("$count", style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.grey200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
              child: Column(
                children: [
                  const Text(
                    "3.7",
                    style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 18),
                      Icon(Icons.star, color: Colors.amber, size: 18),
                      Icon(Icons.star, color: Colors.amber, size: 18),
                      Icon(Icons.star, color: Colors.amber, size: 18),
                      Icon(Icons.star_border, color: Colors.amber, size: 18),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "15 reviews",
                    style: TextStyle(color: AppColors.grey600),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 20),

            const Expanded(
              child: Column(
                children: [
                  _RatingRow(stars: 5, count: 4),
                  _RatingRow(stars: 4, count: 4),
                  _RatingRow(stars: 3, count: 0),
                  _RatingRow(stars: 2, count: 3),
                  _RatingRow(stars: 1, count: 0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  final int stars;
  final int count;

  const _RatingRow({required this.stars, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 18, child: Text("$stars")),
          const Icon(Icons.star, size: 14, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: count / 5,
                minHeight: 8,
                backgroundColor: Colors.grey.shade300,
                valueColor: const AlwaysStoppedAnimation(Colors.amber),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text("$count"),
        ],
      ),
    );
  }
}
