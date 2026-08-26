part of 'pricing_bloc.dart';

enum PricingStatus { loading, ready, publishing, published, failure }

enum PricingTab { current, returnRide }

class PricingState extends Equatable {
  final PricingStatus status;
  final PricingTab activeTab;
  final bool hasReturnRide;

  // First Ride Details
  final String fromAddress;
  final String toAddress;
  final DateTime? date;
  final TimeOfDay? time;
  final int seatCount;
  final FareBreakdown? fare;

  // Return Ride Details
  final TimeOfDay? returnTime;
  final int returnSeatCount;
  final FareBreakdown? returnFare;

  final String vehicleType;
  final List<VehicleOption> vehicles;
  final String? errorMessage;

  const PricingState({
    this.status = PricingStatus.loading,
    this.activeTab = PricingTab.current,
    this.hasReturnRide = false,
    this.fromAddress = '',
    this.toAddress = '',
    this.date,
    this.time,
    this.seatCount = 1,
    this.fare,
    this.returnTime,
    this.returnSeatCount = 1,
    this.returnFare,
    this.vehicleType = 'car',
    this.vehicles = const [],
    this.errorMessage,
  });

  bool get isFormValid {
    if (fare == null || fare!.vehicleId == null || fare!.ratePerKm <= 0) {
      return false;
    }
    if (hasReturnRide) {
      if (returnFare == null ||
          returnFare!.vehicleId == null ||
          returnFare!.ratePerKm <= 0) {
        return false;
      }
    }
    return true;
  }

  PricingState copyWith({
    PricingStatus? status,
    PricingTab? activeTab,
    bool? hasReturnRide,
    String? fromAddress,
    String? toAddress,
    DateTime? date,
    TimeOfDay? time,
    int? seatCount,
    FareBreakdown? fare,
    TimeOfDay? returnTime,
    int? returnSeatCount,
    FareBreakdown? returnFare,
    String? vehicleType,
    List<VehicleOption>? vehicles,
    String? errorMessage,
  }) {
    return PricingState(
      status: status ?? this.status,
      activeTab: activeTab ?? this.activeTab,
      hasReturnRide: hasReturnRide ?? this.hasReturnRide,
      fromAddress: fromAddress ?? this.fromAddress,
      toAddress: toAddress ?? this.toAddress,
      date: date ?? this.date,
      time: time ?? this.time,
      seatCount: seatCount ?? this.seatCount,
      fare: fare ?? this.fare,
      returnTime: returnTime ?? this.returnTime,
      returnSeatCount: returnSeatCount ?? this.returnSeatCount,
      returnFare: returnFare ?? this.returnFare,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicles: vehicles ?? this.vehicles,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        activeTab,
        hasReturnRide,
        fromAddress,
        toAddress,
        date,
        time,
        seatCount,
        fare,
        returnTime,
        returnSeatCount,
        returnFare,
        vehicleType,
        vehicles,
        errorMessage,
      ];
}
