part of 'find_ride_results_bloc.dart';

enum FindRideResultsStatus { initial, loading, loaded }

class FindRideResultsState extends Equatable {
  const FindRideResultsState({
    this.status = FindRideResultsStatus.initial,
    this.fromAddress,
    this.toAddress,
    this.fromLat,
    this.fromLng,
    this.toLat,
    this.toLng,
    this.date,
    this.time,
    this.vehicleType,
    this.currentLat,
    this.currentLng,
    this.results = const [],
  });

  final FindRideResultsStatus status;
  final String? fromAddress;
  final String? toAddress;
  final double? fromLat;
  final double? fromLng;
  final double? toLat;
  final double? toLng;
  final DateTime? date;
  final TimeOfDay? time;
  final String? vehicleType;
  final double? currentLat;
  final double? currentLng;
  final List<RideMatch> results;

  FindRideResultsState copyWith({
    FindRideResultsStatus? status,
    String? fromAddress,
    String? toAddress,
    double? fromLat,
    double? fromLng,
    double? toLat,
    double? toLng,
    DateTime? date,
    TimeOfDay? time,
    String? vehicleType,
    double? currentLat,
    double? currentLng,
    List<RideMatch>? results,
  }) {
    return FindRideResultsState(
      status: status ?? this.status,
      fromAddress: fromAddress ?? this.fromAddress,
      toAddress: toAddress ?? this.toAddress,
      fromLat: fromLat ?? this.fromLat,
      fromLng: fromLng ?? this.fromLng,
      toLat: toLat ?? this.toLat,
      toLng: toLng ?? this.toLng,
      date: date ?? this.date,
      time: time ?? this.time,
      vehicleType: vehicleType ?? this.vehicleType,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      results: results ?? this.results,
    );
  }

  @override
  List<Object?> get props => [
        status,
        fromAddress,
        toAddress,
        fromLat,
        fromLng,
        toLat,
        toLng,
        date,
        time,
        vehicleType,
        currentLat,
        currentLng,
        results,
      ];
}
