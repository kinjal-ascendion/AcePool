import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/core/utils/ride_matcher.dart';
import 'package:acepool/di/injection.dart';
import 'package:acepool/features/rides/presentation/bloc/find_ride_results_bloc.dart';
import 'package:acepool/features/rides/presentation/widgets/ride_result_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FindRideResultsPage extends StatelessWidget {
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
    this.currentLat,
    this.currentLng,
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
  final double? currentLat;
  final double? currentLng;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<FindRideResultsBloc>()
        ..add(FindRideResultsRequested(
          fromAddress: fromAddress,
          toAddress: toAddress,
          fromLat: fromLat,
          fromLng: fromLng,
          toLat: toLat,
          toLng: toLng,
          date: date,
          time: time,
          vehicleType: vehicleType,
          currentLat: currentLat,
          currentLng: currentLng,
        )),
      child: const _FindRideResultsView(),
    );
  }
}

class _FindRideResultsView extends StatelessWidget {
  const _FindRideResultsView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FindRideResultsBloc, FindRideResultsState>(
      builder: (context, state) {
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

                if (state.currentLat != null &&
                    state.currentLng != null &&
                    state.fromLat != null &&
                    state.fromLng != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      'Your pickup point is ${RideMatcher.formatDistance(RideMatcher.distanceKm(
                        state.currentLat!,
                        state.currentLng!,
                        state.fromLat!,
                        state.fromLng!,
                      ))} from your current location',
                      style: TextStyle(fontSize: 12.5, color: AppColors.grey600),
                    ),
                  ),

                // Results list
                Expanded(
                  child: state.status == FindRideResultsStatus.loading ||
                          state.status == FindRideResultsStatus.initial
                      ? const Center(child: CircularProgressIndicator())
                      : state.results.isEmpty
                          ? Center(
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
                            )
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: state.results.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (_, i) => RideResultCard(
                                result: state.results[i],
                                riderFromAddress: state.fromAddress!,
                                riderFromLat: state.fromLat,
                                riderFromLng: state.fromLng,
                                riderToAddress: state.toAddress!,
                                riderToLat: state.toLat,
                                riderToLng: state.toLng,
                                riderTime: state.time!,
                                onRequested: () => context
                                    .read<FindRideResultsBloc>()
                                    .add(const FindRideResultsRefreshed()),
                              ),
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
