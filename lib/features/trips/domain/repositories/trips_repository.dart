import 'package:acepool/features/home/domain/entities/upcoming_trip.dart';
import 'package:acepool/features/trips/domain/entities/available_ride.dart';
import 'package:acepool/features/trips/domain/entities/driver_profile_stats.dart';
import 'package:acepool/features/trips/domain/entities/requested_ride.dart';

abstract class TripsRepository {
  /// The current user's own rides with the given `rideMode` ('offer'/'find'),
  /// excluding completed/cancelled ones.
  Future<List<UpcomingTrip>> getTrips(String rideMode);

  /// Driver-offered rides matching [fromAddress]/[toAddress] (the rider's
  /// current Home find-ride form). Returns empty if either is blank.
  Future<List<AvailableRide>> getAvailableRides({
    String? fromAddress,
    String? toAddress,
    double? fromLat,
    double? fromLng,
    double? toLat,
    double? toLng,
  });

  /// The current user's own ride_requests, with match info recomputed
  /// against the given Home find-ride form values.
  Future<List<RequestedRide>> getRideRequests({
    String? homeFromAddress,
    String? homeToAddress,
    double? homeFromLat,
    double? homeFromLng,
    double? homeToLat,
    double? homeToLng,
  });

  /// Cancels [tripId] (a driver's offered ride) and cascades cancellation
  /// to every ride_request against it.
  Future<void> cancelOfferedRide(String tripId, {required String reason});

  Future<void> updateTripStatus(String tripId, String status);

  /// Creates a ride_request for [ride] and increments its seatsFilled.
  /// Returns the rider's display name for use in a follow-up chat message.
  Future<String> requestAvailableRide({
    required AvailableRide ride,
    String message = '',
    double? negotiatedPrice,
  });

  /// Cancels the current user's own ride_request [requestId] (on ride
  /// [rideId]) and decrements the ride's seatsFilled.
  Future<void> cancelRideRequest({
    required String requestId,
    required String rideId,
    required String reason,
  });

  Future<DriverProfileStats> getDriverProfileStats(String driverId);
}
