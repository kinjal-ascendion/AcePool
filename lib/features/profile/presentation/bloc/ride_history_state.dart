part of 'ride_history_bloc.dart';

enum RideHistoryStatus { initial, loading, loaded }

class RideHistoryState extends Equatable {
  const RideHistoryState({
    this.status = RideHistoryStatus.initial,
    this.rides = const [],
  });

  final RideHistoryStatus status;
  final List<Map<String, dynamic>> rides;

  RideHistoryState copyWith({
    RideHistoryStatus? status,
    List<Map<String, dynamic>>? rides,
  }) {
    return RideHistoryState(
      status: status ?? this.status,
      rides: rides ?? this.rides,
    );
  }

  @override
  List<Object?> get props => [status, rides];
}
