import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/di/injection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:acepool/features/profile/domain/repositories/profile_repository.dart';
import 'package:acepool/features/profile/presentation/bloc/profile_bloc.dart';
import 'account_settings_page.dart';
import 'package:acepool/features/address/presentation/pages/addresses_page.dart';
import 'vehicle_info_page.dart';
import 'ride_statistics_page.dart';
import 'route_matching_page.dart';
import 'package:acepool/core/enums/ride_mode.dart';
import 'ride_history_page.dart';
import 'payment_page.dart';
import 'package:acepool/features/rides/presentation/pages/security_page.dart';
import 'package:acepool/features/profile/presentation/widgets/roles_section.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  RideMode _selectedMode = RideMode.takeRide;

  Future<void> _logout(BuildContext context) async {
    await sl<ProfileRepository>().logout();
    if (context.mounted) context.go('/login');
  }

  Widget _settingsRow({
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                      height: 1.1, // Adjusted for 20px
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.subheadingGrey,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.285, // 18px / 14px
                    ),
                  ),
                ],
              ),
            ),
            Image.asset(
              'assets/images/next.png',
              width: 9,
              height: 18,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('User not logged in')));
    }

    return BlocProvider(
      create: (_) => sl<ProfileBloc>()..add(const ProfileStarted()),
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              if (state.status != ProfileStatus.loaded && state.summary == null) {
                return const Center(child: CircularProgressIndicator());
              }
              final summary = state.summary!;
              final fullName = summary.fullName;
              final employeeId = summary.employeeId;
              final ridesCompleted = summary.ridesCompleted;
              final phone = summary.phone;
              final licenceVerified = summary.licenceVerified;
              final licenceNumber = summary.licenceNumber;
              final travelPreference = summary.travelPreference;
              final isDriver = summary.isDriver;
              final initials = summary.initials;

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                children: [
                  const Text(
                    'Profile',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AccountSettingsPage(
                              fullName: fullName,
                              employeeId: employeeId,
                              phone: phone,
                              licenceVerified: licenceVerified,
                              licenceNumber: licenceNumber,
                            ),
                          ),
                        ),
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: AppColors.black87,
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.grey400,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 12,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName.isNotEmpty ? fullName : '—',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              employeeId.isNotEmpty ? employeeId : '—',
                              style: const TextStyle(
                                color: AppColors.subheadingGrey,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.285,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$ridesCompleted rides completed',
                              style: const TextStyle(
                                color: AppColors.subheadingGrey,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.285,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  RolesSection(
                    isRider: summary.isRider,
                    isDriver: summary.isDriver,
                    currentPreference: travelPreference,
                  ),
                  const SizedBox(height: 8),
                  Divider(color: AppColors.dividerGrey, height: 1),
                  _settingsRow(
                    title: 'Account settings',
                    subtitle: 'Name, Contact, Asc id, License, Role',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AccountSettingsPage(
                          fullName: fullName,
                          employeeId: employeeId,
                          phone: phone,
                          licenceVerified: licenceVerified,
                          licenceNumber: licenceNumber,
                        ),
                      ),
                    ),
                  ),
                  Divider(color: AppColors.dividerGrey, height: 1),
                  _settingsRow(
                    title: 'Vehicle info',
                    subtitle: 'Add/ Edit vehicle details',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VehicleInfoPage()),
                    ),
                  ),
                  Divider(color: AppColors.dividerGrey, height: 1),
                  _settingsRow(
                    title: 'Route matching',
                    subtitle: 'Routes & Radius settings',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RouteMatchingPage(),
                      ),
                    ),
                  ),
                  Divider(color: AppColors.dividerGrey, height: 1),
                  _settingsRow(
                    title: 'Ride History',
                    subtitle: 'Past Rides & Receipts',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RideHistoryPage(),
                      ),
                    ),
                  ),
                  Divider(color: AppColors.dividerGrey, height: 1),
                  if (isDriver) ...[
                    _settingsRow(
                      title: 'Payment',
                      subtitle: 'Payment methods',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PaymentPage(),
                        ),
                      ),
                    ),
                    Divider(color: AppColors.dividerGrey, height: 1),
                  ],
                  _settingsRow(
                    title: 'Addresses',
                    subtitle: 'Home, Office address',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddressesPage()),
                    ),
                  ),
                  Divider(color: AppColors.dividerGrey, height: 1),
                  _settingsRow(
                    title: 'Ride statistics',
                    subtitle: 'Ratings, Reviews & more',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RideStatisticsPage(
                          mode: _selectedMode,
                          travelPreference: travelPreference,
                        ),
                      ),
                    ),
                  ),
                  Divider(color: AppColors.dividerGrey, height: 1),
                  _settingsRow(
                    title: 'Security',
                    subtitle: 'Emergency contact details',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SecurityPage(),
                      ),
                    ),
                  ),
                  Divider(color: AppColors.dividerGrey, height: 1),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () => _logout(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: AppColors.red, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Log out',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'T&C apply',
                    style: TextStyle(color: AppColors.grey500, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
