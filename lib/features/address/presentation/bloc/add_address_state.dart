part of 'add_address_bloc.dart';

enum AddAddressStatus { initial, saving, success, validationFailure, saveError }

class AddAddressState extends Equatable {
  const AddAddressState({
    this.status = AddAddressStatus.initial,
    this.message,
  });

  final AddAddressStatus status;
  final String? message;

  AddAddressState copyWith({
    AddAddressStatus? status,
    String? message,
  }) {
    return AddAddressState(
      status: status ?? this.status,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, message];
}
