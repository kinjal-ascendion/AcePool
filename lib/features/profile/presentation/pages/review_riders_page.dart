import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:acepool/di/injection.dart';
import 'package:acepool/features/profile/presentation/bloc/review_riders_bloc.dart';
import '../widgets/rider_rating_card.dart';

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
        title: const Text("Review Riders"),
      ),
      body: BlocProvider.value(
        value: _bloc,
        child: BlocBuilder<ReviewRidersBloc, ReviewRidersState>(
          builder: (context, state) {
            if (state.status == ReviewRidersStatus.initial ||
                state.status == ReviewRidersStatus.loading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state.riders.isEmpty) {
              return const Center(
                child: Text("No riders found"),
              );
            }

            final riders = state.riders;

            return ListView.builder(
              itemCount: riders.length,
              itemBuilder: (context, index) {
                final rider = riders[index];

                return RiderRatingCard(
                  riderName: rider.riderName,
                  employeeId: rider.employeeId,
                  pickupPoint: rider.pickupPoint,
                  dropOffPoint: rider.dropOffPoint,
                  driverRating: rider.driverRating,
                  selectedRating: state.selectedRatings[rider.requestId] ?? 0,
                  onRatingChanged: (rating) {
                    _bloc.add(ReviewRidersStarSelected(
                      requestId: rider.requestId,
                      rating: rating,
                    ));
                  },
                  onSubmit: () {
                    _bloc.add(ReviewRidersSubmitted(rider.requestId));
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
