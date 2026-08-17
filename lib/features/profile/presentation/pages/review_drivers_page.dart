import 'package:acepool/di/injection.dart';
import 'package:acepool/features/profile/domain/repositories/ratings_repository.dart';
import 'package:acepool/features/profile/presentation/bloc/review_drivers_bloc.dart';
import 'package:acepool/features/profile/presentation/pages/all_done_page.dart';
import 'package:acepool/features/profile/presentation/widgets/passenger_review_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReviewDriversPage extends StatefulWidget {
  final String rideId;

  const ReviewDriversPage({
    super.key,
    required this.rideId,
  });

  @override
  State<ReviewDriversPage> createState() => _ReviewDriversPageState();
}

class _ReviewDriversPageState extends State<ReviewDriversPage> {
  late final ReviewDriversBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = ReviewDriversBloc(
      ratingsRepository: sl<RatingsRepository>(),
    )..add(ReviewDriversStarted(widget.rideId));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Ride statistics',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ),
      body: BlocProvider.value(
        value: _bloc,
        child: BlocConsumer<ReviewDriversBloc, ReviewDriversState>(
          listenWhen: (previous, current) =>
              !previous.completed && current.completed,
          listener: (context, state) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => AllDonePage(
                  passengerCount: state.drivers.length,
                  message: 'Feedback submitted for the driver.',
                ),
              ),
            );
          },
          builder: (context, state) {
            if (state.status == ReviewDriversStatus.initial ||
                state.status == ReviewDriversStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.drivers.isEmpty) {
              return const Center(child: Text('No drivers found'));
            }

            final driver = state.currentDriver!;
            final isRated = driver.riderRating != null;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'REVIEW YOUR DRIVER',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  PassengerReviewCard(
                    key: ValueKey(driver.requestId),
                    riderName: driver.driverName,
                    employeeId: driver.employeeId,
                    riderPhotoUrl: driver.driverPhotoUrl,
                    pickupPoint: driver.pickupPoint,
                    dropOffPoint: driver.dropOffPoint,
                    selectedEmoji: state.selectedEmoji,
                    selectedTags: state.selectedTags,
                    comment: state.comment,
                    isRated: isRated,
                    isSubmitting: state.isSubmitting,
                    isDriverReview: true,
                    onEmojiSelected: (rating) =>
                        _bloc.add(ReviewDriversEmojiSelected(rating)),
                    onTagToggled: (tag) =>
                        _bloc.add(ReviewDriversTagToggled(tag)),
                    onCommentChanged: (text) =>
                        _bloc.add(ReviewDriversCommentChanged(text)),
                    onSubmit: () => _bloc.add(const ReviewDriversSubmitted()),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _bloc.add(const ReviewDriversSkipped()),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF8A8A8A),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}


