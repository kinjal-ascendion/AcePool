import 'package:google_fonts/google_fonts.dart';
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              "REVIEWS BY DRIVERS",
              style: GoogleFonts.mulish(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: const Color(0xFF1E1E1E),
                height: 15 / 14,
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
                        vehicleInfo: review.vehicleInfo,
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
