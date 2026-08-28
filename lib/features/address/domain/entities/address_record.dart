class AddressRecord {
  const AddressRecord({
    required this.id,
    required this.category,
    required this.label,
    required this.address,
    required this.landmark,
    this.lat,
    this.lng,
    required this.isDefault,
  });

  final String id;
  final String category;
  final String label;
  final String address;
  final String landmark;
  final double? lat;
  final double? lng;
  final bool isDefault;
}
