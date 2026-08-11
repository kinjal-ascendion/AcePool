import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:acepool/features/profile/domain/repositories/profile_repository.dart';

part 'account_settings_event.dart';
part 'account_settings_state.dart';

class AccountSettingsBloc extends Bloc<AccountSettingsEvent, AccountSettingsState> {
  AccountSettingsBloc({required ProfileRepository profileRepository})
      : _profileRepository = profileRepository,
        super(const AccountSettingsState()) {
    on<AccountSettingsSaveRequested>(_onSaveRequested);
  }

  final ProfileRepository _profileRepository;

  Future<void> _onSaveRequested(
    AccountSettingsSaveRequested event,
    Emitter<AccountSettingsState> emit,
  ) async {
    if (event.phone.isNotEmpty && event.phone.length != 10) {
      emit(state.copyWith(
        status: AccountSettingsStatus.failure,
        message: 'Enter a valid 10-digit phone number',
      ));
      return;
    }

    emit(state.copyWith(status: AccountSettingsStatus.saving));
    try {
      await _profileRepository.updateProfile(
        fullName: event.fullName,
        phone: event.phone,
        email: event.email,
        licenceVerified: event.licenceVerified,
        licenceNumber: event.licenceNumber,
      );
      emit(state.copyWith(status: AccountSettingsStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: AccountSettingsStatus.failure,
        message: 'Failed to save profile: $e',
      ));
    }
  }
}
