import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/travel_preference.dart';
import '../bloc/travel_preference_bloc.dart';
import '../widgets/onboarding_next_button.dart';
import '../widgets/onboarding_option_tile.dart';
import '../widgets/onboarding_progress_bar.dart';

class TravelPreferencePage extends StatelessWidget {
  const TravelPreferencePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TravelPreferenceBloc>(),
      child: const _TravelPreferenceView(),
    );
  }
}

class _TravelPreferenceView extends StatelessWidget {
  const _TravelPreferenceView();

  void _onNext(BuildContext context) {
    final selected = context.read<TravelPreferenceBloc>().state.selected;
    context.go('/onboarding/vehicle-preference', extra: selected);
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
              const OnboardingProgressBar(currentStep: 0),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Are you going to',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black87,
                        ),
                      ),
                      const SizedBox(height: 28),
                      BlocBuilder<TravelPreferenceBloc, TravelPreferenceState>(
                        builder: (context, state) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              OnboardingOptionTile(
                                label: 'Find Ride',
                                selected:
                                    state.selected == TravelPreference.ride,
                                onTap: () =>
                                    context.read<TravelPreferenceBloc>().add(
                                      const TravelOptionSelected(
                                        TravelPreference.ride,
                                      ),
                                    ),
                              ),
                              const SizedBox(height: 12),
                              OnboardingOptionTile(
                                label: 'Offer Ride',
                                selected:
                                    state.selected == TravelPreference.drive,
                                onTap: () =>
                                    context.read<TravelPreferenceBloc>().add(
                                      const TravelOptionSelected(
                                        TravelPreference.drive,
                                      ),
                                    ),
                              ),
                              const SizedBox(height: 12),
                              OnboardingOptionTile(
                                label: 'Both',
                                selected:
                                    state.selected == TravelPreference.both,
                                onTap: () =>
                                    context.read<TravelPreferenceBloc>().add(
                                      const TravelOptionSelected(
                                        TravelPreference.both,
                                      ),
                                    ),
                              ),
                            ],
                          );
                        },
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
