import 'package:flutter/material.dart';

class RiderRatingCard extends StatelessWidget {
  final String riderName;
  final String employeeId;
  final String pickupPoint;
final String dropOffPoint;
  final int selectedRating;
  final int? driverRating;

  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmit;

  const RiderRatingCard({
    super.key,
    required this.riderName,
    required this.employeeId,
    required this.pickupPoint,
required this.dropOffPoint,
    required this.selectedRating,
    required this.onRatingChanged,
    required this.onSubmit,
    required this.driverRating,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [

    CircleAvatar(
      radius: 24,
      child: Text(
        riderName.isNotEmpty
            ? riderName[0].toUpperCase()
            : "?",
      ),
    ),

    const SizedBox(width: 12),

    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
  children: [

    Expanded(
      child: Text(
        riderName,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    if (driverRating != null)
      Row(
        children: List.generate(
          5,
          (index) => Icon(
            index < driverRating!
                ? Icons.star
                : Icons.star_border,
            color: index < driverRating!
                ? Colors.amber
                : Colors.grey,
            size: 26,
          ),
        ),
      ),
  ],
),

          const SizedBox(height: 0),

          Text(
            employeeId,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    ),
  ],
),
const SizedBox(height: 16),

Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [

    Column(
      children: const [
        Icon(
          Icons.radio_button_unchecked,
          size: 18,
          color: Colors.green,
        ),

        SizedBox(
          height: 26,
          child: VerticalDivider(
            thickness: 2,
            color: Colors.green,
          ),
        ),

        Icon(
          Icons.circle,
          size: 14,
          color: Colors.green,
        ),
      ],
    ),

    const SizedBox(width: 10),

    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            pickupPoint,
            maxLines: 1,
  overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15),
          ),

          const SizedBox(height: 8),

          Text(
            dropOffPoint,
            maxLines: 1,
  overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15),
          ),
        ],
      ),
    ),
  ],
),

if (driverRating == null) ...[

 const SizedBox(height: 18),

const Divider(
  height: 32,
  thickness: 1,
  color: Color(0xFFE0E0E0),
),

const Center(
  child: Text(
    "How was your experience?",
    style: TextStyle(
      fontSize: 16,
      color: Color.fromARGB(255, 112, 111, 111),
    ),
  ),
),

const SizedBox(height: 12),
  Row(
    mainAxisAlignment: MainAxisAlignment.center,
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
              : const Color.fromARGB(255, 190, 190, 190),
          size: 28,
        ),
      ),
    ),
  ),

  const SizedBox(height: 16),

  SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: selectedRating == 0
          ? null
          : onSubmit,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
         shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
      ),
      child: const Text("Submit Rating"),
    ),
  ),
],
          ],
        ),
      ),
    );
  }
}