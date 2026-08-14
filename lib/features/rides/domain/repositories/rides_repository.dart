import 'package:flutter/material.dart';

import 'package:acepool/features/rides/domain/entities/ride_match.dart';
import 'package:acepool/features/rides/domain/entities/ride_rider.dart';
import 'package:acepool/features/rides/domain/entities/rider_journey.dart';

abstract class RidesRepository {
  Future<List<RideMatch>> findMatchingRides({
    required String fromAddress,
    required String toAddress,
    double? fromLat,
    double? fromLng,
    double? toLat,
    double? toLng,
    required DateTime date,
    required TimeOfDay time,
    required String vehicleType,
  });

  /// Creates a ride_request for [ride] on behalf of the current rider and
  /// increments the ride's seatsFilled count. Returns the rider's display
  /// name (as resolved from their profile) for use in a follow-up chat
  /// message.
  Future<String> requestRide({
    required RideMatch ride,
    required String riderFromAddress,
    double? riderFromLat,
    double? riderFromLng,
    required String riderToAddress,
    double? riderToLat,
    double? riderToLng,
    required TimeOfDay riderTime,
    String message = '',
    double? negotiatedPrice,
  });

  /// Riders whose request on [rideId] has [status] (default `accepted`),
  /// optionally scoped to requests owned by [driverId].
  Future<List<RideRider>> getAcceptedRiders({
    required String rideId,
    String? driverId,
    String status = 'accepted',
  });

  /// Same as [getAcceptedRiders] but scoped to the currently signed-in
  /// driver (matches `drives_detail_page`'s original `driverId == uid`
  /// filter); returns empty if no user is signed in.
  Future<List<RideRider>> getRidersForCurrentDriver({
    required String rideId,
    String status = 'accepted',
  });

  /// Accepted riders on [rideId] excluding the current user, for the ride
  /// details screen's "other riders" list (distinct query shape/defaults
  /// from [getAcceptedRiders] — kept separate to preserve exact behavior).
  Future<List<RideRider>> getOtherRiders(String rideId);

  /// Same effect as [requestRide] but matching `ride_details_page`'s exact
  /// (distinct) defaulting/endpoint-match logic when rider coordinates are
  /// optional and pickup time falls back to the ride's own time rather than
  /// a separately-supplied rider search time.
  Future<String> requestRideFromDetails({
    required RideMatch ride,
    String? riderFromAddress,
    double? riderFromLat,
    double? riderFromLng,
    String? riderToAddress,
    double? riderToLat,
    double? riderToLng,
    String message = '',
    double? negotiatedPrice,
  });

  /// Rejects a rider's request and decrements the ride's seatsFilled count.
  Future<void> cancelRiderRequest({
    required String requestId,
    required String rideId,
  });

  Future<void> updateRideStatus(String rideId, String status);

  /// Cancels the ride and cascades cancellation to every pending/accepted
  /// ride_request against it.
  Future<void> cancelRide(String rideId, {required String reason});

  /// Corrects `seatsFilled` on [rideId] to match [acceptedCount] if it has
  /// drifted.
  Future<void> reconcileSeatsFilled(String rideId, int acceptedCount);

  Future<void> respondToNegotiation({
    required String requestId,
    required String status, // 'accepted' or 'declined'
  });

  Future<bool> isRideOwnedByCurrentUser(String rideId);

  /// Live updates to a ride's driver-authored note.
  Stream<String?> watchRideNote(String rideId);

  Future<void> updateRideNote(String rideId, String note);

  Future<RiderJourney> getRiderJourney({
    required RideMatch ride,
    String? riderFromAddress,
    double? riderFromLat,
    double? riderFromLng,
    String? riderToAddress,
    double? riderToLat,
    double? riderToLng,
  });

  Future<void> completeRide({
    required String rideId,
    required String paymentMethod,
  });

  /// Resolves the current user's display name and sends [text] to
  /// [driverId] in their 1:1 chat (creating/reusing the deterministic
  /// `uid_driverId` chat id), mirroring `ride_details_page`'s `_sendMessage`.
  Future<void> sendRideChatMessage({
    required String driverId,
    required String driverName,
    required String text,
  });

  Future<void> ensureGroupChat({
    required String rideId,
    required String groupTitle,
    required DateTime rideDate,
    required List<String> participantIds,
    required Map<String, String> participantNames,
    required Map<String, String> participantPhotos,
  });
}
