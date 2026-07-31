import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../widgets/rider_rating_card.dart';

class ReviewRidersPage extends StatefulWidget {
  final String rideId;

  const ReviewRidersPage({
    super.key,
    required this.rideId,
  });

  @override
  State<ReviewRidersPage> createState() => _ReviewRidersPageState();
}

class _ReviewRidersPageState extends State<ReviewRidersPage> {
  static final _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'acepool',
  );

  late Future<List<RiderReview>> _ridersFuture;

  @override
  void initState() {
    super.initState();

    _ridersFuture = _fetchRiders();
  }

final Map<String, int> _selectedRatings = {};

Future<List<RiderReview>> _fetchRiders() async {
  final snapshot = await _db
      .collection('ride_requests')
      .where('rideId', isEqualTo: widget.rideId)
      .where('status', isEqualTo: 'accepted')
      .get();

  final List<RiderReview> riders = [];

for (final doc in snapshot.docs) {
  final data = doc.data();

  final userDoc = await _db
      .collection('users')
      .doc(data['riderId'])
      .get();

  final userData = userDoc.data();

  riders.add(
    RiderReview(
      requestId: doc.id,
      riderId: data['riderId'],
      riderName: data['riderName'],
      employeeId: userData?['employeeId'] ?? '',
      pickupPoint: data['pickupPoint'] ?? '',
      dropOffPoint: data['dropOffPoint'] ?? '',
      driverRating: data['driverRating'],
    ),
  );
}

return riders;
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text("Review Riders"),
    ),
    body: FutureBuilder<List<RiderReview>>(
      future: _ridersFuture,
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text("No riders found"),
          );
        }

        final riders = snapshot.data!;

        return ListView.builder(
          itemCount: riders.length,
          itemBuilder: (context, index) {

            final rider = riders[index];

   return RiderRatingCard(
  riderName: rider.riderName,
  employeeId: rider.employeeId,
   pickupPoint: rider.pickupPoint,
  dropOffPoint: rider.dropOffPoint,
  driverRating: rider.driverRating,
  selectedRating:
      _selectedRatings[rider.requestId] ?? 0,

  onRatingChanged: (rating) {
    setState(() {
      _selectedRatings[rider.requestId] = rating;
    });
  },

  onSubmit: () async {
  await _db
      .collection('ride_requests')
      .doc(rider.requestId)
      .update({
    "driverRating": _selectedRatings[rider.requestId],
    "driverRatedAt": FieldValue.serverTimestamp(),
  });

  if (!mounted) return;
  setState(() {
    rider.driverRating = _selectedRatings[rider.requestId];
  });

},
);
          },
        );
      },
    ),
  );
}

}
class RiderReview {

  final String requestId;
  final String riderId;
final String pickupPoint;
final String dropOffPoint;
  final String riderName;
  final String employeeId;

   int? driverRating;

  RiderReview({
    required this.requestId,
    required this.riderId,
    required this.riderName,
    required this.employeeId,
    required this.driverRating,
    required this.dropOffPoint,
    required this.pickupPoint,
  });
}