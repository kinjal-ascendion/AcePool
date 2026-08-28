import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:acepool/di/injection.dart';
import 'package:acepool/features/profile/presentation/bloc/ratings_by_you_bloc.dart';
import '../widgets/ride_review_card.dart';
import 'package:intl/intl.dart';
import 'review_drivers_page.dart';

class RatingsByYouPage extends StatefulWidget {
  const RatingsByYouPage({super.key});

  @override
  State<RatingsByYouPage> createState() => _RatingsByYouPageState();
}

class _RatingsByYouPageState extends State<RatingsByYouPage> {
  late final RatingsByYouBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = sl<RatingsByYouBloc>()..add(const RatingsByYouStarted());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    if (isToday) return 'Today';
    return DateFormat('EEE d MMM').format(date);
  }

  String _formatTime(TimeOfDay time) {
    return DateFormat('h.mm a')
        .format(DateTime(2000, 1, 1, time.hour, time.minute))
        .toLowerCase();
  }

  Widget _sectionHeader(String title, String status) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.mulish(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: const Color(0xFF1E1E1E),
            ),
          ),
          Text(
            status.toUpperCase(),
            style: GoogleFonts.mulish(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: const Color(0xFF8A8A8A),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Ride statistics",
          style: GoogleFonts.mulish(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 24,
            height: 1.0,
          ),
        ),
      ),
      body: BlocProvider.value(
        value: _bloc,
        child: BlocBuilder<RatingsByYouBloc, RatingsByYouState>(
          builder: (context, state) {
            if (state.status == RatingsByYouStatus.initial ||
                state.status == RatingsByYouStatus.loading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final rides = state.rides;

            if (rides.isEmpty) {
              return const Center(
                child: Text("No completed rides found"),
              );
            }

            final pending = rides.where((r) => r.riderRating == null).toList();
            final done = rides.where((r) => r.riderRating != null).toList();

            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                if (pending.isNotEmpty) ...[
                  _sectionHeader("REVIEWS BY YOU", "PENDING"),
                  ...pending.map((ride) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: RideReviewCard(
                          riderNames: [
                            ride.driverName.isNotEmpty ? ride.driverName : 'Driver'
                          ],
                          riderPhotoUrls: [ride.driverPhotoUrl],
                          passengerCount: 0,
                          vehicleInfo: ride.vehicleInfo,
                          dateTimeText:
                              '${_formatDate(ride.date)} . ${_formatTime(ride.time)}',
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReviewDriversPage(
                                  rideId: ride.rideId,
                                ),
                              ),
                            );
                            if (mounted) {
                              _bloc.add(const RatingsByYouStarted());
                            }
                          },
                        ),
                      )),
                ],
                if (done.isNotEmpty) ...[
                  _sectionHeader("REVIEWS BY YOU", "DONE"),
                  ...done.map((ride) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: RideReviewCard(
                          riderNames: [
                            ride.driverName.isNotEmpty ? ride.driverName : 'Driver'
                          ],
                          riderPhotoUrls: [ride.driverPhotoUrl],
                          passengerCount: 0,
                          vehicleInfo: ride.vehicleInfo,
                          dateTimeText:
                              '${_formatDate(ride.date)} . ${_formatTime(ride.time)}',
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReviewDriversPage(
                                  rideId: ride.rideId,
                                ),
                              ),
                            );
                            if (mounted) {
                              _bloc.add(const RatingsByYouStarted());
                            }
                          },
                        ),
                      )),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
