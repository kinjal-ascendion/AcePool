import 'package:flutter/material.dart';

class RatingPanel extends StatelessWidget {
  final int selectedRating;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmit;

  const RatingPanel({
    super.key,
    required this.selectedRating,
    required this.onRatingChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(top: 12, bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),      
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "RATE YOUR RIDE",
              style: TextStyle(
                //fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 20),

            const Center(
              child: Text(
                "How was your experience?",
                style: TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 12),

            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (index) => IconButton(
                    onPressed: () {
                      onRatingChanged(index + 1);
                    },
                   icon: Icon(
  index < selectedRating
      ? Icons.star
      : Icons.star_border,
  color: index < selectedRating
      ? Colors.amber
      : const Color.fromARGB(255, 190, 189, 189),
  size: 32,
),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: selectedRating == 0 ? null : onSubmit,
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      disabledBackgroundColor: Colors.grey.shade400,
      disabledForegroundColor: Colors.white70,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    child: const Text(
      "Submit Rating",
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
),
          ],
        ),
      ),
    );
  }
}