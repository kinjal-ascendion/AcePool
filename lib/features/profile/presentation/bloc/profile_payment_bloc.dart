import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:acepool/features/profile/domain/repositories/profile_repository.dart';

part 'profile_payment_event.dart';
part 'profile_payment_state.dart';

class ProfilePaymentBloc extends Bloc<ProfilePaymentEvent, ProfilePaymentState> {
  ProfilePaymentBloc({required ProfileRepository profileRepository})
      : _profileRepository = profileRepository,
        super(const ProfilePaymentState()) {
    on<ProfilePaymentMethodChanged>(_onMethodChanged);
    on<ProfilePaymentEditToggled>(_onEditToggled);
    on<ProfilePaymentSaveRequested>(_onSaveRequested);
    on<ProfilePaymentDetailsLoaded>(_onDetailsLoaded);
    _loadPaymentDetails();
  }

  final ProfileRepository _profileRepository;

  void _onMethodChanged(ProfilePaymentMethodChanged event, Emitter<ProfilePaymentState> emit) {
    emit(state.copyWith(selectedMethod: event.method));
  }

  void _onEditToggled(ProfilePaymentEditToggled event, Emitter<ProfilePaymentState> emit) {
    emit(state.copyWith(isEditing: !state.isEditing));
  }

  Future<void> _onSaveRequested(
    ProfilePaymentSaveRequested event,
    Emitter<ProfilePaymentState> emit,
  ) async {
    await _profileRepository.savePaymentDetails(
      method: state.selectedMethod,
      upiId: event.upiId,
      upiPhone: event.upiPhone,
    );
    emit(
      state.copyWith(
        savedTick: state.savedTick + 1,
        upiId: event.upiId,
        upiPhone: event.upiPhone,
      ),
    );
  }

  void _onDetailsLoaded(
    ProfilePaymentDetailsLoaded event,
    Emitter<ProfilePaymentState> emit,
  ) {
    emit(
      state.copyWith(
        selectedMethod: event.method,
        upiId: event.upiId,
        upiPhone: event.upiPhone,
      ),
    );
  }

  Future<void> _loadPaymentDetails() async {
    try {
      final details = await _profileRepository.getPaymentDetails();
      add(
        ProfilePaymentDetailsLoaded(
          method: details.method,
          upiId: details.upiId,
          upiPhone: details.upiPhone,
        ),
      );
    } catch (_) {
      // Keep defaults if the fetch fails.
    }
  }
}
