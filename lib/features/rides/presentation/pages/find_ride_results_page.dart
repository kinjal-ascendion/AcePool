import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/features/rides/domain/entities/ride_match.dart';
import 'package:acepool/features/rides/domain/usecases/find_matching_rides_usecase.dart';
import 'package:acepool/features/rides/presentation/widgets/ride_result_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class FindRideResultsPage extends StatefulWidget {
  const FindRideResultsPage({
    super.key,
    required this.fromAddress,
    required this.toAddress,
    this.fromLat,
    this.fromLng,
    this.toLat,
    this.toLng,
    required this.date,
    required this.time,
    required this.vehicleType,
  });

  final String fromAddress;
  final String toAddress;
  final double? fromLat;
  final double? fromLng;
  final double? toLat;
  final double? toLng;
  final DateTime date;
  final TimeOfDay time;
  final String vehicleType;

  @override
  State<FindRideResultsPage> createState() => _FindRideResultsPageState();
}

class _FindRideResultsPageState extends State<FindRideResultsPage> {
  static final _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'acepool',
  );
  static final _findMatchingRides = FindMatchingRidesUseCase(db: _db);

  late Future<List<RideMatch>> _resultsFuture;

  @override
  void initState() {
    super.initState();
    _resultsFuture = _fetchResults();
  }

  Future<List<RideMatch>> _fetchResults() => _findMatchingRides(
        fromAddress: widget.fromAddress,
        toAddress: widget.toAddress,
        fromLat: widget.fromLat,
        fromLng: widget.fromLng,
        toLat: widget.toLat,
        toLng: widget.toLng,
        date: widget.date,
        time: widget.time,
        vehicleType: widget.vehicleType,
      );

  void _refresh() => setState(() => _resultsFuture = _fetchResults());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Find a Ride',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Upcoming filter chip mirroring Trips page
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.grey300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Upcoming',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down,
                              size: 18, color: AppColors.grey600),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Results list
            Expanded(
              child: FutureBuilder<List<RideMatch>>(
                future: _resultsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }
                  final results = snapshot.data ?? [];
                  if (results.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off,
                              size: 64, color: AppColors.grey300),
                          const SizedBox(height: 16),
                          Text(
                            'No rides available for this date',
                            style: TextStyle(
                                color: AppColors.grey500,
                                fontSize: 15),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding:
                        const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: results.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 14),
                    itemBuilder: (_, i) => RideResultCard(
                      result: results[i],
                      riderFromAddress: widget.fromAddress,
                      riderTime: widget.time,
                      db: _db,
                      onRequested: _refresh,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
