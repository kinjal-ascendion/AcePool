import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:acepool/features/profile/domain/repositories/ride_history_repository.dart';

class RideHistoryRepositoryImpl implements RideHistoryRepository {
  RideHistoryRepositoryImpl({FirebaseFirestore? db, FirebaseAuth? firebaseAuth})
      : _db = db ??
            FirebaseFirestore.instanceFor(
              app: Firebase.app(),
              databaseId: 'acepool',
            ),
        _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  @override
  Future<List<Map<String, dynamic>>> getHistory() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    try {
      // 1. Fetch rides where user was the DRIVER (creator)
      final driverSnap = await _db
          .collection('rides')
          .where('uid', isEqualTo: uid)
          .where('status', whereIn: ['completed', 'cancelled'])
          .get();

      final driverRides = driverSnap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

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
}
