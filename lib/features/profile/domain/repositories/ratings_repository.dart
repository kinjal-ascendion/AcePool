import 'package:acepool/features/profile/domain/entities/driver_ratable_ride.dart';
import 'package:acepool/features/profile/domain/entities/received_rating_ride.dart';
import 'package:acepool/features/profile/domain/entities/rider_ratable_ride.dart';
import 'package:acepool/features/profile/domain/entities/rider_review.dart';

abstract class RatingsRepository {
  /// Ratings the current user (as rider) received from drivers.
  Future<RatingsSummary> getRatingsReceivedFromDrivers();

  /// Ratings the current user (as driver) received from riders.
  Future<RatingsSummary> getRatingsReceivedFromRiders();

  /// The current user's (rider's) completed rides available to rate.
  Future<List<RiderRatableRide>> getMyCompletedRidesToRate();

  Future<void> submitRiderRating({required String requestId, required int rating});

  /// Riders on [rideId] the current user (driver) can rate.
  Future<List<RiderReview>> getRidersToReview(String rideId);

  Future<void> submitDriverRating({required String requestId, required int rating});

  /// The current user's (driver's) completed offered rides, with review
  /// progress.
  Future<List<DriverRatableRide>> getMyCompletedRidesAsDriver();
}
