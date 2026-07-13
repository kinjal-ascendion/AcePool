import 'dart:math' as math;

import 'package:equatable/equatable.dart';

class FareBreakdown extends Equatable {
  final double distanceKm;
  final int durationMinutes;
  final double distanceCost;
  final double tollCost;
  final bool includeTolls;
  final double detourCost;
  final int riderCount;

  const FareBreakdown({
    required this.distanceKm,
    required this.durationMinutes,
    required this.distanceCost,
    required this.tollCost,
    required this.includeTolls,
    required this.detourCost,
    required this.riderCount,
  });

  double get totalSharedCost => distanceCost + (includeTolls ? tollCost : 0) + detourCost;

  double get farePerSeat => totalSharedCost / riderCount;

  double get driverEarnings => farePerSeat * riderCount;

  FareBreakdown copyWith({
    double? distanceKm,
    int? durationMinutes,
    double? distanceCost,
    double? tollCost,
    bool? includeTolls,
    double? detourCost,
    int? riderCount,
  }) {
    return FareBreakdown(
      distanceKm: distanceKm ?? this.distanceKm,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      distanceCost: distanceCost ?? this.distanceCost,
      tollCost: tollCost ?? this.tollCost,
      includeTolls: includeTolls ?? this.includeTolls,
      detourCost: detourCost ?? this.detourCost,
      riderCount: riderCount ?? this.riderCount,
    );
  }

  static int clampRiderCount(int count) => math.max(1, math.min(4, count));

  @override
  List<Object?> get props => [
    distanceKm,
    durationMinutes,
    distanceCost,
    tollCost,
    includeTolls,
    detourCost,
    riderCount,
  ];
}
