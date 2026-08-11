import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:acepool/di/injection.dart';
import 'package:acepool/features/profile/presentation/bloc/ratings_by_you_bloc.dart';
import '../widgets/ride_card.dart';
import 'package:intl/intl.dart';
import '../widgets/rating_panel.dart';

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
              child: BlocConsumer<RatingsByYouBloc, RatingsByYouState>(
                listener: (context, state) {
                  if (state.errorMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.errorMessage!)),
                    );
                  }
                },
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

                      return Column(
                        children: [
                          RideCard(
                            date: DateFormat('MMMM d, yyyy').format(ride.date),
                            time: ride.time.format(context),
                            pickup: ride.pickup,
                            drop: ride.drop,
                            rating: (ride.riderRating ?? 0).toDouble(),
                            reviews: 0,
                            showReviews: false,
                            trailing: ride.riderRating == null
                                ? ElevatedButton.icon(
                                    onPressed: () {
                                      _bloc.add(RatingsByYouExpandToggled(ride.requestId));
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
                                      "Review your Driver",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  )
                                : null,
                          ),

                          if (state.expandedRequestId == ride.requestId)
                            RatingPanel(
                              selectedRating: state.selectedRating,
                              onRatingChanged: (rating) {
                                _bloc.add(RatingsByYouStarSelected(rating));
                              },
                              onSubmit: () {
                                _bloc.add(RatingsByYouSubmitted(ride.requestId));
                              },
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
