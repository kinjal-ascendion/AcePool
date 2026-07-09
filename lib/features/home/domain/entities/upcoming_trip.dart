import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:acepool/core/utils/date_time_formatter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class UpcomingTrip extends Equatable {
  final String id;
  final DateTime date;
  final TimeOfDay time;
  final String fromAddress;
  final String toAddress;
  final LatLng? fromLatLng;
  final LatLng? toLatLng;
  final int seatsFilled;
  final int seatsTotal;

  const UpcomingTrip({
    required this.id,
    required this.date,
    required this.time,
    required this.fromAddress,
    required this.toAddress,
    this.fromLatLng,
    this.toLatLng,
    required this.seatsFilled,
    required this.seatsTotal,
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
    fromLatLng,
    toLatLng,
    seatsFilled,
    seatsTotal,
  ];
}
