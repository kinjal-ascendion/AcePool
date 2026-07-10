import 'package:acepool/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/onboarding_selection.dart';
import '../widgets/onboarding_next_button.dart';
import '../widgets/onboarding_option_tile.dart';
import '../widgets/onboarding_progress_bar.dart';
import 'travel_preference_page.dart';

enum VehiclePreference { car, bike, both }

class VehiclePreferencePage extends StatefulWidget {
  const VehiclePreferencePage({super.key, required this.travelPreference});

  final TravelPreference travelPreference;

  @override
  State<VehiclePreferencePage> createState() => _VehiclePreferencePageState();
}

class _VehiclePreferencePageState extends State<VehiclePreferencePage> {
  VehiclePreference _selected = VehiclePreference.car;

  void _onNext() {
    context.go(
      '/login',
      extra: OnboardingSelection(
        travelPreference: widget.travelPreference,
        vehicleType: _selected,
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
                      OnboardingOptionTile(
                        label: 'Car',
                        selected: _selected == VehiclePreference.car,
                        onTap: () =>
                            setState(() => _selected = VehiclePreference.car),
                      ),
                      const SizedBox(height: 12),
                      OnboardingOptionTile(
                        label: 'Bike/ Scooty',
                        selected: _selected == VehiclePreference.bike,
                        onTap: () =>
                            setState(() => _selected = VehiclePreference.bike),
                      ),
                      const SizedBox(height: 12),
                      OnboardingOptionTile(
                        label: 'Both',
                        selected: _selected == VehiclePreference.both,
                        onTap: () =>
                            setState(() => _selected = VehiclePreference.both),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Note: Helmet is mandatory if you choose a 2-wheeler',
                        style: TextStyle(fontSize: 12, color: AppColors.black45),
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
