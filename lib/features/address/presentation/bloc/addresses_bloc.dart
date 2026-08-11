import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:acepool/features/address/domain/entities/address_record.dart';
import 'package:acepool/features/address/domain/repositories/address_repository.dart';

part 'addresses_event.dart';
part 'addresses_state.dart';

class AddressesBloc extends Bloc<AddressesEvent, AddressesState> {
  AddressesBloc({required AddressRepository addressRepository})
      : _addressRepository = addressRepository,
        super(const AddressesState()) {
    on<AddressesStarted>(_onStarted);
  }

  final AddressRepository _addressRepository;

  Future<void> _onStarted(AddressesStarted event, Emitter<AddressesState> emit) async {
    emit(state.copyWith(status: AddressesStatus.loading));
    final addresses = await _addressRepository.getAddresses();
    emit(state.copyWith(status: AddressesStatus.loaded, addresses: addresses));
  }
}
