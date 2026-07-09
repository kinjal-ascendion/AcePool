import 'package:acepool/di/injection.dart';
import 'package:acepool/features/home/domain/entities/picked_location.dart';
import 'package:acepool/features/home/presentation/bloc/home_bloc.dart';
import 'package:acepool/features/home/presentation/pages/location_search_page.dart';
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
import 'package:go_router/go_router.dart';
class HomePage extends StatelessWidget {
  const HomePage({super.key, this.onViewAllTrips});

  final VoidCallback? onViewAllTrips;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<HomeBloc>()..add(const HomeStarted()),
      child: _HomeView(onViewAllTrips: onViewAllTrips),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView({this.onViewAllTrips});

  final VoidCallback? onViewAllTrips;

  static final _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'acepool',
  );

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) context.go('/login');
  }

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

  Future<void> _pickLocation(
    BuildContext context, {
    required String title,
    required String? current,
    required void Function(PickedLocation) onConfirm,
  }) async {
    final result = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => LocationSearchPage(
          title: title,
          initialValue: current,
        ),
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
              (current.status == HomeStatus.failure ||
                  current.status == HomeStatus.scheduled)) ||
          (previous.findStatus != current.findStatus &&
              current.findStatus == HomeStatus.failure),
      listener: (context, state) {
        if (state.status == HomeStatus.scheduled) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ride scheduled successfully!')),
          );
        } else if (state.status == HomeStatus.failure ||
            state.findStatus == HomeStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'Something went wrong')),
          );
        }
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HomeAppBarGreeting(
                      initials: initials,
                      name: displayName,
                      onAvatarTap: () => _logout(context),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: RideModeToggle(
                        selected: state.rideMode,
                        onChanged: (mode) => bloc.add(RideModeChanged(mode)),
                      ),
                    ),
                    const SizedBox(height: 20),
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
                          : state.status == HomeStatus.scheduling,
                      isFormValid: state.isFormValid,
                      onVehicleTypeChanged: (type) =>
                          bloc.add(VehicleTypeChanged(type)),
                      onFromTap: () => _pickLocation(
                        context,
                        title: 'Start location',
                        current: state.fromAddress,
                        onConfirm: (loc) => bloc.add(
                          FromAddressChanged(loc.address, lat: loc.lat, lng: loc.lng),
                        ),
                      ),
                      onToTap: () => _pickLocation(
                        context,
                        title: 'Office location',
                        current: state.toAddress,
                        onConfirm: (loc) => bloc.add(
                          ToAddressChanged(loc.address, lat: loc.lat, lng: loc.lng),
                        ),
                      ),
                      onSwap: () => bloc.add(const LocationsSwapped()),
                      onDateTap: () => _pickDate(context),
                      onTimeTap: () => _pickTime(context),
                      onSeatCountChanged: (count) =>
                          bloc.add(SeatCountChanged(count)),
                      onSchedulePressed: () {
                        if (state.rideMode == RideMode.find) {
                          bloc.add(const FindRidesRequested());
                        } else {
                          bloc.add(const ScheduleRideRequested());
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
                        riderTime: state.selectedTime ?? TimeOfDay.now(),
                        db: _db,
                        onRequested: () => bloc.add(const FindRidesRequested()),
                        onViewAll: () => Navigator.of(context).push(MaterialPageRoute(
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
                          ),
                        )),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
