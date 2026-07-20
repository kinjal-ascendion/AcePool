import 'package:flutter/material.dart';
import '../widgets/rating_summary_card.dart';
import '../widgets/ride_card.dart';

class RatingsByRidersPage extends StatelessWidget {
  const RatingsByRidersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Ratings by riders",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          RatingSummaryCard(),

          SizedBox(height: 12),

          RideCard(
            date: "12 June",
            time: "10:00 AM",
            pickup: "Ascendion Hyderabad",
            drop: "Gachibowli",
            rating: 4,
            reviews: 4,
          ),

          RideCard(
            date: "18 June",
            time: "8:45 AM",
            pickup: "Madhapur",
            drop: "Ascendion Hyderabad",
            rating: 5,
            reviews: 5,
          ),

          RideCard(
            date: "22 June",
            time: "6:30 PM",
            pickup: "Ascendion Hyderabad",
            drop: "Kondapur",
            rating: 3,
            reviews: 3,
          ),
        ],
      ),
    );
  }
}
