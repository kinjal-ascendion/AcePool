part of 'ride_payment_bloc.dart';

enum RidePaymentStatus { initial, success }

class RidePaymentState extends Equatable {
  const RidePaymentState({
    this.selectedMethod = 'upi',
    this.isSubmitting = false,
    this.status = RidePaymentStatus.initial,
  });

  final String selectedMethod;
  final bool isSubmitting;
  final RidePaymentStatus status;

  RidePaymentState copyWith({
    String? selectedMethod,
    bool? isSubmitting,
    RidePaymentStatus? status,
  }) {
    return RidePaymentState(
      selectedMethod: selectedMethod ?? this.selectedMethod,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [selectedMethod, isSubmitting, status];
}
