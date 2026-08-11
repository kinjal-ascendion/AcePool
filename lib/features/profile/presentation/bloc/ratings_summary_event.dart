part of 'ratings_summary_bloc.dart';

enum RatingsSummarySource { fromDrivers, fromRiders }

abstract class RatingsSummaryEvent extends Equatable {
  const RatingsSummaryEvent();

  @override
  List<Object?> get props => [];
}

class RatingsSummaryRequested extends RatingsSummaryEvent {
  const RatingsSummaryRequested(this.source);

  final RatingsSummarySource source;

  @override
  List<Object?> get props => [source];
}
