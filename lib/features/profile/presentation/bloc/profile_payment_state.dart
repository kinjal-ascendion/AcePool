part of 'profile_payment_bloc.dart';

const _unset = Object();

class ProfilePaymentState extends Equatable {
  const ProfilePaymentState({
    this.selectedMethod = 'UPI',
    this.isEditing = false,
    this.savedTick = 0,
    this.upiId = '',
    this.upiPhone = '',
    this.errorMessage,
  });

  final String selectedMethod;
  final bool isEditing;
  final int savedTick;
  final String upiId;
  final String upiPhone;
  final String? errorMessage;

  ProfilePaymentState copyWith({
    String? selectedMethod,
    bool? isEditing,
    int? savedTick,
    String? upiId,
    String? upiPhone,
    Object? errorMessage = _unset,
  }) {
    return ProfilePaymentState(
      selectedMethod: selectedMethod ?? this.selectedMethod,
      isEditing: isEditing ?? this.isEditing,
      savedTick: savedTick ?? this.savedTick,
      upiId: upiId ?? this.upiId,
      upiPhone: upiPhone ?? this.upiPhone,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    selectedMethod,
    isEditing,
    savedTick,
    upiId,
    upiPhone,
    errorMessage,
  ];
}
