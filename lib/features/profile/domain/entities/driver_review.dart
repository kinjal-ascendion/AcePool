class DriverReview {
  const DriverReview({
    required this.requestId,
    required this.rideId,
    required this.driverId,
    required this.driverName,
    required this.employeeId,
    required this.pickupPoint,
    required this.dropOffPoint,
    this.driverPhotoUrl,
    this.riderRating,
  });

  final String requestId;
  final String rideId;
  final String driverId;
  final String driverName;
  final String employeeId;
  final String pickupPoint;
  final String dropOffPoint;
  final String? driverPhotoUrl;
  final int? riderRating;

  DriverReview copyWith({int? riderRating, String? driverPhotoUrl}) {
    return DriverReview(
      requestId: requestId,
      rideId: rideId,
      driverId: driverId,
      driverName: driverName,
      employeeId: employeeId,
      pickupPoint: pickupPoint,
      dropOffPoint: dropOffPoint,
      driverPhotoUrl: driverPhotoUrl ?? this.driverPhotoUrl,
      riderRating: riderRating ?? this.riderRating,
    );
  }
}
