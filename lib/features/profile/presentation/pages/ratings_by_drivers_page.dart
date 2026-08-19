import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:acepool/di/injection.dart';
import 'package:acepool/features/profile/domain/repositories/ratings_repository.dart';
import 'package:acepool/features/profile/presentation/bloc/reviews_from_drivers_bloc.dart';
import '../widgets/review_from_rider_card.dart';

class RatingsByDriversPage extends StatefulWidget {
  const RatingsByDriversPage({super.key});

  @override
  State<RatingsByDriversPage> createState() => _RatingsByDriversPageState();
}

class _RatingsByDriversPageState extends State<RatingsByDriversPage> {
  late final ReviewsFromDriversBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = ReviewsFromDriversBloc(
      ratingsRepository: sl<RatingsRepository>(),
    )..add(const ReviewsFromDriversStarted());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
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
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              "REVIEWS FROM YOUR DRIVERS",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: BlocProvider.value(
              value: _bloc,
              child: BlocBuilder<ReviewsFromDriversBloc, ReviewsFromDriversState>(
                builder: (context, state) {
                  if (state.status == ReviewsFromDriversStatus.initial ||
                      state.status == ReviewsFromDriversStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.reviews.isEmpty) {
                    return const Center(
                      child: Text("No reviews received yet"),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: state.reviews.length,
                    itemBuilder: (context, index) {
                      final review = state.reviews[index];
                      return ReviewFromRiderCard(
                        riderName: review.driverName,
                        riderPhotoUrl: review.driverPhotoUrl,
                        riderEmployeeId: review.driverEmployeeId,
                        sentiment: review.sentiment,
                        pickup: review.pickup,
                        drop: review.drop,
                        date: review.date,
                        time: review.time,
                        tags: review.tags,
                        comment: review.comment,
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
