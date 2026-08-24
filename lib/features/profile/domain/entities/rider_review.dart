/// A rider on one of the driver's rides, for the "review your riders" flow.
class RiderReview {
  const RiderReview({
    required this.requestId,
    required this.riderId,
    required this.riderName,
    required this.employeeId,
    required this.pickupPoint,
    required this.dropOffPoint,
    required this.driverRating,
    this.riderPhotoUrl,
    this.vehicleInfo,
  });

  final String requestId;
  final String riderId;
  final String riderName;
  final String employeeId;
  final String pickupPoint;
  final String dropOffPoint;
  final int? driverRating;
  final String? riderPhotoUrl;
  final String? vehicleInfo;

  RiderReview copyWith({int? driverRating, String? riderPhotoUrl, String? vehicleInfo}) {
    return RiderReview(
      requestId: requestId,
      riderId: riderId,
      riderName: riderName,
      employeeId: employeeId,
      pickupPoint: pickupPoint,
      dropOffPoint: dropOffPoint,
      driverRating: driverRating ?? this.driverRating,
      riderPhotoUrl: riderPhotoUrl ?? this.riderPhotoUrl,
      vehicleInfo: vehicleInfo ?? this.vehicleInfo,
    );
  }
}
