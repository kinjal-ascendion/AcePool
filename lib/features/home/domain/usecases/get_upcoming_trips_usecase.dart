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

      final fromLat = (data['fromLat'] as num?)?.toDouble();
      final fromLng = (data['fromLng'] as num?)?.toDouble();
      final toLat = (data['toLat'] as num?)?.toDouble();
      final toLng = (data['toLng'] as num?)?.toDouble();

      final fromLatLngMap = data['fromLatLng'] as Map<String, dynamic>?;
      final toLatLngMap = data['toLatLng'] as Map<String, dynamic>?;
      final fareMap = data['fare'] as Map<String, dynamic>?;

      return UpcomingTrip(
        id: doc.id,
        date: DateTime(date.year, date.month, date.day),
        time: TimeOfDay(
          hour: timeMap['hour'] as int,
          minute: timeMap['minute'] as int,
        ),
        fromAddress: data['fromAddress'] as String,
        toAddress: data['toAddress'] as String,
        fromLat: fromLat ?? (fromLatLngMap?['latitude'] as num?)?.toDouble(),
        fromLng: fromLng ?? (fromLatLngMap?['longitude'] as num?)?.toDouble(),
        toLat: toLat ?? (toLatLngMap?['latitude'] as num?)?.toDouble(),
        toLng: toLng ?? (toLatLngMap?['longitude'] as num?)?.toDouble(),
        seatsFilled: (data['seatsFilled'] as int?) ?? 0,
        seatsTotal: data['seatCount'] as int,
        farePerSeat: (fareMap?['farePerSeat'] as num?)?.toDouble(),
        note: data['note'] as String?,
        durationMinutes: (data['routeDurationMinutes'] as num?)?.toInt(),
      );
    }).toList();
  }
}
