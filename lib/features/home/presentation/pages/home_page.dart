import 'package:acepool/di/injection.dart';
import 'package:acepool/features/home/presentation/bloc/home_bloc.dart';
import 'package:acepool/features/home/presentation/widgets/home_app_bar_greeting.dart';
import 'package:acepool/features/home/presentation/widgets/home_bottom_nav_bar.dart';
import 'package:acepool/features/home/presentation/widgets/ride_mode_toggle.dart';
import 'package:acepool/features/home/presentation/widgets/ride_schedule_form.dart';
import 'package:acepool/features/home/presentation/widgets/upcoming_trips_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:acepool/features/profile/presentation/pages/profile_page.dart';

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

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeBloc, HomeState>(
      listenWhen: (previous, current) => current.status == HomeStatus.failure,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.errorMessage ?? 'Something went wrong')),
        );
      },
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          final bloc = context.read<HomeBloc>();
          return Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TODO(auth): replace hardcoded user with real auth/profile data once available
                    const HomeAppBarGreeting(initials: 'K', name: 'Kinjal'),
                    const SizedBox(height: 20),
                    RideModeToggle(
                      selected: state.rideMode,
                      onChanged: (mode) => bloc.add(RideModeChanged(mode)),
                    ),
                    const SizedBox(height: 20),
                    RideScheduleForm(
                      vehicleType: state.vehicleType,
                      fromAddress: state.fromAddress,
                      toAddress: state.toAddress,
                      selectedDate: state.selectedDate,
                      selectedTime: state.selectedTime,
                      seatCount: state.seatCount,
                      onVehicleTypeChanged: (type) =>
                          bloc.add(VehicleTypeChanged(type)),
                      onSwap: () => bloc.add(const LocationsSwapped()),
                      onDateTap: () => _pickDate(context),
                      onTimeTap: () => _pickTime(context),
                      onSeatCountChanged: (count) =>
                          bloc.add(SeatCountChanged(count)),
                      // TODO: wire once a create-ride/booking feature exists
                      onSchedulePressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Coming soon')),
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    UpcomingTripsSection(
                      trips: state.upcomingTrips,
                      // TODO: wire once a full trips-list page exists
                      onViewAll: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Coming soon')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: HomeBottomNavBar(
              currentIndex: 0,
              onTap: (index) {
                if (index == 3) {
                 Navigator.push(
                   context,
                   MaterialPageRoute(
                      builder: (_) => const ProfilePage(),
                    ),
                  );
                } else if (index != 0) {
                   ScaffoldMessenger.of(
                     context,
                    ).showSnackBar(
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
