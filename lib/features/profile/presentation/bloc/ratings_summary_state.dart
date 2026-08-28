part of 'ratings_summary_bloc.dart';

enum RatingsSummaryStatus { initial, loading, loaded }

class RatingsSummaryState extends Equatable {
  const RatingsSummaryState({
    this.status = RatingsSummaryStatus.initial,
    this.summary,
  });

  final RatingsSummaryStatus status;
  final RatingsSummary? summary;

  RatingsSummaryState copyWith({
    RatingsSummaryStatus? status,
    RatingsSummary? summary,
  }) {
    return RatingsSummaryState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
    );
  }

  @override
  List<Object?> get props => [status, summary];
}
