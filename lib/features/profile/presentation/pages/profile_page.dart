import 'package:acepool/core/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'account_settings_page.dart';
import 'addresses_page.dart';
import 'vehicle_info_page.dart';
import 'ride_statistics_page.dart';
import 'route_matching_page.dart';
import 'package:acepool/core/enums/ride_mode.dart';
import 'ride_history_page.dart';
import 'payment_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static final _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'acepool',
  );

  late Future<Map<String, dynamic>?> _userDataFuture;
  RideMode _selectedMode = RideMode.takeRide;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _fetchUserData();
  }

  Future<Map<String, dynamic>?> _fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: AppColors.grey600, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.grey400),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _userDataFuture,
          builder: (context, snapshot) {
            final data = snapshot.data;
            final fullName = data?['fullName'] as String? ?? '';
            final employeeId = data?['employeeId'] as String? ?? '';
            final phone = data?['phone'] as String?;
            final licenceVerified = data?['licenceVerified'] as bool?;
            final licenceNumber = data?['licenceNumber'] as String?;

            final initials = fullName.trim().isNotEmpty
                ? fullName
                    .trim()
                    .split(' ')
                    .where((w) => w.isNotEmpty)
                    .take(2)
                    .map((w) => w[0].toUpperCase())
                    .join()
                : '?';

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                const Text(
  'Profile',
  textAlign: TextAlign.center,
  style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
  ),
),

const SizedBox(height: 20),
Center(
  child: Container(
    height: 48,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.grey300),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _modeButton(
          title: "Take Ride",
          selected: _selectedMode == RideMode.takeRide,
          onTap: () {
            setState(() {
              _selectedMode = RideMode.takeRide;
            });
          },
        ),

        _modeButton(
          title: "Offer Ride",
          selected: _selectedMode == RideMode.offerRide,
          onTap: () {
            setState(() {
              _selectedMode = RideMode.offerRide;
            });
          },
        ),
      ],
    ),
  ),
),

const SizedBox(height: 24),
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
                      ).then((_) {
                    if (mounted) {
                      setState(() {
                        _userDataFuture = _fetchUserData();
                      });
                    }
                  }),
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
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            employeeId.isNotEmpty ? employeeId : '—',
                            style: TextStyle(
                              color: AppColors.grey600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Divider(color: AppColors.grey200, height: 1),
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
                  ).then((_) {
                    if (mounted) {
                      setState(() {
                        _userDataFuture = _fetchUserData();
                      });
                    }
                  }),
                ),
                Divider(color: AppColors.grey200, height: 1),
                _settingsRow(
                  title: 'Vehicle info',
                  subtitle: 'Add/ Edit vehicle details',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VehicleInfoPage()),
                  ),
                ),
                Divider(color: AppColors.grey200, height: 1),
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
                Divider(color: AppColors.grey200, height: 1),
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
                Divider(color: AppColors.grey200, height: 1),
                _settingsRow(
                  title: 'Pricing',
                  subtitle: 'Set the fare price',
                ),
                Divider(color: AppColors.grey200, height: 1),


if (_selectedMode == RideMode.offerRide) ...[
  _settingsRow(
    title: 'Payment',
    subtitle: 'UPI & Cash payment preferences',
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PaymentPage(),
      ),
    ),
  ),
  Divider(color: AppColors.grey200, height: 1),
],


                _settingsRow(
                  title: 'Addresses',
                  subtitle: 'Home, Office address',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddressesPage()),
                  ),
                ),
                Divider(color: AppColors.grey200, height: 1),
               _settingsRow(
  title: 'Ride statistics',
  subtitle: 'Ratings, Reviews & more',
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => RideStatisticsPage(
        mode: _selectedMode,
      ),
    ),
  ),
),
                Divider(color: AppColors.grey200, height: 1),
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
    );
  }
  Widget _modeButton({
  required String title,
  required bool selected,
  required VoidCallback onTap,
}) {
  return InkWell(
    borderRadius: BorderRadius.circular(24),
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: 150,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? AppColors.black87 : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: selected ? Colors.white : AppColors.black87,
        ),
      ),
    ),
  );
}
}
