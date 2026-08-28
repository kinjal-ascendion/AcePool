part of 'travel_preference_bloc.dart';

abstract class TravelPreferenceEvent extends Equatable {
  const TravelPreferenceEvent();

  @override
  List<Object?> get props => [];
}

class TravelOptionSelected extends TravelPreferenceEvent {
  final TravelPreference value;

  const TravelOptionSelected(this.value);

  @override
  List<Object?> get props => [value];
}
