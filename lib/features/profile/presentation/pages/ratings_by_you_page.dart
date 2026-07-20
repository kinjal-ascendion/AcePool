import 'package:flutter/material.dart';
import '../widgets/ride_card.dart';

class RatingsByYouPage extends StatelessWidget {
  const RatingsByYouPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Ratings by you",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RideCard(
            date: "16 June",
            time: "9:30 AM",
            pickup: "Green Park Apartments",
            drop: "Prestige Blue Chip, Koramangala",
            rating: 0,
            reviews: 0,
            trailing: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 16),
              label: const Text("Review your riders"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
            ),
          ),

          RideCard(
            date: "12 June",
            time: "9:30 AM",
            pickup: "Green Park Apartments",
            drop: "Prestige Blue Chip, Koramangala",
            rating: 5,
            reviews: 0,
            trailing: const Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 18),
                    Icon(Icons.star, color: Colors.amber, size: 18),
                    Icon(Icons.star, color: Colors.amber, size: 18),
                    Icon(Icons.star, color: Colors.amber, size: 18),
                    Icon(Icons.star, color: Colors.amber, size: 18),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  "2/3 reviews added",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          RideCard(
            date: "09 June",
            time: "10:30 AM",
            pickup: "Green Park Apartments",
            drop: "Prestige Blue Chip, Koramangala",
            rating: 4,
            reviews: 0,
            trailing: const Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 18),
                    Icon(Icons.star, color: Colors.amber, size: 18),
                    Icon(Icons.star, color: Colors.amber, size: 18),
                    Icon(Icons.star, color: Colors.amber, size: 18),
                    Icon(Icons.star_border, color: Colors.amber, size: 18),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  "1/3 reviews added",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          RideCard(
            date: "01 June",
            time: "10:30 AM",
            pickup: "Green Park Apartments",
            drop: "Prestige Blue Chip, Koramangala",
            rating: 0,
            reviews: 0,
            trailing: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 16),
              label: const Text("Review your riders"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
