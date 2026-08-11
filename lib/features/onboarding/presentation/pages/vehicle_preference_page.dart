import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/travel_preference.dart';
import '../../domain/entities/vehicle_preference.dart';
import '../../domain/onboarding_selection.dart';
import '../bloc/vehicle_preference_bloc.dart';
import '../widgets/onboarding_next_button.dart';
import '../widgets/onboarding_option_tile.dart';
import '../widgets/onboarding_progress_bar.dart';

class VehiclePreferencePage extends StatelessWidget {
  const VehiclePreferencePage({super.key, required this.travelPreference});

  final TravelPreference travelPreference;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<VehiclePreferenceBloc>(),
      child: _VehiclePreferenceView(travelPreference: travelPreference),
    );
  }
}

class _VehiclePreferenceView extends StatelessWidget {
  const _VehiclePreferenceView({required this.travelPreference});

  final TravelPreference travelPreference;

  void _onNext(BuildContext context) {
    final selected = context.read<VehiclePreferenceBloc>().state.selected;
    context.go(
      '/login',
      extra: OnboardingSelection(
        travelPreference: travelPreference,
        vehicleType: selected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const OnboardingProgressBar(currentStep: 1),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'What are you driving?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black87,
                        ),
                      ),
                      const SizedBox(height: 28),
                      BlocBuilder<
                        VehiclePreferenceBloc,
                        VehiclePreferenceState
                      >(
                        builder: (context, state) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              OnboardingOptionTile(
                                label: 'Car',
                                selected:
                                    state.selected == VehiclePreference.car,
                                onTap: () =>
                                    context.read<VehiclePreferenceBloc>().add(
                                      const VehicleOptionSelected(
                                        VehiclePreference.car,
                                      ),
                                    ),
                              ),
                              const SizedBox(height: 12),
                              OnboardingOptionTile(
                                label: 'Bike/ Scooty',
                                selected:
                                    state.selected == VehiclePreference.bike,
                                onTap: () =>
                                    context.read<VehiclePreferenceBloc>().add(
                                      const VehicleOptionSelected(
                                        VehiclePreference.bike,
                                      ),
                                    ),
                              ),
                              const SizedBox(height: 12),
                              OnboardingOptionTile(
                                label: 'Both',
                                selected:
                                    state.selected == VehiclePreference.both,
                                onTap: () =>
                                    context.read<VehiclePreferenceBloc>().add(
                                      const VehicleOptionSelected(
                                        VehiclePreference.both,
                                      ),
                                    ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Note: Helmet is mandatory if you choose a 2-wheeler',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              OnboardingNextButton(onPressed: () => _onNext(context)),
            ],
          ),
        ),
      ),
    );
  }
}
