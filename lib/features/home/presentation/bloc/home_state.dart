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
  final String? toAddress;
  final LatLng? fromLatLng;
  final LatLng? toLatLng;
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
    this.toAddress,
    this.fromLatLng,
    this.toLatLng,
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
    Object? toAddress = _unset,
    Object? fromLatLng = _unset,
    Object? toLatLng = _unset,
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
      toAddress: toAddress == _unset ? this.toAddress : toAddress as String?,
      fromLatLng: fromLatLng == _unset ? this.fromLatLng : fromLatLng as LatLng?,
      toLatLng: toLatLng == _unset ? this.toLatLng : toLatLng as LatLng?,
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
      toAddress: fromAddress,
      fromLatLng: toLatLng,
      toLatLng: fromLatLng,
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
    toAddress,
    fromLatLng,
    toLatLng,
    selectedDate,
    selectedTime,
    seatCount,
    upcomingTrips,
    errorMessage,
  ];
}
