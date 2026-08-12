import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:acepool/features/profile/domain/entities/driver_ratable_ride.dart';
import 'package:acepool/features/profile/domain/entities/received_rating_ride.dart';
import 'package:acepool/features/profile/domain/entities/rider_ratable_ride.dart';
import 'package:acepool/features/profile/domain/entities/rider_review.dart';
import 'package:acepool/features/profile/domain/repositories/ratings_repository.dart';

class RatingsRepositoryImpl implements RatingsRepository {
  RatingsRepositoryImpl({FirebaseFirestore? db, FirebaseAuth? firebaseAuth})
      : _db = db ??
            FirebaseFirestore.instanceFor(
              app: Firebase.app(),
              databaseId: 'acepool',
            ),
        _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  @override
  Future<RatingsSummary> getRatingsReceivedFromDrivers() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const RatingsSummary(averageRating: 0, totalReviews: 0, ratingCounts: {}, rides: []);
    }

    var totalReviews = 0;
    var averageRating = 0.0;
    final ratingCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    final requestSnapshot = await _db
        .collection('ride_requests')
        .where('riderId', isEqualTo: uid)
        .where('status', isEqualTo: 'accepted')
        .get();

    final rides = <ReceivedRatingRide>[];

    for (final request in requestSnapshot.docs) {
      final requestData = request.data();
      if (requestData['driverRating'] == null) continue;

      final rideDoc = await _db.collection('rides').doc(requestData['rideId']).get();
      if (!rideDoc.exists) continue;

      final rideData = rideDoc.data()!;
      if (rideData['status'] != 'completed') continue;

      final driverRating = (requestData['driverRating'] as num).toDouble();
      totalReviews++;
      if (ratingCounts.containsKey(driverRating.toInt())) {
        ratingCounts[driverRating.toInt()] = (ratingCounts[driverRating.toInt()] ?? 0) + 1;
      }

      final rideTime = rideData['time'] as Map<String, dynamic>;

      rides.add(ReceivedRatingRide(
        rideId: requestData['rideId'],
        date: (rideData['date'] as Timestamp).toDate(),
        time: TimeOfDay(hour: rideTime['hour'], minute: rideTime['minute']),
        pickup: rideData['fromAddress'],
        drop: rideData['toAddress'],
        rating: driverRating,
        reviews: 1,
      ));
    }

    if (totalReviews > 0) {
      double sum = 0;
      ratingCounts.forEach((stars, count) => sum += stars * count);
      averageRating = sum / totalReviews;
    }

    return RatingsSummary(
      averageRating: averageRating,
      totalReviews: totalReviews,
      ratingCounts: ratingCounts,
      rides: rides,
    );
  }

  @override
  Future<RatingsSummary> getRatingsReceivedFromRiders() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const RatingsSummary(averageRating: 0, totalReviews: 0, ratingCounts: {}, rides: []);
    }

    var totalReviews = 0;
    var averageRating = 0.0;
    final ratingCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    final requestSnapshot = await _db
        .collection('ride_requests')
        .where('driverId', isEqualTo: uid)
        .where('status', isEqualTo: 'accepted')
        .get();

    final rides = <ReceivedRatingRide>[];

    for (final request in requestSnapshot.docs) {
      final requestData = request.data();

      // Ignore if the rider hasn't rated yet
      if (requestData['riderRating'] == null) continue;

      final rideDoc = await _db.collection('rides').doc(requestData['rideId']).get();
      if (!rideDoc.exists) continue;

      final rideData = rideDoc.data()!;
      if (rideData['status'] != 'completed') continue;

      // Get all requests for this ride
      final allRequests = await _db
          .collection('ride_requests')
          .where('rideId', isEqualTo: requestData['rideId'])
          .where('status', isEqualTo: 'accepted')
          .get();

      double totalRating = 0;
      int reviewCount = 0;

      for (final doc in allRequests.docs) {
        final data = doc.data();
        if (data['riderRating'] != null) {
          final rating = (data['riderRating'] as num).toDouble();
          totalRating += rating;
          reviewCount++;
          totalReviews++;
          if (ratingCounts.containsKey(rating.toInt())) {
            ratingCounts[rating.toInt()] = (ratingCounts[rating.toInt()] ?? 0) + 1;
          }
        }
      }
      final rideAverageRating = reviewCount == 0 ? 0.0 : totalRating / reviewCount;

      final rideTime = requestData['rideTime'] as Map<String, dynamic>;

      rides.add(ReceivedRatingRide(
        rideId: requestData['rideId'],
        date: (requestData['rideDate'] as Timestamp).toDate(),
        time: TimeOfDay(hour: rideTime['hour'], minute: rideTime['minute']),
        pickup: requestData['rideFrom'],
        drop: requestData['rideTo'],
        rating: rideAverageRating,
        reviews: reviewCount,
      ));
    }

    if (totalReviews > 0) {
      double sum = 0;
      ratingCounts.forEach((stars, count) => sum += stars * count);
      averageRating = sum / totalReviews;
    }

    return RatingsSummary(
      averageRating: averageRating,
      totalReviews: totalReviews,
      ratingCounts: ratingCounts,
      rides: rides,
    );
  }

  @override
  Future<List<RiderRatableRide>> getMyCompletedRidesToRate() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    final requestSnapshot = await _db
        .collection('ride_requests')
        .where('riderId', isEqualTo: uid)
        .where('status', isEqualTo: 'accepted')
        .get();

    final rides = <RiderRatableRide>[];

    for (final request in requestSnapshot.docs) {
      final requestData = request.data();

      final rideDoc = await _db.collection('rides').doc(requestData['rideId']).get();
      if (!rideDoc.exists) continue;

      final rideData = rideDoc.data()!;
      if (rideData['status'] != 'completed') continue;

      final rideTime = requestData['rideTime'] as Map<String, dynamic>;

      rides.add(RiderRatableRide(
        requestId: request.id,
        rideId: requestData['rideId'],
        driverId: requestData['driverId'],
        date: (requestData['rideDate'] as Timestamp).toDate(),
        time: TimeOfDay(hour: rideTime['hour'], minute: rideTime['minute']),
        pickup: requestData['rideFrom'],
        drop: requestData['rideTo'],
        riderRating: requestData['riderRating'],
      ));
    }

    return rides;
  }

  @override
  Future<void> submitRiderRating({required String requestId, required int rating}) async {
    await _db.collection("ride_requests").doc(requestId).update({
      "riderRating": rating,
      "riderRatedAt": FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<RiderReview>> getRidersToReview(String rideId) async {
    final snapshot = await _db
        .collection('ride_requests')
        .where('rideId', isEqualTo: rideId)
        .where('status', isEqualTo: 'accepted')
        .get();

    final riders = <RiderReview>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final userDoc = await _db.collection('users').doc(data['riderId']).get();
      final userData = userDoc.data();

      riders.add(RiderReview(
        requestId: doc.id,
        riderId: data['riderId'],
        riderName: data['riderName'],
        employeeId: userData?['employeeId'] ?? '',
        pickupPoint: data['pickupPoint'] ?? '',
        dropOffPoint: data['dropOffPoint'] ?? '',
        driverRating: data['driverRating'],
      ));
    }

    return riders;
  }

  @override
  Future<void> submitDriverRating({required String requestId, required int rating}) async {
    await _db.collection('ride_requests').doc(requestId).update({
      "driverRating": rating,
      "driverRatedAt": FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<DriverRatableRide>> getMyCompletedRidesAsDriver() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    final rideSnapshot = await _db
        .collection('rides')
        .where('uid', isEqualTo: uid)
        .where('status', isEqualTo: 'completed')
        .get();

    final rides = <DriverRatableRide>[];

    for (final ride in rideSnapshot.docs) {
      final rideData = ride.data();
      final rideTime = rideData['time'] as Map<String, dynamic>;

      final requestSnapshot = await _db
          .collection('ride_requests')
          .where('rideId', isEqualTo: ride.id)
          .where('status', isEqualTo: 'accepted')
          .get();

      final totalRiders = requestSnapshot.docs.length;
      final ratedRiders =
          requestSnapshot.docs.where((doc) => doc.data()['driverRating'] != null).length;

      rides.add(DriverRatableRide(
        requestId: '', // Not needed yet
        rideId: ride.id,
        driverId: uid,
        date: (rideData['date'] as Timestamp).toDate(),
        time: TimeOfDay(hour: rideTime['hour'], minute: rideTime['minute']),
        pickup: rideData['fromAddress'],
        drop: rideData['toAddress'],
        driverRating: ratedRiders > 0 ? 1 : null,
        ratedRiders: ratedRiders,
        totalRiders: totalRiders, // We'll calculate this later
      ));
    }

    return rides;
  }
}
