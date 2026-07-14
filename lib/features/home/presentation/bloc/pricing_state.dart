part of 'pricing_bloc.dart';

enum PricingStatus { loading, ready, publishing, published, failure }

class PricingState extends Equatable {
  final PricingStatus status;
  final String fromAddress;
  final String toAddress;
  final DateTime? date;
  final TimeOfDay? time;
  final int seatCount;
  final String vehicleType;
  final FareBreakdown? fare;
  final String? errorMessage;

  const PricingState({
    this.status = PricingStatus.loading,
    this.fromAddress = '',
    this.toAddress = '',
    this.date,
    this.time,
    this.seatCount = 1,
    this.vehicleType = 'car',
    this.fare,
    this.errorMessage,
  });

  PricingState copyWith({
    PricingStatus? status,
    String? fromAddress,
    String? toAddress,
    DateTime? date,
    TimeOfDay? time,
    int? seatCount,
    String? vehicleType,
    FareBreakdown? fare,
    String? errorMessage,
  }) {
    return PricingState(
      status: status ?? this.status,
      fromAddress: fromAddress ?? this.fromAddress,
      toAddress: toAddress ?? this.toAddress,
      date: date ?? this.date,
      time: time ?? this.time,
      seatCount: seatCount ?? this.seatCount,
      vehicleType: vehicleType ?? this.vehicleType,
      fare: fare ?? this.fare,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    fromAddress,
    toAddress,
    date,
    time,
    seatCount,
    vehicleType,
    fare,
    errorMessage,
  ];
}
