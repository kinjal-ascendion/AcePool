part of 'ratings_by_you_bloc.dart';

enum RatingsByYouStatus { initial, loading, loaded }

const _unset = Object();

class RatingsByYouState extends Equatable {
  const RatingsByYouState({
    this.status = RatingsByYouStatus.initial,
    this.rides = const [],
    this.expandedRequestId,
    this.selectedRating = 0,
    this.errorMessage,
  });

  final RatingsByYouStatus status;
  final List<RiderRatableRide> rides;
  final String? expandedRequestId;
  final int selectedRating;
  final String? errorMessage;

  RatingsByYouState copyWith({
    RatingsByYouStatus? status,
    List<RiderRatableRide>? rides,
    Object? expandedRequestId = _unset,
    bool clearExpandedRequestId = false,
    int? selectedRating,
    String? errorMessage,
  }) {
    return RatingsByYouState(
      status: status ?? this.status,
      rides: rides ?? this.rides,
      expandedRequestId: clearExpandedRequestId
          ? null
          : (expandedRequestId == _unset ? this.expandedRequestId : expandedRequestId as String?),
      selectedRating: selectedRating ?? this.selectedRating,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, rides, expandedRequestId, selectedRating, errorMessage];
}
