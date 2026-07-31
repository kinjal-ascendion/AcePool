import 'package:flutter/material.dart';
import '../widgets/rating_summary_card.dart';
import '../widgets/ride_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';

class RatingsByDriversPage extends StatefulWidget {
  const RatingsByDriversPage({super.key});

  @override
  State<RatingsByDriversPage> createState() => _RatingsByDriversPageState();
}

class _RatingsByDriversPageState extends State<RatingsByDriversPage> {

  static final _db = FirebaseFirestore.instanceFor(
  app: Firebase.app(),
  databaseId: 'acepool',
);

late Future<List<ReceivedRatingRide>> _ridesFuture;
double _averageRating = 0;
int _totalReviews = 0;

Map<int, int> _ratingCounts = {
  5: 0,
  4: 0,
  3: 0,
  2: 0,
  1: 0,
};

@override
void initState() {
  super.initState();
  _ridesFuture = _fetchRatingsReceived();
}

Future<List<ReceivedRatingRide>> _fetchRatingsReceived() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return [];
  _totalReviews = 0;
_averageRating = 0;

_ratingCounts = {
  5: 0,
  4: 0,
  3: 0,
  2: 0,
  1: 0,
};

 final requestSnapshot = await _db
    .collection('ride_requests')
    .where('riderId', isEqualTo: uid)
    .where('status', isEqualTo: 'accepted')
    .get();
  List<ReceivedRatingRide> rides = [];

  for (final request in requestSnapshot.docs) {
  final requestData = request.data();

  if (requestData['driverRating'] == null) continue;

  final rideDoc = await _db
      .collection('rides')
      .doc(requestData['rideId'])
      .get();

  if (!rideDoc.exists) continue;

  final rideData = rideDoc.data()!;

  if (rideData['status'] != 'completed') continue;

  final allRequests = await _db
      .collection('ride_requests')
      .where('rideId', isEqualTo: requestData['rideId'])
      .where('status', isEqualTo: 'accepted')
      .get();

 final driverRating =
    (requestData['driverRating'] as num).toDouble();

_totalReviews++;

if (_ratingCounts.containsKey(driverRating.toInt())) {
  _ratingCounts[driverRating.toInt()] =
      (_ratingCounts[driverRating.toInt()] ?? 0) + 1;
}

  final rideTime = rideData['time'] as Map<String, dynamic>;

  rides.add(
   ReceivedRatingRide(
  rideId: requestData['rideId'],
  date: (rideData['date'] as Timestamp).toDate(),
  time: TimeOfDay(
    hour: rideTime['hour'],
    minute: rideTime['minute'],
  ),
  pickup: rideData['fromAddress'],
  drop: rideData['toAddress'],
  rating: driverRating,
reviews: 1,
),
  );
}
if (_totalReviews > 0) {
  double sum = 0;

  _ratingCounts.forEach((stars, count) {
    sum += stars * count;
  });

  _averageRating = sum / _totalReviews;
}

return rides;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Ride statistics",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
         body: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [

    const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Text(
        "RATINGS BY DRIVERS",
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.2,
        ),
      ),
    ),

    Expanded(

     child: FutureBuilder<List<ReceivedRatingRide>>(
  future: _ridesFuture,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (snapshot.hasError) {
      return Center(
        child: Text(snapshot.error.toString()),
      );
    }

    final rides = snapshot.data ?? [];

    if (rides.isEmpty) {
      return const Center(
        child: Text("No ratings received yet"),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        RatingSummaryCard(
  averageRating: _averageRating,
  totalReviews: _totalReviews,
  ratingCounts: _ratingCounts,
),

        const SizedBox(height: 12),

        ...rides.map(
          (ride) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: RideCard(
             date: DateFormat('MMMM d, yyyy').format(ride.date),
              time: ride.time.format(context),
              pickup: ride.pickup,
              drop: ride.drop,
              rating: ride.rating,
              reviews: ride.reviews,
              showReviews: true,
              showReviewCount: false,
            ),
          ),
        ),
      ],
    );
  },
),
    ),
  ],
         ),
  
    );
  }
}
class ReceivedRatingRide {
  final String rideId;
  final DateTime date;
  final TimeOfDay time;
  final String pickup;
  final String drop;
  final double rating;
  final int reviews;

  ReceivedRatingRide({
    required this.rideId,
    required this.date,
    required this.time,
    required this.pickup,
    required this.drop,
    required this.rating,
    required this.reviews,
  });
}
