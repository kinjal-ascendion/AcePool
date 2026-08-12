import 'package:acepool/features/onboarding/domain/entities/vehicle_preference.dart';
import 'package:acepool/features/onboarding/presentation/bloc/vehicle_preference_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VehicleOptionSelected equality', () {
    test('supports value equality based on props', () {
      expect(
        const VehicleOptionSelected(VehiclePreference.car),
        const VehicleOptionSelected(VehiclePreference.car),
      );
      expect(
        const VehicleOptionSelected(VehiclePreference.car).props,
        [VehiclePreference.car],
      );
      expect(
        const VehicleOptionSelected(VehiclePreference.car),
        isNot(const VehicleOptionSelected(VehiclePreference.bike)),
      );
    });
  });

  group('VehiclePreferenceBloc', () {
    test('initial state selects VehiclePreference.car', () {
      expect(
        VehiclePreferenceBloc().state,
        const VehiclePreferenceState(selected: VehiclePreference.car),
      );
    });

    blocTest<VehiclePreferenceBloc, VehiclePreferenceState>(
      'emits state with bike selected when VehicleOptionSelected(bike) is added',
      build: VehiclePreferenceBloc.new,
      act: (bloc) =>
          bloc.add(const VehicleOptionSelected(VehiclePreference.bike)),
      expect: () => const [
        VehiclePreferenceState(selected: VehiclePreference.bike),
      ],
    );

    blocTest<VehiclePreferenceBloc, VehiclePreferenceState>(
      'emits state with both selected when VehicleOptionSelected(both) is added',
      build: VehiclePreferenceBloc.new,
      act: (bloc) =>
          bloc.add(const VehicleOptionSelected(VehiclePreference.both)),
      expect: () => const [
        VehiclePreferenceState(selected: VehiclePreference.both),
      ],
    );

    blocTest<VehiclePreferenceBloc, VehiclePreferenceState>(
      'emits state with car selected when VehicleOptionSelected(car) is added',
      build: VehiclePreferenceBloc.new,
      act: (bloc) =>
          bloc.add(const VehicleOptionSelected(VehiclePreference.car)),
      expect: () => const [
        VehiclePreferenceState(selected: VehiclePreference.car),
      ],
    );

    blocTest<VehiclePreferenceBloc, VehiclePreferenceState>(
      'emits one state per selection event, reflecting the latest choice',
      build: VehiclePreferenceBloc.new,
      act: (bloc) {
        bloc
          ..add(const VehicleOptionSelected(VehiclePreference.bike))
          ..add(const VehicleOptionSelected(VehiclePreference.both));
      },
      expect: () => const [
        VehiclePreferenceState(selected: VehiclePreference.bike),
        VehiclePreferenceState(selected: VehiclePreference.both),
      ],
    );
  });
}
