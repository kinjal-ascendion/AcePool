import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:acepool/di/injection.dart';
import 'package:acepool/features/profile/presentation/bloc/ratings_summary_bloc.dart';
import '../widgets/rating_summary_card.dart';
import '../widgets/ride_card.dart';
import 'package:intl/intl.dart';

class RatingsByDriversPage extends StatefulWidget {
  const RatingsByDriversPage({super.key});

  @override
  State<RatingsByDriversPage> createState() => _RatingsByDriversPageState();
}

class _RatingsByDriversPageState extends State<RatingsByDriversPage> {
  late final RatingsSummaryBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = sl<RatingsSummaryBloc>()
      ..add(const RatingsSummaryRequested(RatingsSummarySource.fromDrivers));
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
              "RATINGS BY DRIVERS",
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
              child: BlocBuilder<RatingsSummaryBloc, RatingsSummaryState>(
                builder: (context, state) {
                  if (state.status == RatingsSummaryStatus.initial ||
                      state.status == RatingsSummaryStatus.loading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final summary = state.summary;
                  final rides = summary?.rides ?? [];

                  if (rides.isEmpty) {
                    return const Center(
                      child: Text("No ratings received yet"),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      RatingSummaryCard(
                        averageRating: summary!.averageRating,
                        totalReviews: summary.totalReviews,
                        ratingCounts: summary.ratingCounts,
                      ),

                      const SizedBox(height: 12),

                      ...rides.map(
                        (ride) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: RideCard(
                            date: DateFormat('MMMM d, yyyy').format(ride.date),
                            time: ride.time.format(context),
                            pickup: ride.pickup,
                            drop: ride.drop,
                            rating: ride.rating,
                            reviews: ride.reviews,
                            showReviews: true,
                            showReviewCount: false,
                          ),
                        ),
                      ),
                    ],
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
