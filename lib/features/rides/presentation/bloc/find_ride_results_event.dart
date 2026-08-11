part of 'find_ride_results_bloc.dart';

abstract class FindRideResultsEvent extends Equatable {
  const FindRideResultsEvent();

  @override
  List<Object?> get props => [];
}

class FindRideResultsRequested extends FindRideResultsEvent {
  const FindRideResultsRequested({
    required this.fromAddress,
    required this.toAddress,
    this.fromLat,
    this.fromLng,
    this.toLat,
    this.toLng,
    required this.date,
    required this.time,
    required this.vehicleType,
    this.currentLat,
    this.currentLng,
  });

  final String fromAddress;
  final String toAddress;
  final double? fromLat;
  final double? fromLng;
  final double? toLat;
  final double? toLng;
  final DateTime date;
  final TimeOfDay time;
  final String vehicleType;
  final double? currentLat;
  final double? currentLng;

  @override
  List<Object?> get props => [
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
      ];
}

class FindRideResultsRefreshed extends FindRideResultsEvent {
  const FindRideResultsRefreshed();
}
