import 'package:acepool/di/injection.dart';
import 'package:acepool/features/home/presentation/bloc/home_bloc.dart';
import 'package:acepool/features/home/presentation/pages/location_search_page.dart';
import 'package:acepool/features/home/presentation/widgets/home_app_bar_greeting.dart';
import 'package:acepool/features/home/presentation/widgets/home_bottom_nav_bar.dart';
import 'package:acepool/features/home/presentation/widgets/ride_mode_toggle.dart';
import 'package:acepool/features/home/presentation/widgets/ride_schedule_form.dart';
import 'package:acepool/features/home/presentation/widgets/upcoming_trips_section.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<HomeBloc>()..add(const HomeStarted()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

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
    required void Function(String) onConfirm,
  }) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => LocationSearchPage(
          title: title,
          initialValue: current,
        ),
      ),
    );
    if (result != null && result.isNotEmpty) {
      onConfirm(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeBloc, HomeState>(
      listenWhen: (previous, current) =>
          current.status == HomeStatus.failure ||
          current.status == HomeStatus.scheduled,
      listener: (context, state) {
        if (state.status == HomeStatus.scheduled) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ride scheduled successfully!')),
          );
        } else if (state.status == HomeStatus.failure) {
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
            backgroundColor: const Color(0xFFF5F5F5),
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
                      vehicleType: state.vehicleType,
                      fromAddress: state.fromAddress,
                      toAddress: state.toAddress,
                      selectedDate: state.selectedDate,
                      selectedTime: state.selectedTime,
                      seatCount: state.seatCount,
                      isScheduling: state.status == HomeStatus.scheduling,
                      isFormValid: state.isFormValid,
                      onVehicleTypeChanged: (type) =>
                          bloc.add(VehicleTypeChanged(type)),
                      onFromTap: () => _pickLocation(
                        context,
                        title: 'Start location',
                        current: state.fromAddress,
                        onConfirm: (v) => bloc.add(FromAddressChanged(v)),
                      ),
                      onToTap: () => _pickLocation(
                        context,
                        title: 'Office location',
                        current: state.toAddress,
                        onConfirm: (v) => bloc.add(ToAddressChanged(v)),
                      ),
                      onSwap: () => bloc.add(const LocationsSwapped()),
                      onDateTap: () => _pickDate(context),
                      onTimeTap: () => _pickTime(context),
                      onSeatCountChanged: (count) =>
                          bloc.add(SeatCountChanged(count)),
                      onSchedulePressed: () =>
                          bloc.add(const ScheduleRideRequested()),
                    ),
                    const SizedBox(height: 28),
                    UpcomingTripsSection(
                      trips: state.upcomingTrips,
                      isLoading: state.status == HomeStatus.loading,
                      onViewAll: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Coming soon')),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: HomeBottomNavBar(
              currentIndex: 0,
              onTap: (index) {
                if (index != 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Coming soon')),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}
