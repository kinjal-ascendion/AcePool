part of 'addresses_bloc.dart';

enum AddressesStatus { initial, loading, loaded }

class AddressesState extends Equatable {
  const AddressesState({
    this.status = AddressesStatus.initial,
    this.addresses = const [],
  });

  final AddressesStatus status;
  final List<AddressRecord> addresses;

  AddressesState copyWith({
    AddressesStatus? status,
    List<AddressRecord>? addresses,
  }) {
    return AddressesState(
      status: status ?? this.status,
      addresses: addresses ?? this.addresses,
    );
  }

  @override
  List<Object?> get props => [status, addresses];
}
