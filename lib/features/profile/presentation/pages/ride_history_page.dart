import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/core/utils/date_time_formatter.dart';
import 'package:acepool/di/injection.dart';
import 'package:acepool/features/profile/presentation/bloc/ride_history_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'ride_history_detail_page.dart';

class RideHistoryPage extends StatefulWidget {
  const RideHistoryPage({super.key});

  @override
  State<RideHistoryPage> createState() => _RideHistoryPageState();
}

class _RideHistoryPageState extends State<RideHistoryPage> {
  late final RideHistoryBloc _bloc;
  bool _showAllRides = false;

  @override
  void initState() {
    super.initState();
    _bloc = sl<RideHistoryBloc>()..add(const RideHistoryStarted());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  Map<String, List<Map<String, dynamic>>> _groupRides(
    List<Map<String, dynamic>> rides,
  ) {
    final Map<String, List<Map<String, dynamic>>> groups = {
      'TODAY': [],
      'YESTERDAY': [],
      'THIS MONTH': [],
      'OLDER RIDES': [],
    };

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final firstOfThisMonth = DateTime(now.year, now.month, 1);

    for (var ride in rides) {
      final timestamp = ride['date'] as Timestamp?;
      if (timestamp == null) continue;

      final rideDate = timestamp.toDate();
      final rideDay = DateTime(rideDate.year, rideDate.month, rideDate.day);

      if (rideDay.isAtSameMomentAs(today)) {
        groups['TODAY']!.add(ride);
      } else if (rideDay.isAtSameMomentAs(yesterday)) {
        groups['YESTERDAY']!.add(ride);
      } else if (rideDay.isAfter(
        firstOfThisMonth.subtract(const Duration(seconds: 1)),
      )) {
        groups['THIS MONTH']!.add(ride);
      } else {
        groups['OLDER RIDES']!.add(ride);
      }
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.black, size: 26),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Ride History',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.mulish(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E1E1E),
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: BlocProvider.value(
                value: _bloc,
                child: BlocBuilder<RideHistoryBloc, RideHistoryState>(
                  builder: (context, state) {
                    if (state.status == RideHistoryStatus.initial ||
                        state.status == RideHistoryStatus.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final rides = state.rides;
                    if (rides.isEmpty) {
                      return const Center(child: Text('No completed rides found.'));
                    }

                    final groups = _groupRides(rides);
                    final hasData = groups.values.any((list) => list.isNotEmpty);

                    if (!hasData) {
                      return const Center(child: Text('No completed rides found.'));
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ..._buildGroup('TODAY', groups['TODAY']!),
                            ..._buildGroup('YESTERDAY', groups['YESTERDAY']!),
                            ..._buildGroup('THIS MONTH', groups['THIS MONTH']!),
                            ..._buildGroup('OLDER RIDES', groups['OLDER RIDES']!),
                            if (!_showAllRides)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: TextButton(
                                    onPressed: () => setState(() => _showAllRides = true),
                                    child: Text(
                                      'View All',
                                      style: GoogleFonts.mulish(
                                        color: const Color(0xFF616874),
                                        decoration: TextDecoration.underline,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGroup(String title, List<Map<String, dynamic>> rides) {
    if (rides.isEmpty) return [];

    List<Map<String, dynamic>> displayRides = rides;
    if (!_showAllRides && rides.length > 2) {
      displayRides = rides.take(2).toList();
    }

    return [
      _buildSectionHeader(title),
      ...displayRides.map((ride) {
        final data = ride;
        final isDriver = data['rideMode'] == 'offer';
        final vehicleType = data['vehicleType'] as String? ?? 'car';
        final toAddress = data['toAddress'] as String? ?? 'Unknown Destination';

        final timestamp = data['date'] as Timestamp;
        final rideDate = timestamp.toDate();
        final timeMap = data['time'] as Map<String, dynamic>?;
        final time = TimeOfDay(
          hour: timeMap?['hour'] as int? ?? 0,
          minute: timeMap?['minute'] as int? ?? 0,
        );

        final dateTimeStr =
            '${DateTimeFormatter.monthDayYear(rideDate)} ; ${DateTimeFormatter.time12h(time)}';

        final fareMap = data['fare'] as Map<String, dynamic>?;
        final price = isDriver
            ? (fareMap?['driverEarnings'] ?? fareMap?['totalCost'] ?? 0.0)
            : (fareMap?['farePerSeat'] ?? 0.0);

        final status = data['status'] as String? ?? 'completed';
        final statusLabel = status == 'cancelled' ? 'Cancelled' : 'Completed';
        final priceStatus = '₹ ${price.toStringAsFixed(2)} ; $statusLabel';

        final relativeTime = _getRelativeTimeLabel(rideDate);

        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RideHistoryDetailPage(rideData: ride),
            ),
          ),
          child: _buildRideItem(
            icon: vehicleType.toLowerCase() == 'bike'
                ? Icons.directions_bike_outlined
                : Icons.directions_car_filled_outlined,
            title: toAddress,
            dateTime: dateTimeStr,
            priceStatus: priceStatus,
            relativeTime: relativeTime,
          ),
        );
      }).toList(),
    ];
  }

  String _getRelativeTimeLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rideDay = DateTime(date.year, date.month, date.day);
    final difference = today.difference(rideDay).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return DateTimeFormatter.monthDayYear(date);
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            title,
            style: GoogleFonts.mulish(
              color: const Color(0xFF4C515B),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 15 / 14,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const Divider(
          color: Color(0xFFE0E0E0),
          height: 1,
          indent: 16,
          endIndent: 16,
        ),
      ],
    );
  }

  Widget _buildRideItem({
    required IconData icon,
    required String title,
    required String dateTime,
    required String priceStatus,
    required String relativeTime,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF1E1E1E), size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.mulish(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: const Color(0xFF1E1E1E),
                          height: 1.0,
                          letterSpacing: -0.32, // -2% of 16
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      relativeTime,
                      style: GoogleFonts.mulish(
                        color: const Color(0xFF616874),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  dateTime,
                  style: GoogleFonts.mulish(
                    color: const Color(0xFF616874),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.0,
                    letterSpacing: 0.256, // 1.6% of 16
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      priceStatus,
                      style: GoogleFonts.mulish(
                        color: const Color(0xFF616874),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1.0,
                        letterSpacing: 0.256, // 1.6% of 16
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF1E1E1E),
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
