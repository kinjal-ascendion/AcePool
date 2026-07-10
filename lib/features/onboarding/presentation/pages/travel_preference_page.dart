import 'package:acepool/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/onboarding_next_button.dart';
import '../widgets/onboarding_option_tile.dart';
import '../widgets/onboarding_progress_bar.dart';

enum TravelPreference { ride, drive, both }

class TravelPreferencePage extends StatefulWidget {
  const TravelPreferencePage({super.key});

  @override
  State<TravelPreferencePage> createState() => _TravelPreferencePageState();
}

class _TravelPreferencePageState extends State<TravelPreferencePage> {
  TravelPreference _selected = TravelPreference.ride;

  void _onNext() {
    context.go('/onboarding/vehicle-preference', extra: _selected);
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
                      OnboardingOptionTile(
                        label: 'Find Ride',
                        selected: _selected == TravelPreference.ride,
                        onTap: () =>
                            setState(() => _selected = TravelPreference.ride),
                      ),
                      const SizedBox(height: 12),
                      OnboardingOptionTile(
                        label: 'Offer Ride',
                        selected: _selected == TravelPreference.drive,
                        onTap: () =>
                            setState(() => _selected = TravelPreference.drive),
                      ),
                      const SizedBox(height: 12),
                      OnboardingOptionTile(
                        label: 'Both',
                        selected: _selected == TravelPreference.both,
                        onTap: () =>
                            setState(() => _selected = TravelPreference.both),
                      ),
                    ],
                  ),
                ),
              ),
              OnboardingNextButton(onPressed: _onNext),
            ],
          ),
        ),
      ),
    );
  }
}
