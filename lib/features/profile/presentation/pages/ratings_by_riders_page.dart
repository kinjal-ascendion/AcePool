import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:acepool/di/injection.dart';
import 'package:acepool/features/profile/domain/repositories/ratings_repository.dart';
import 'package:acepool/features/profile/presentation/bloc/reviews_from_riders_bloc.dart';
import '../widgets/review_from_rider_card.dart';

class RatingsByRidersPage extends StatefulWidget {
  const RatingsByRidersPage({super.key});

  @override
  State<RatingsByRidersPage> createState() => _RatingsByRidersPageState();
}

class _RatingsByRidersPageState extends State<RatingsByRidersPage> {
  late final ReviewsFromRidersBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = ReviewsFromRidersBloc(
      ratingsRepository: sl<RatingsRepository>(),
    )..add(const ReviewsFromRidersStarted());
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
              "REVIEWS FROM YOUR RIDERS",
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
              child: BlocBuilder<ReviewsFromRidersBloc, ReviewsFromRidersState>(
                builder: (context, state) {
                  if (state.status == ReviewsFromRidersStatus.initial ||
                      state.status == ReviewsFromRidersStatus.loading) {
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
                        riderName: review.riderName,
                        riderPhotoUrl: review.riderPhotoUrl,
                        riderEmployeeId: review.riderEmployeeId,
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
