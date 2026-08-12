part of 'profile_payment_bloc.dart';

class ProfilePaymentState extends Equatable {
  const ProfilePaymentState({
    this.selectedMethod = 'UPI',
    this.isEditing = false,
    this.savedTick = 0,
    this.upiId = '',
    this.upiPhone = '',
  });

  final String selectedMethod;
  final bool isEditing;
  final int savedTick;
  final String upiId;
  final String upiPhone;

  ProfilePaymentState copyWith({
    String? selectedMethod,
    bool? isEditing,
    int? savedTick,
    String? upiId,
    String? upiPhone,
  }) {
    return ProfilePaymentState(
      selectedMethod: selectedMethod ?? this.selectedMethod,
      isEditing: isEditing ?? this.isEditing,
      savedTick: savedTick ?? this.savedTick,
      upiId: upiId ?? this.upiId,
      upiPhone: upiPhone ?? this.upiPhone,
    );
  }

  @override
  List<Object?> get props => [selectedMethod, isEditing, savedTick, upiId, upiPhone];
}
