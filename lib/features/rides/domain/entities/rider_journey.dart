/// A rider's resolved journey details for a given ride: their own
/// pickup/drop-off points (from their accepted ride_request, falling back to
/// the driver's endpoints), plus the driver's pinned location/route duration.
class RiderJourney {
  const RiderJourney({
    required this.pickupPoint,
    required this.dropOffPoint,
    required this.riderStartAddress,
    required this.riderEndAddress,
    this.pickupLat,
    this.pickupLng,
    this.dropOffLat,
    this.dropOffLng,
    this.riderStartLat,
    this.riderStartLng,
    this.riderEndLat,
    this.riderEndLng,
    this.pinnedLat,
    this.pinnedLng,
    this.pinnedName,
    required this.driveDurationMinutes,
  });

  final String pickupPoint;
  final String dropOffPoint;
  final String riderStartAddress;
  final String riderEndAddress;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropOffLat;
  final double? dropOffLng;
  final double? riderStartLat;
  final double? riderStartLng;
  final double? riderEndLat;
  final double? riderEndLng;
  final double? pinnedLat;
  final double? pinnedLng;
  final String? pinnedName;
  final int driveDurationMinutes;
}
