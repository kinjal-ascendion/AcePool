import 'package:acepool/di/injection.dart';
import 'package:acepool/features/profile/presentation/bloc/review_riders_bloc.dart';
import 'package:acepool/features/profile/presentation/pages/all_done_page.dart';
import 'package:acepool/features/profile/presentation/widgets/passenger_review_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class ReviewRidersPage extends StatefulWidget {
  final String rideId;

  const ReviewRidersPage({
    super.key,
    required this.rideId,
  });

  @override
  State<ReviewRidersPage> createState() => _ReviewRidersPageState();
}

class _ReviewRidersPageState extends State<ReviewRidersPage> {
  late final ReviewRidersBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = sl<ReviewRidersBloc>()..add(ReviewRidersStarted(widget.rideId));
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
        child: BlocConsumer<ReviewRidersBloc, ReviewRidersState>(
          listenWhen: (previous, current) =>
              !previous.completed && current.completed,
          listener: (context, state) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => AllDonePage(passengerCount: state.riders.length),
              ),
            );
          },
          builder: (context, state) {
            if (state.status == ReviewRidersStatus.initial ||
                state.status == ReviewRidersStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.riders.isEmpty) {
              return const Center(child: Text('No riders found'));
            }

            final rider = state.currentRider!;
            final isRated = rider.driverRating != null;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'REVIEW YOUR RIDERS',
                    style: GoogleFonts.mulish(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: const Color(0xFF1E1E1E),
                      height: 15 / 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ProgressBar(
                    total: state.riders.length,
                    filled: state.currentIndex + 1,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'PASSENGER ${state.currentIndex + 1} OF ${state.riders.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                      color: Color(0xFF8A8A8A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  PassengerReviewCard(
                    key: ValueKey(rider.requestId),
                    riderName: rider.riderName,
                    employeeId: rider.employeeId,
                    riderPhotoUrl: rider.riderPhotoUrl,
                    pickupPoint: rider.pickupPoint,
                    dropOffPoint: rider.dropOffPoint,
                    vehicleInfo: rider.vehicleInfo,
                    selectedEmoji: state.selectedEmoji,
                    selectedTags: state.selectedTags,
                    comment: state.comment,
                    isRated: isRated,
                    isSubmitting: state.isSubmitting,
                    onEmojiSelected: (rating) =>
                        _bloc.add(ReviewRidersEmojiSelected(rating)),
                    onTagToggled: (tag) =>
                        _bloc.add(ReviewRidersTagToggled(tag)),
                    onCommentChanged: (text) =>
                        _bloc.add(ReviewRidersCommentChanged(text)),
                    onSubmit: () => _bloc.add(const ReviewRidersSubmitted()),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _bloc.add(const ReviewRidersSkipped()),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'Skip',
                          style: GoogleFonts.mulish(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF616874),
                            height: 21 / 16,
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

class _ProgressBar extends StatelessWidget {
  final int total;
  final int filled;

  const _ProgressBar({required this.total, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (index) {
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index == total - 1 ? 0 : 5),
            decoration: BoxDecoration(
              color: index < filled
                  ? const Color(0xFF1A1A1A)
                  : const Color(0xFFE5E5E5),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}
