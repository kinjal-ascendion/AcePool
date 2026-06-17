part of 'home_bloc.dart';

enum HomeStatus { initial, loading, success, failure }

enum RideMode { find, offer }

enum VehicleType { car, bike }

class HomeState extends Equatable {
  final HomeStatus status;
  final RideMode rideMode;
  final VehicleType vehicleType;
  final String? fromAddress;
  final String? toAddress;
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
    this.selectedDate,
    this.selectedTime,
    this.seatCount = 1,
    this.upcomingTrips = const [],
    this.errorMessage,
  });

  HomeState copyWith({
    HomeStatus? status,
    RideMode? rideMode,
    VehicleType? vehicleType,
    String? fromAddress,
    String? toAddress,
    DateTime? selectedDate,
    TimeOfDay? selectedTime,
    int? seatCount,
    List<UpcomingTrip>? upcomingTrips,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      rideMode: rideMode ?? this.rideMode,
      vehicleType: vehicleType ?? this.vehicleType,
      fromAddress: fromAddress ?? this.fromAddress,
      toAddress: toAddress ?? this.toAddress,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      seatCount: seatCount ?? this.seatCount,
      upcomingTrips: upcomingTrips ?? this.upcomingTrips,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  // copyWith can't represent "set back to null", so swapping (where either
  // side may be null) needs a dedicated constructor call instead.
  HomeState swapLocations() {
    return HomeState(
      status: status,
      rideMode: rideMode,
      vehicleType: vehicleType,
      fromAddress: toAddress,
      toAddress: fromAddress,
      selectedDate: selectedDate,
      selectedTime: selectedTime,
      seatCount: seatCount,
      upcomingTrips: upcomingTrips,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    rideMode,
    vehicleType,
    fromAddress,
    toAddress,
    selectedDate,
    selectedTime,
    seatCount,
    upcomingTrips,
    errorMessage,
  ];
}
