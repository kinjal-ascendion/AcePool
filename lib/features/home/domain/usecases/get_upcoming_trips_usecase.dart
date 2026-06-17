import 'package:flutter/material.dart';
import 'package:acepool/features/home/domain/entities/upcoming_trip.dart';

class GetUpcomingTripsUseCase {
  Future<List<UpcomingTrip>> call() async {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final dayAfter = now.add(const Duration(days: 2));

    return [
      UpcomingTrip(
        id: '1',
        date: DateTime(tomorrow.year, tomorrow.month, tomorrow.day),
        time: const TimeOfDay(hour: 9, minute: 30),
        fromAddress: 'Green park apartments',
        toAddress: 'Prestige blue chip, koramangala',
        seatsFilled: 2,
        seatsTotal: 3,
      ),
      UpcomingTrip(
        id: '2',
        date: DateTime(dayAfter.year, dayAfter.month, dayAfter.day),
        time: const TimeOfDay(hour: 18, minute: 0),
        fromAddress: 'Prestige blue chip, koramangala',
        toAddress: 'Green park apartments',
        seatsFilled: 1,
        seatsTotal: 3,
      ),
    ];
  }
}
