class Vehicle {
  const Vehicle({
    required this.id,
    required this.type,
    required this.number,
    required this.brand,
    required this.model,
    required this.seats,
    required this.isDefault,
  });

  final String id;

  /// 'four_wheeler' or 'two_wheeler'.
  final String type;
  final String number;
  final String brand;
  final String model;
  final int seats;
  final bool isDefault;

  bool get isFourWheeler => type == 'four_wheeler';

  String get displayName {
    final name = [brand, model].where((s) => s.isNotEmpty).join(' ');
    return name;
  }
}
