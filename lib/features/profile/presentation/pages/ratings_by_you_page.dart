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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Ride statistics",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              "FEEDBACK BY YOU",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: BlocProvider.value(
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

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: rides.length,
                    itemBuilder: (context, index) {
                      final ride = rides[index];

                      return RideReviewCard(
                        riderNames: [ride.driverName.isNotEmpty ? ride.driverName : 'Driver'],
                        riderPhotoUrls: [ride.driverPhotoUrl],
                        passengerCount: 0,
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
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
