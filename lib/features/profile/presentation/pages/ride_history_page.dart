import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/core/utils/date_time_formatter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'ride_history_detail_page.dart';

class RideHistoryPage extends StatefulWidget {
  const RideHistoryPage({super.key});

  @override
  State<RideHistoryPage> createState() => _RideHistoryPageState();
}

class _RideHistoryPageState extends State<RideHistoryPage> {
  static final _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'acepool',
  );

  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _fetchHistory();
  }

  Future<List<Map<String, dynamic>>> _fetchHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    try {
      // 1. Fetch rides where user was the DRIVER (creator)
      final driverSnap = await _db
          .collection('rides')
          .where('uid', isEqualTo: uid)
          .where('status', whereIn: ['completed', 'cancelled'])
          .get();
      
      final driverRides = driverSnap.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      // 2. Fetch rides where user was a RIDER
      final riderSnap = await _db
          .collection('ride_requests')
          .where('riderId', isEqualTo: uid)
          .where('status', whereIn: ['completed', 'cancelled'])
          .get();

      final riderRides = <Map<String, dynamic>>[];
      for (var doc in riderSnap.docs) {
        final requestData = doc.data();
        final rideId = requestData['rideId'] as String;
        
        // Fetch full ride details to get price, vehicle info etc.
        final rideDoc = await _db.collection('rides').doc(rideId).get();
        if (rideDoc.exists) {
          final rideData = rideDoc.data()!;
          riderRides.add({
            'id': rideId,
            ...rideData,
            'status': requestData['status'],
            'rideMode': 'find', // Force 'find' mode for history display
            'fromAddress': requestData['pickupPoint'] ?? rideData['fromAddress'],
            'toAddress': requestData['dropOffPoint'] ?? rideData['toAddress'],
          });
        }
      }

      // Combine and sort by date descending
      final allRides = [...driverRides, ...riderRides];
      allRides.sort((a, b) {
        final timestampA = a['date'] as Timestamp?;
        final timestampB = b['date'] as Timestamp?;
        if (timestampA == null || timestampB == null) return 0;
        return timestampB.compareTo(timestampA);
      });

      return allRides;
    } catch (e) {
      debugPrint('Error fetching ride history: $e');
      return [];
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupRides(List<Map<String, dynamic>> rides) {
    final Map<String, List<Map<String, dynamic>>> groups = {
      'TODAY': [],
      'YESTERDAY': [],
      'THIS MONTH': [],
      'OLDER RIDES': [],
    };

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final firstOfThisMonth = DateTime(now.year, now.month, 1);

    for (var ride in rides) {
      final timestamp = ride['date'] as Timestamp?;
      if (timestamp == null) continue;
      
      final rideDate = timestamp.toDate();
      final rideDay = DateTime(rideDate.year, rideDate.month, rideDate.day);

      if (rideDay.isAtSameMomentAs(today)) {
        groups['TODAY']!.add(ride);
      } else if (rideDay.isAtSameMomentAs(yesterday)) {
        groups['YESTERDAY']!.add(ride);
      } else if (rideDay.isAfter(firstOfThisMonth.subtract(const Duration(seconds: 1)))) {
        groups['THIS MONTH']!.add(ride);
      } else {
        groups['OLDER RIDES']!.add(ride);
      }
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ride History',
          style: TextStyle(
            color: AppColors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final rides = snapshot.data ?? [];
          if (rides.isEmpty) {
            return const Center(
              child: Text('No completed rides found.'),
            );
          }

          final groups = _groupRides(rides);
          final hasData = groups.values.any((list) => list.isNotEmpty);

          if (!hasData) {
            return const Center(
              child: Text('No completed rides found.'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._buildGroup('TODAY', groups['TODAY']!),
                  ..._buildGroup('YESTERDAY', groups['YESTERDAY']!),
                  ..._buildGroup('THIS MONTH', groups['THIS MONTH']!),
                  ..._buildGroup('OLDER RIDES', groups['OLDER RIDES']!),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'View All',
                        style: TextStyle(
                          color: AppColors.grey500,
                          decoration: TextDecoration.underline,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildGroup(String title, List<Map<String, dynamic>> rides) {
    if (rides.isEmpty) return [];
    
    return [
      _buildSectionHeader(title),
      ...rides.map((ride) {
        final data = ride;
        final isDriver = data['rideMode'] == 'offer';
        final vehicleType = data['vehicleType'] as String? ?? 'car';
        final toAddress = data['toAddress'] as String? ?? 'Unknown Destination';
        
        final timestamp = data['date'] as Timestamp;
        final rideDate = timestamp.toDate();
        final timeMap = data['time'] as Map<String, dynamic>?;
        final time = TimeOfDay(
          hour: timeMap?['hour'] as int? ?? 0,
          minute: timeMap?['minute'] as int? ?? 0,
        );

        final dateTimeStr = '${DateTimeFormatter.monthDayYear(rideDate)} ; ${DateTimeFormatter.time12h(time)}';
        
        final fareMap = data['fare'] as Map<String, dynamic>?;
        final price = isDriver 
            ? (fareMap?['driverEarnings'] ?? fareMap?['totalCost'] ?? 0.0)
            : (fareMap?['farePerSeat'] ?? 0.0);
            
        final status = data['status'] as String? ?? 'completed';
        final statusLabel = status == 'cancelled' ? 'Cancelled' : 'Completed';
        final priceStatus = '₹ $price ; $statusLabel';
        
        final relativeTime = _getRelativeTimeLabel(rideDate);

        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RideHistoryDetailPage(rideData: ride),
            ),
          ),
          child: _buildRideItem(
            icon: vehicleType.toLowerCase() == 'bike' 
                ? Icons.directions_bike_outlined 
                : Icons.directions_car_filled_outlined,
            title: toAddress,
            dateTime: dateTimeStr,
            priceStatus: priceStatus,
            relativeTime: relativeTime,
          ),
        );
      }).toList(),
    ];
  }

  String _getRelativeTimeLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rideDay = DateTime(date.year, date.month, date.day);
    final difference = today.difference(rideDay).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return DateTimeFormatter.monthDayYear(date);
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF4C515B),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Divider(color: const Color(0xFFE0E0E0), height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  Widget _buildRideItem({
    required IconData icon,
    required String title,
    required String dateTime,
    required String priceStatus,
    required String relativeTime,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF1E1E1E), size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF1E1E1E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      relativeTime,
                      style: const TextStyle(
                        color: Color(0xFF616874),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  dateTime,
                  style: const TextStyle(
                    color: Color(0xFF616874),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      priceStatus,
                      style: const TextStyle(
                        color: Color(0xFF616874),
                        fontSize: 16,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF1E1E1E),
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
