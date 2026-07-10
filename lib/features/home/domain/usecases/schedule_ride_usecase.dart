import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ScheduleRideUseCase {
  final FirebaseFirestore _db;

  ScheduleRideUseCase({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'acepool');

  Future<void> call({
    required String rideMode,
    required String vehicleType,
    required String fromAddress,
    required String toAddress,
    double? fromLat,
    double? fromLng,
    double? toLat,
    double? toLng,
    required DateTime date,
    required TimeOfDay time,
    required int seatCount,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    await _db.collection('rides').add({
      'uid': uid,
      'rideMode': rideMode,
      'vehicleType': vehicleType,
      'fromAddress': fromAddress,
      'toAddress': toAddress,
      'fromLat': fromLat,
      'fromLng': fromLng,
      'toLat': toLat,
      'toLng': toLng,
      'date': Timestamp.fromDate(date),
      'time': {'hour': time.hour, 'minute': time.minute},
      'seatCount': seatCount,
      'seatsFilled': 0,
      'createdAt': FieldValue.serverTimestamp(),
    }).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception('Request timed out. Check your connection.'),
    );
  }
}
