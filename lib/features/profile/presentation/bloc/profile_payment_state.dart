part of 'profile_payment_bloc.dart';

class ProfilePaymentState extends Equatable {
  const ProfilePaymentState({
    this.selectedMethod = 'UPI',
    this.isEditing = false,
    this.savedTick = 0,
  });

  final String selectedMethod;
  final bool isEditing;
  final int savedTick;

  ProfilePaymentState copyWith({
    String? selectedMethod,
    bool? isEditing,
    int? savedTick,
  }) {
    return ProfilePaymentState(
      selectedMethod: selectedMethod ?? this.selectedMethod,
      isEditing: isEditing ?? this.isEditing,
      savedTick: savedTick ?? this.savedTick,
    );
  }

  @override
  List<Object?> get props => [selectedMethod, isEditing, savedTick];
}
