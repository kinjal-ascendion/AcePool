import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/travel_preference.dart';

part 'travel_preference_event.dart';
part 'travel_preference_state.dart';

class TravelPreferenceBloc
    extends Bloc<TravelPreferenceEvent, TravelPreferenceState> {
  TravelPreferenceBloc()
    : super(const TravelPreferenceState(selected: TravelPreference.ride)) {
    on<TravelOptionSelected>(_onTravelOptionSelected);
  }

  void _onTravelOptionSelected(
    TravelOptionSelected event,
    Emitter<TravelPreferenceState> emit,
  ) {
    emit(TravelPreferenceState(selected: event.value));
  }
}
