import 'package:acepool/features/home/domain/entities/upcoming_trip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  UpcomingTrip buildTrip({String status = 'upcoming'}) {
    return UpcomingTrip(
      id: 'trip-1',
      date: DateTime(2026, 8, 12),
      time: const TimeOfDay(hour: 14, minute: 30),
      fromAddress: 'Home',
      toAddress: 'Office',
      fromLat: 1.1,
      fromLng: 2.2,
      toLat: 3.3,
      toLng: 4.4,
      seatsFilled: 2,
      seatsTotal: 4,
      farePerSeat: 50,
      note: 'Some note',
      durationMinutes: 30,
      status: status,
    );
  }

  group('UpcomingTrip', () {
    test('required fields with default seatsFilled/status', () {
      final trip = UpcomingTrip(
        id: 'trip-2',
        date: DateTime(2026, 1, 1),
        time: const TimeOfDay(hour: 9, minute: 0),
        fromAddress: 'A',
        toAddress: 'B',
        seatsFilled: 0,
        seatsTotal: 4,
      );

      expect(trip.status, 'upcoming');
      expect(trip.fromLat, isNull);
      expect(trip.farePerSeat, isNull);
      expect(trip.note, isNull);
      expect(trip.durationMinutes, isNull);
    });

    test('copyWith overrides status and keeps other fields', () {
      final trip = buildTrip();

      final updated = trip.copyWith(status: 'cancelled');

      expect(updated.status, 'cancelled');
      expect(updated.id, trip.id);
      expect(updated.date, trip.date);
      expect(updated.time, trip.time);
      expect(updated.fromAddress, trip.fromAddress);
      expect(updated.toAddress, trip.toAddress);
      expect(updated.fromLat, trip.fromLat);
      expect(updated.seatsFilled, trip.seatsFilled);
      expect(updated.seatsTotal, trip.seatsTotal);
      expect(updated.farePerSeat, trip.farePerSeat);
      expect(updated.note, trip.note);
      expect(updated.durationMinutes, trip.durationMinutes);
    });

    test('copyWith with no status keeps existing status', () {
      final trip = buildTrip(status: 'upcoming');

      final updated = trip.copyWith();

      expect(updated.status, 'upcoming');
    });

    test('dateLabel formats using DateTimeFormatter', () {
      final trip = buildTrip();

      expect(trip.dateLabel, contains('2026'));
      expect(trip.dateLabel, startsWith('August 12, 2026'));
    });

    test('timeLabel formats using DateTimeFormatter (12h with AM/PM)', () {
      final trip = buildTrip();

      expect(trip.timeLabel, '2:30 PM');
    });

    test('timeLabel formats midnight boundary as 12:00 AM', () {
      final midnightTrip = UpcomingTrip(
        id: 'trip-3',
        date: DateTime(2026, 8, 12),
        time: const TimeOfDay(hour: 0, minute: 0),
        fromAddress: 'A',
        toAddress: 'B',
        seatsFilled: 0,
        seatsTotal: 1,
      );

      expect(midnightTrip.timeLabel, '12:00 AM');
    });

    test('supports value equality', () {
      final a = buildTrip();
      final b = buildTrip();

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('differs when status differs', () {
      final a = buildTrip(status: 'upcoming');
      final b = buildTrip(status: 'completed');

      expect(a, isNot(b));
    });
  });
}
