import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:acepool/core/utils/date_time_formatter.dart';

class UpcomingTrip extends Equatable {
  final String id;
  final DateTime date;
  final TimeOfDay time;
  final String fromAddress;
  final String toAddress;
  final double? fromLat;
  final double? fromLng;
  final double? toLat;
  final double? toLng;
  final int seatsFilled;
  final int seatsTotal;
  final double? farePerSeat;
  final String? note;
  final int? durationMinutes;

  const UpcomingTrip({
    required this.id,
    required this.date,
    required this.time,
    required this.fromAddress,
    required this.toAddress,
    this.fromLat,
    this.fromLng,
    this.toLat,
    this.toLng,
    required this.seatsFilled,
    required this.seatsTotal,
    this.farePerSeat,
    this.note,
    this.durationMinutes,
  });

  String get dateLabel =>
      '${DateTimeFormatter.monthDayYear(date)}${DateTimeFormatter.relativeDayLabel(date)}';

  String get timeLabel => DateTimeFormatter.time12h(time);

  @override
  List<Object?> get props => [
    id,
    date,
    time,
    fromAddress,
    toAddress,
    fromLat,
    fromLng,
    toLat,
    toLng,
    seatsFilled,
    seatsTotal,
    farePerSeat,
    note,
    durationMinutes,
  ];
}
