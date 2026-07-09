import 'package:acepool/features/home/domain/entities/upcoming_trip.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GetUpcomingTripsUseCase {
  final FirebaseFirestore _db;

  GetUpcomingTripsUseCase({FirebaseFirestore? db})
    : _db =
          db ??
          FirebaseFirestore.instanceFor(
            app: Firebase.app(),
            databaseId: 'acepool',
          );

  Future<List<UpcomingTrip>> call() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);

    final snapshot = await _db
        .collection('rides')
        .where('uid', isEqualTo: uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
        .orderBy('date')
        .limit(3)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final date = (data['date'] as Timestamp).toDate();
      final timeMap = data['time'] as Map<String, dynamic>;

      LatLng? fromLatLng;
      if (data['fromLatLng'] != null) {
        final map = data['fromLatLng'] as Map<String, dynamic>;
        fromLatLng = LatLng(map['latitude'] as double, map['longitude'] as double);
      }

      LatLng? toLatLng;
      if (data['toLatLng'] != null) {
        final map = data['toLatLng'] as Map<String, dynamic>;
        toLatLng = LatLng(map['latitude'] as double, map['longitude'] as double);
      }

      return UpcomingTrip(
        id: doc.id,
        date: DateTime(date.year, date.month, date.day),
        time: TimeOfDay(
          hour: timeMap['hour'] as int,
          minute: timeMap['minute'] as int,
        ),
        fromAddress: data['fromAddress'] as String,
        toAddress: data['toAddress'] as String,
        fromLatLng: fromLatLng,
        toLatLng: toLatLng,
        seatsFilled: (data['seatsFilled'] as int?) ?? 0,
        seatsTotal: data['seatCount'] as int,
      );
    }).toList();
  }
}
