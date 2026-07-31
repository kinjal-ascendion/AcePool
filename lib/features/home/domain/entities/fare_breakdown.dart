import 'package:equatable/equatable.dart';

class FareBreakdown extends Equatable {
  final double distanceKm;
  final int durationMinutes;
  final String? vehicleId;
  final String? vehicleLabel;
  final double ratePerKm;

  const FareBreakdown({
    required this.distanceKm,
    required this.durationMinutes,
    this.vehicleId,
    this.vehicleLabel,
    this.ratePerKm = 0,
  });

  double get totalCost => distanceKm * ratePerKm;

  FareBreakdown copyWith({
    double? distanceKm,
    int? durationMinutes,
    String? vehicleId,
    String? vehicleLabel,
    double? ratePerKm,
  }) {
    return FareBreakdown(
      distanceKm: distanceKm ?? this.distanceKm,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleLabel: vehicleLabel ?? this.vehicleLabel,
      ratePerKm: ratePerKm ?? this.ratePerKm,
    );
  }

  @override
  List<Object?> get props => [
    distanceKm,
    durationMinutes,
    vehicleId,
    vehicleLabel,
    ratePerKm,
  ];
}
