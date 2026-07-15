import 'package:acepool/core/services/location_service.dart';
import 'package:acepool/features/home/domain/entities/picked_location.dart';
import 'package:acepool/features/home/presentation/bloc/home_bloc.dart';
import 'package:acepool/features/home/presentation/pages/location_search_page.dart';
import 'package:acepool/features/home/presentation/pages/pricing_page.dart';
import 'package:acepool/features/home/presentation/widgets/find_ride_results_section.dart';
import 'package:acepool/features/home/presentation/widgets/home_app_bar_greeting.dart';
import 'package:acepool/features/home/presentation/widgets/ride_mode_toggle.dart';
import 'package:acepool/features/home/presentation/widgets/ride_schedule_form.dart';
import 'package:acepool/features/home/presentation/widgets/upcoming_trips_section.dart';
import 'package:acepool/features/rides/presentation/pages/find_ride_results_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, this.onViewAllTrips, this.onOpenProfile});

  final VoidCallback? onViewAllTrips;
  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    // HomeBloc is provided by MainShellPage, shared with TripsPage's
    // "Find ride" tab so both reflect the same search state.
    return _HomeView(
      onViewAllTrips: onViewAllTrips,
      onOpenProfile: onOpenProfile,
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView({this.onViewAllTrips, this.onOpenProfile});

  final VoidCallback? onViewAllTrips;
  final VoidCallback? onOpenProfile;

  static final _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'acepool',
  );

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && context.mounted) {
      context.read<HomeBloc>().add(DateSelected(picked));
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && context.mounted) {
      context.read<HomeBloc>().add(TimeSelected(picked));
    }
  }

  /// Turns "Find ride" into a location-aware action: if the device's
  /// location service is off, ask the user to turn it on before searching.
  /// The search still runs either way (see `_promptEnableLocation`) — this
  /// only decides whether that prompt is shown first.
  Future<void> _handleFindRide(BuildContext context, HomeBloc bloc) async {
    if (!await LocationService().isServiceEnabled() && context.mounted) {
      await _promptEnableLocation(context);
    }
    bloc.add(const FindRidesRequested());
  }

  /// Shows a dialog asking the user to enable location services, with a
  /// shortcut to the device Settings screen. If the user dismisses this
  /// instead of enabling location, the caller proceeds with the search
  /// anyway — HomeBloc already degrades gracefully when location is
  /// unavailable, so this never blocks "Find ride".
  Future<void> _promptEnableLocation(BuildContext context) async {
    final openSettings = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Turn on location'),
        content: const Text(
          'Enable location services to see how far you are from your pickup point.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
    if (openSettings == true) {
      await Geolocator.openLocationSettings();
    }
  }

  Future<void> _pickLocation(
    BuildContext context, {
    required String title,
    required String? current,
    required void Function(PickedLocation) onConfirm,
  }) async {
    final result = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => LocationSearchPage(title: title, initialValue: current),
      ),
    );
    if (result != null && result.address.trim().isNotEmpty) {
      onConfirm(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeBloc, HomeState>(
      listenWhen: (previous, current) =>
          (previous.status != current.status &&
              current.status == HomeStatus.failure) ||
          (previous.findStatus != current.findStatus &&
              current.findStatus == HomeStatus.failure),
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.errorMessage ?? 'Something went wrong')),
        );
      },
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          final bloc = context.read<HomeBloc>();
          final user = FirebaseAuth.instance.currentUser;
          final displayName = user?.displayName ?? 'User';
          final initials = displayName
              .trim()
              .split(' ')
              .where((w) => w.isNotEmpty)
              .take(2)
              .map((w) => w[0].toUpperCase())
              .join();

          return Scaffold(
            body: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HomeAppBarGreeting(
                          initials: initials,
                          name: displayName,
                          onAvatarTap: onOpenProfile,
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: RideModeToggle(
                            selected: state.rideMode,
                            onChanged: (mode) =>
                                bloc.add(RideModeChanged(mode)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      // extendBody:true (see MainShellPage) draws the body
                      // behind the floating pill nav bar, so the last card
                      // needs its own clearance to scroll fully above it.
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        100,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RideScheduleForm(
                            rideMode: state.rideMode,
                            vehicleType: state.vehicleType,
                            fromAddress: state.fromAddress,
                            toAddress: state.toAddress,
                            selectedDate: state.selectedDate,
                            selectedTime: state.selectedTime,
                            seatCount: state.seatCount,
                            isScheduling: state.rideMode == RideMode.find
                                ? state.findStatus == HomeStatus.loading
                                : false,
                            isFormValid: state.isFormValid,
                            onVehicleTypeChanged: (type) =>
                                bloc.add(VehicleTypeChanged(type)),
                            onFromTap: () => _pickLocation(
                              context,
                              title: 'Start location',
                              current: state.fromAddress,
                              onConfirm: (loc) => bloc.add(
                                FromAddressChanged(
                                  loc.address,
                                  lat: loc.lat,
                                  lng: loc.lng,
                                ),
                              ),
                            ),
                            onToTap: () => _pickLocation(
                              context,
                              title: 'Office location',
                              current: state.toAddress,
                              onConfirm: (loc) => bloc.add(
                                ToAddressChanged(
                                  loc.address,
                                  lat: loc.lat,
                                  lng: loc.lng,
                                ),
                              ),
                            ),
                            onSwap: () => bloc.add(const LocationsSwapped()),
                            onDateTap: () => _pickDate(context),
                            onTimeTap: () => _pickTime(context),
                            onSeatCountChanged: (count) =>
                                bloc.add(SeatCountChanged(count)),
                            onSchedulePressed: () async {
                              if (state.rideMode == RideMode.find) {
                                await _handleFindRide(context, bloc);
                                return;
                              }
                              final published = await Navigator.of(context)
                                  .push<bool>(
                                    MaterialPageRoute(
                                      builder: (_) => PricingPage(
                                        fromAddress: state.fromAddress!,
                                        toAddress: state.toAddress!,
                                        fromLat: state.fromLat,
                                        fromLng: state.fromLng,
                                        toLat: state.toLat,
                                        toLng: state.toLng,
                                        date: state.selectedDate!,
                                        time: state.selectedTime!,
                                        seatCount: state.seatCount,
                                        vehicleType: state.vehicleType.name,
                                        rideMode: state.rideMode.name,
                                      ),
                                    ),
                                  );
                              if (published == true && context.mounted) {
                                bloc.add(const RideFormReset());
                              }
                            },
                          ),
                          if (state.rideMode == RideMode.offer) ...[
                            const SizedBox(height: 28),
                            UpcomingTripsSection(
                              trips: state.upcomingTrips,
                              isLoading: state.status == HomeStatus.loading,
                              onViewAll: onViewAllTrips,
                            ),
                            const SizedBox(height: 16),
                          ] else ...[
                            const SizedBox(height: 28),
                            FindRideResultsSection(
                              results: state.findResults,
                              isLoading: state.findStatus == HomeStatus.loading,
                              hasSearched: state.hasSearchedRides,
                              riderFromAddress: state.fromAddress ?? '',
                              riderFromLat: state.fromLat,
                              riderFromLng: state.fromLng,
                              riderToAddress: state.toAddress ?? '',
                              riderToLat: state.toLat,
                              riderToLng: state.toLng,
                              riderTime: state.selectedTime ?? TimeOfDay.now(),
                              currentLat: state.currentLat,
                              currentLng: state.currentLng,
                              db: _db,
                              onRequested: () => _handleFindRide(context, bloc),
                              onViewAll: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => FindRideResultsPage(
                                    fromAddress: state.fromAddress!,
                                    toAddress: state.toAddress!,
                                    fromLat: state.fromLat,
                                    fromLng: state.fromLng,
                                    toLat: state.toLat,
                                    toLng: state.toLng,
                                    date: state.selectedDate!,
                                    time: state.selectedTime!,
                                    vehicleType: state.vehicleType.name,
                                    currentLat: state.currentLat,
                                    currentLng: state.currentLng,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
