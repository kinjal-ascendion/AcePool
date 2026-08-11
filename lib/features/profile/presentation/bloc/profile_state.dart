part of 'profile_bloc.dart';

enum ProfileStatus { initial, loading, loaded }

class ProfileState extends Equatable {
  const ProfileState({this.status = ProfileStatus.initial, this.summary});

  final ProfileStatus status;
  final ProfileSummary? summary;

  ProfileState copyWith({ProfileStatus? status, ProfileSummary? summary}) {
    return ProfileState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
    );
  }

  @override
  List<Object?> get props => [status, summary];
}
