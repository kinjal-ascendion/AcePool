part of 'home_bloc.dart';

const _unset = Object();

enum HomeStatus { initial, loading, success, failure, scheduling, scheduled }

enum RideMode { find, offer }

enum VehicleType { car, bike }

class HomeState extends Equatable {
  final HomeStatus status;
  final RideMode rideMode;
  final VehicleType vehicleType;
  final String? fromAddress;
  final double? fromLatitude;
  final double? fromLongitude;
  final String? toAddress;
  final double? toLatitude;
  final double? toLongitude;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final int seatCount;
  final List<UpcomingTrip> upcomingTrips;
  final String? errorMessage;

  const HomeState({
    this.status = HomeStatus.initial,
    this.rideMode = RideMode.offer,
    this.vehicleType = VehicleType.car,
    this.fromAddress,
    this.fromLatitude,
    this.fromLongitude,
    this.toAddress,
    this.toLatitude,
    this.toLongitude,
    this.selectedDate,
    this.selectedTime,
    this.seatCount = 1,
    this.upcomingTrips = const [],
    this.errorMessage,
  });

  bool get isFormValid =>
      fromAddress != null &&
      fromAddress!.trim().isNotEmpty &&
      toAddress != null &&
      toAddress!.trim().isNotEmpty &&
      selectedDate != null &&
      selectedTime != null;

  HomeState copyWith({
    HomeStatus? status,
    RideMode? rideMode,
    VehicleType? vehicleType,
    Object? fromAddress = _unset,
    Object? fromLatitude = _unset,
    Object? fromLongitude = _unset,
    Object? toAddress = _unset,
    Object? toLatitude = _unset,
    Object? toLongitude = _unset,
    DateTime? selectedDate,
    TimeOfDay? selectedTime,
    int? seatCount,
    List<UpcomingTrip>? upcomingTrips,
    Object? errorMessage = _unset,
  }) {
    return HomeState(
      status: status ?? this.status,
      rideMode: rideMode ?? this.rideMode,
      vehicleType: vehicleType ?? this.vehicleType,
      fromAddress: fromAddress == _unset ? this.fromAddress : fromAddress as String?,
      fromLatitude: fromLatitude == _unset ? this.fromLatitude : fromLatitude as double?,
      fromLongitude: fromLongitude == _unset ? this.fromLongitude : fromLongitude as double?,
      toAddress: toAddress == _unset ? this.toAddress : toAddress as String?,
      toLatitude: toLatitude == _unset ? this.toLatitude : toLatitude as double?,
      toLongitude: toLongitude == _unset ? this.toLongitude : toLongitude as double?,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      seatCount: seatCount ?? this.seatCount,
      upcomingTrips: upcomingTrips ?? this.upcomingTrips,
      errorMessage: errorMessage == _unset ? this.errorMessage : errorMessage as String?,
    );
  }

  HomeState swapLocations() {
    return HomeState(
      status: status,
      rideMode: rideMode,
      vehicleType: vehicleType,
      fromAddress: toAddress,
      fromLatitude: toLatitude,
      fromLongitude: toLongitude,
      toAddress: fromAddress,
      toLatitude: fromLatitude,
      toLongitude: fromLongitude,
      selectedDate: selectedDate,
      selectedTime: selectedTime,
      seatCount: seatCount,
      upcomingTrips: upcomingTrips,
      errorMessage: errorMessage,
    );
  }

  HomeState resetForm() {
    return HomeState(
      status: HomeStatus.success,
      rideMode: rideMode,
      vehicleType: vehicleType,
      upcomingTrips: upcomingTrips,
    );
  }

  @override
  List<Object?> get props => [
    status,
    rideMode,
    vehicleType,
    fromAddress,
    fromLatitude,
    fromLongitude,
    toAddress,
    toLatitude,
    toLongitude,
    selectedDate,
    selectedTime,
    seatCount,
    upcomingTrips,
    errorMessage,
  ];
}
