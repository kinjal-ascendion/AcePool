import 'package:acepool/features/onboarding/domain/entities/travel_preference.dart';
import 'package:acepool/features/onboarding/presentation/bloc/travel_preference_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TravelOptionSelected equality', () {
    test('supports value equality based on props', () {
      expect(
        const TravelOptionSelected(TravelPreference.ride),
        const TravelOptionSelected(TravelPreference.ride),
      );
      expect(
        const TravelOptionSelected(TravelPreference.ride).props,
        [TravelPreference.ride],
      );
      expect(
        const TravelOptionSelected(TravelPreference.ride),
        isNot(const TravelOptionSelected(TravelPreference.drive)),
      );
    });
  });

  group('TravelPreferenceBloc', () {
    test('initial state selects TravelPreference.ride', () {
      expect(
        TravelPreferenceBloc().state,
        const TravelPreferenceState(selected: TravelPreference.ride),
      );
    });

    blocTest<TravelPreferenceBloc, TravelPreferenceState>(
      'emits state with drive selected when TravelOptionSelected(drive) is added',
      build: TravelPreferenceBloc.new,
      act: (bloc) => bloc.add(const TravelOptionSelected(TravelPreference.drive)),
      expect: () => const [
        TravelPreferenceState(selected: TravelPreference.drive),
      ],
    );

    blocTest<TravelPreferenceBloc, TravelPreferenceState>(
      'emits state with both selected when TravelOptionSelected(both) is added',
      build: TravelPreferenceBloc.new,
      act: (bloc) => bloc.add(const TravelOptionSelected(TravelPreference.both)),
      expect: () => const [
        TravelPreferenceState(selected: TravelPreference.both),
      ],
    );

    blocTest<TravelPreferenceBloc, TravelPreferenceState>(
      'emits state with ride selected when TravelOptionSelected(ride) is added',
      build: TravelPreferenceBloc.new,
      act: (bloc) => bloc.add(const TravelOptionSelected(TravelPreference.ride)),
      expect: () => const [
        TravelPreferenceState(selected: TravelPreference.ride),
      ],
    );

    blocTest<TravelPreferenceBloc, TravelPreferenceState>(
      'emits one state per selection event, reflecting the latest choice',
      build: TravelPreferenceBloc.new,
      act: (bloc) {
        bloc
          ..add(const TravelOptionSelected(TravelPreference.drive))
          ..add(const TravelOptionSelected(TravelPreference.both));
      },
      expect: () => const [
        TravelPreferenceState(selected: TravelPreference.drive),
        TravelPreferenceState(selected: TravelPreference.both),
      ],
    );
  });
}
