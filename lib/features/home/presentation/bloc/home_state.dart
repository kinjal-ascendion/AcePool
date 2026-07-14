part of 'home_bloc.dart';

const _unset = Object();

enum HomeStatus { initial, loading, success, failure }

enum RideMode { find, offer }

enum VehicleType { car, bike }

class HomeState extends Equatable {
  final HomeStatus status;
  final RideMode rideMode;
  final VehicleType vehicleType;
  final String? fromAddress;
  final String? toAddress;
  final double? fromLat;
  final double? fromLng;
  final double? toLat;
  final double? toLng;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final int seatCount;
  final List<UpcomingTrip> upcomingTrips;
  final String? errorMessage;
  final HomeStatus findStatus;
  final List<RideMatch> findResults;
  final bool hasSearchedRides;
  final double? currentLat;
  final double? currentLng;

  const HomeState({
    this.status = HomeStatus.initial,
    this.rideMode = RideMode.offer,
    this.vehicleType = VehicleType.car,
    this.fromAddress,
    this.toAddress,
    this.fromLat,
    this.fromLng,
    this.toLat,
    this.toLng,
    this.selectedDate,
    this.selectedTime,
    this.seatCount = 1,
    this.upcomingTrips = const [],
    this.errorMessage,
    this.findStatus = HomeStatus.initial,
    this.findResults = const [],
    this.hasSearchedRides = false,
    this.currentLat,
    this.currentLng,
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
    Object? fromLat = _unset,
    Object? fromLng = _unset,
    Object? toLat = _unset,
    Object? toLng = _unset,
    DateTime? selectedDate,
    TimeOfDay? selectedTime,
    int? seatCount,
    List<UpcomingTrip>? upcomingTrips,
    Object? errorMessage = _unset,
    HomeStatus? findStatus,
    List<RideMatch>? findResults,
    bool? hasSearchedRides,
    Object? currentLat = _unset,
    Object? currentLng = _unset,
  }) {
    return HomeState(
      status: status ?? this.status,
      rideMode: rideMode ?? this.rideMode,
      vehicleType: vehicleType ?? this.vehicleType,
      fromAddress: fromAddress == _unset ? this.fromAddress : fromAddress as String?,
      toAddress: toAddress == _unset ? this.toAddress : toAddress as String?,
      fromLat: fromLat == _unset ? this.fromLat : fromLat as double?,
      fromLng: fromLng == _unset ? this.fromLng : fromLng as double?,
      toLat: toLat == _unset ? this.toLat : toLat as double?,
      toLng: toLng == _unset ? this.toLng : toLng as double?,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      seatCount: seatCount ?? this.seatCount,
      upcomingTrips: upcomingTrips ?? this.upcomingTrips,
      errorMessage: errorMessage == _unset ? this.errorMessage : errorMessage as String?,
      findStatus: findStatus ?? this.findStatus,
      findResults: findResults ?? this.findResults,
      hasSearchedRides: hasSearchedRides ?? this.hasSearchedRides,
      currentLat: currentLat == _unset ? this.currentLat : currentLat as double?,
      currentLng: currentLng == _unset ? this.currentLng : currentLng as double?,
    );
  }

  HomeState swapLocations() {
    return HomeState(
      status: status,
      rideMode: rideMode,
      vehicleType: vehicleType,
      fromAddress: toAddress,
      toAddress: fromAddress,
      fromLat: toLat,
      fromLng: toLng,
      toLat: fromLat,
      toLng: fromLng,
      selectedDate: selectedDate,
      selectedTime: selectedTime,
      seatCount: seatCount,
      upcomingTrips: upcomingTrips,
      errorMessage: errorMessage,
      findStatus: findStatus,
      findResults: findResults,
      hasSearchedRides: hasSearchedRides,
      currentLat: currentLat,
      currentLng: currentLng,
    );
  }

  HomeState resetForm() {
    return HomeState(
      status: HomeStatus.success,
      rideMode: rideMode,
      vehicleType: vehicleType,
      upcomingTrips: upcomingTrips,
      currentLat: currentLat,
      currentLng: currentLng,
    );
  }

  @override
  List<Object?> get props => [
    status,
    rideMode,
    vehicleType,
    fromAddress,
    toAddress,
    fromLat,
    fromLng,
    toLat,
    toLng,
    selectedDate,
    selectedTime,
    seatCount,
    upcomingTrips,
    errorMessage,
    findStatus,
    findResults,
    hasSearchedRides,
    currentLat,
    currentLng,
  ];
}
