import 'package:flutter/material.dart';
import '../widgets/ride_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import '../widgets/rating_panel.dart';

class RatingsByYouPage extends StatefulWidget {
  const RatingsByYouPage({super.key});

  @override
  State<RatingsByYouPage> createState() => _RatingsByYouPageState();
}

class _RatingsByYouPageState extends State<RatingsByYouPage> {

static final _db = FirebaseFirestore.instanceFor(
  app: Firebase.app(),
  databaseId: 'acepool',
);

late Future<List<RatedRide>> _ridesFuture;

String? _expandedRideId;
int _selectedRating = 0;

@override
void initState() {
  super.initState();
  _ridesFuture = _fetchCompletedRides();
}

Future<List<RatedRide>> _fetchCompletedRides() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return [];

  final requestSnapshot = await _db
      .collection('ride_requests')
      .where('riderId', isEqualTo: uid)
      .where('status', isEqualTo: 'accepted')
      .get();

  List<RatedRide> rides = [];

  for (final request in requestSnapshot.docs) {
    final requestData = request.data();

    final rideDoc = await _db
        .collection('rides')
        .doc(requestData['rideId'])
        .get();

    if (!rideDoc.exists) continue;

    final rideData = rideDoc.data()!;

    if (rideData['status'] != 'completed') continue;

    final rideTime = requestData['rideTime'] as Map<String, dynamic>;

rides.add(
  RatedRide(
    requestId: request.id,
    rideId: requestData['rideId'],
    driverId: requestData['driverId'],
    date: (requestData['rideDate'] as Timestamp).toDate(),
    time: TimeOfDay(
      hour: rideTime['hour'],
      minute: rideTime['minute'],
    ),
    pickup: requestData['rideFrom'],
    
    drop: requestData['rideTo'],
    riderRating: requestData['riderRating'],
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
      rating: (ride.riderRating ?? 0).toDouble(),
      reviews: 0,
      showReviews: false,
      trailing: ride.riderRating == null
          ? ElevatedButton.icon(
    onPressed: () {
      setState(() {
        if (_expandedRideId == ride.requestId) {
          _expandedRideId = null;
        } else {
          _expandedRideId = ride.requestId;
          _selectedRating = 0;
        }
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
      "Review your Driver",
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  )
          : null,
    ),

    if (_expandedRideId == ride.requestId)
      RatingPanel(
        selectedRating: _selectedRating,
        onRatingChanged: (rating) {
          setState(() {
            _selectedRating = rating;
          });
        },
       onSubmit: () async {
  try {
    await _db
        .collection("ride_requests")
        .doc(ride.requestId)
        .update({
      "riderRating": _selectedRating,
      "riderRatedAt": FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    final rides = await _ridesFuture;

final index = rides.indexWhere(
  (r) => r.requestId == ride.requestId,
);

if (index != -1) {
  rides[index] = RatedRide(
    requestId: rides[index].requestId,
    rideId: rides[index].rideId,
    driverId: rides[index].driverId,
    date: rides[index].date,
    time: rides[index].time,
    pickup: rides[index].pickup,
    drop: rides[index].drop,
    riderRating: _selectedRating,
  );
}

setState(() {
  _expandedRideId = null;
  _selectedRating = 0;
  _ridesFuture = Future.value(rides);
});

  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString()),
      ),
    );
  }
},
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
  final int? riderRating;

  RatedRide({
    required this.requestId,
    required this.rideId,
    required this.driverId,
    required this.date,
    required this.time,
    required this.pickup,
    required this.drop,
    required this.riderRating,
  });
}
