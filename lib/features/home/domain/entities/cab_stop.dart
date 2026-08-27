class CabStop {
  final String pickupAddress;
  final double? pickupLat;
  final double? pickupLng;

  final String dropOffAddress;
  final double? dropOffLat;
  final double? dropOffLng;

  const CabStop({
    required this.pickupAddress,
    this.pickupLat,
    this.pickupLng,
    required this.dropOffAddress,
    this.dropOffLat,
    this.dropOffLng,
  });
}