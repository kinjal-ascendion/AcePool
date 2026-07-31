import 'package:flutter/material.dart';
import '../widgets/ride_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'review_riders_page.dart';

class ReviewYourRidersPage extends StatefulWidget {
  const ReviewYourRidersPage({super.key});

  @override
  State<ReviewYourRidersPage> createState() =>
      _ReviewYourRidersPageState();
}

class _ReviewYourRidersPageState
    extends State<ReviewYourRidersPage> {

static final _db = FirebaseFirestore.instanceFor(
  app: Firebase.app(),
  databaseId: 'acepool',
);

late Future<List<RatedRide>> _ridesFuture;

@override
void initState() {
  super.initState();
  _ridesFuture = _fetchCompletedRides();
}
Future<List<RatedRide>> _fetchCompletedRides() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return [];

  final rideSnapshot = await _db
      .collection('rides')
      .where('uid', isEqualTo: uid)
      .where('status', isEqualTo: 'completed')
      .get();

  List<RatedRide> rides = [];

  for (final ride in rideSnapshot.docs) {
    final rideData = ride.data();

    final rideTime = rideData['time'] as Map<String, dynamic>;
    final requestSnapshot = await _db
    .collection('ride_requests')
    .where('rideId', isEqualTo: ride.id)
    .where('status', isEqualTo: 'accepted')
    .get();

final totalRiders = requestSnapshot.docs.length;

final ratedRiders = requestSnapshot.docs
    .where((doc) => doc.data()['driverRating'] != null)
    .length;

    rides.add(
      RatedRide(
        requestId: '', // Not needed yet
        rideId: ride.id,
        driverId: uid,

        date: (rideData['date'] as Timestamp).toDate(),

        time: TimeOfDay(
          hour: rideTime['hour'],
          minute: rideTime['minute'],
        ),

        pickup: rideData['fromAddress'],
        drop: rideData['toAddress'],

       driverRating: ratedRiders > 0 ? 1 : null,
       ratedRiders: ratedRiders,
       totalRiders: totalRiders,// We'll calculate this later
      ),
    );
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
        "RATINGS BY YOU",
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.2,
        ),
      ),
    ),

    Expanded(
      child: FutureBuilder<List<RatedRide>>(
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
        child: Text("No completed rides found"),
      );
    }

       return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rides.length,
      itemBuilder: (context, index) {
        final ride = rides[index];

       return Column(
  children: [
    RideCard(
      date: DateFormat('MMMM d, yyyy').format(ride.date),
      time: ride.time.format(context),
      pickup: ride.pickup,
      drop: ride.drop,
      rating: (ride.driverRating ?? 0).toDouble(),
      reviews: 0,
      showReviews: false,
      trailing: ride.ratedRiders == 0
    ? ElevatedButton.icon(
        onPressed: () async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ReviewRidersPage(
        rideId: ride.rideId,
      ),
    ),
  );

  setState(() {
    _ridesFuture = _fetchCompletedRides();
  });
},
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        icon: const Icon(
          Icons.add,
          size: 14,
        ),
        label: const Text(
          "Review your Riders",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      )
    : InkWell(
       onTap: () async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ReviewRidersPage(
        rideId: ride.rideId,
      ),
    ),
  );

  setState(() {
    _ridesFuture = _fetchCompletedRides();
  });
},
        child: Text(
          "${ride.ratedRiders}/${ride.totalRiders} reviews added",
          style: const TextStyle(
            fontSize:11,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
            //decoration: TextDecoration.underline,
          ),
        ),
      ),
    ),

    const SizedBox(height: 16),
  ],
);
      },
    );
  },
),
    ),
  ],
),
    );
  }
}
class RatedRide {
  final String requestId;
  final String rideId;
  final String driverId;
  final DateTime date;
  final TimeOfDay time;
  final String pickup;
  final String drop;
  final int? driverRating;
  final int ratedRiders;
  final int totalRiders;

  RatedRide({
    required this.requestId,
    required this.rideId,
    required this.driverId,
    required this.date,
    required this.time,
    required this.pickup,
    required this.drop,
    required this.driverRating,
    required this.ratedRiders,
    required this.totalRiders,
  });
}
