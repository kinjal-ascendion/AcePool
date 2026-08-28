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
    on<ProfilePaymentErrorDismissed>(_onErrorDismissed);
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
    try {
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
          errorMessage: null,
          isEditing: false, // Lock the fields again after a successful save.
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Could not save payment details. Please try again.',
        ),
      );
    }
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

  void _onErrorDismissed(
    ProfilePaymentErrorDismissed event,
    Emitter<ProfilePaymentState> emit,
  ) {
    emit(state.copyWith(errorMessage: null));
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
