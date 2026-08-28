import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:acepool/features/address/domain/repositories/address_repository.dart';

part 'add_address_event.dart';
part 'add_address_state.dart';

class AddAddressBloc extends Bloc<AddAddressEvent, AddAddressState> {
  AddAddressBloc({required AddressRepository addressRepository})
      : _addressRepository = addressRepository,
        super(const AddAddressState()) {
    on<AddAddressSaveRequested>(_onSaveRequested);
  }

  final AddressRepository _addressRepository;

  Future<void> _onSaveRequested(
    AddAddressSaveRequested event,
    Emitter<AddAddressState> emit,
  ) async {
    if (event.address.trim().isEmpty) {
      emit(state.copyWith(
        status: AddAddressStatus.validationFailure,
        message: 'Address is required',
      ));
      return;
    }

    emit(state.copyWith(status: AddAddressStatus.saving));
    try {
      await _addressRepository.saveAddress(
        isEdit: event.isEdit,
        docId: event.docId,
        category: event.category,
        label: event.label,
        address: event.address.trim(),
        landmark: event.landmark.trim(),
        lat: event.lat,
        lng: event.lng,
      );
      emit(state.copyWith(status: AddAddressStatus.success));
    } catch (e) {
      // Matches original: save errors are debug-printed only, no snackbar
      // shown to the user — just stop the spinner.
      emit(state.copyWith(status: AddAddressStatus.saveError, message: 'SAVE ERROR: $e'));
    }
  }
}
