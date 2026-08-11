import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:acepool/di/injection.dart';
import 'package:acepool/features/profile/presentation/bloc/review_your_riders_bloc.dart';
import '../widgets/ride_card.dart';
import 'package:intl/intl.dart';
import 'review_riders_page.dart';

class ReviewYourRidersPage extends StatefulWidget {
  const ReviewYourRidersPage({super.key});

  @override
  State<ReviewYourRidersPage> createState() => _ReviewYourRidersPageState();
}

class _ReviewYourRidersPageState extends State<ReviewYourRidersPage> {
  late final ReviewYourRidersBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = sl<ReviewYourRidersBloc>()..add(const ReviewYourRidersStarted());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
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
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              "RATINGS BY YOU",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
          ),

          Expanded(
            child: BlocProvider.value(
              value: _bloc,
              child: BlocBuilder<ReviewYourRidersBloc, ReviewYourRidersState>(
                builder: (context, state) {
                  if (state.status == ReviewYourRidersStatus.initial ||
                      state.status == ReviewYourRidersStatus.loading) {
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

                      return Column(
                        children: [
                          RideCard(
                            date: DateFormat('MMMM d, yyyy').format(ride.date),
                            time: ride.time.format(context),
                            pickup: ride.pickup,
                            drop: ride.drop,
                            rating: (ride.driverRating ?? 0).toDouble(),
                            reviews: 0,
                            showReviews: false,
                            trailing: ride.ratedRiders == 0
                                ? ElevatedButton.icon(
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ReviewRidersPage(
                                            rideId: ride.rideId,
                                          ),
                                        ),
                                      );

                                      _bloc.add(const ReviewYourRidersStarted());
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.add,
                                      size: 14,
                                    ),
                                    label: const Text(
                                      "Review your Riders",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  )
                                : InkWell(
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ReviewRidersPage(
                                            rideId: ride.rideId,
                                          ),
                                        ),
                                      );

                                      _bloc.add(const ReviewYourRidersStarted());
                                    },
                                    child: Text(
                                      "${ride.ratedRiders}/${ride.totalRiders} reviews added",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                          ),

                          const SizedBox(height: 16),
                        ],
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
