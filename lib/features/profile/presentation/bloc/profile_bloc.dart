import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:acepool/features/profile/domain/entities/profile_summary.dart';
import 'package:acepool/features/profile/domain/repositories/profile_repository.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({required ProfileRepository profileRepository})
      : _profileRepository = profileRepository,
        super(const ProfileState()) {
    on<ProfileStarted>(_onStarted);
  }

  final ProfileRepository _profileRepository;

  Future<void> _onStarted(ProfileStarted event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    await emit.forEach<ProfileSummary>(
      _profileRepository.watchProfile(),
      onData: (summary) => state.copyWith(status: ProfileStatus.loaded, summary: summary),
    );
  }
}
