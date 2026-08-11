part of 'travel_preference_bloc.dart';

class TravelPreferenceState extends Equatable {
  final TravelPreference selected;

  const TravelPreferenceState({required this.selected});

  @override
  List<Object?> get props => [selected];
}
