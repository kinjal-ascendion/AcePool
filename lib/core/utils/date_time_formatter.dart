import 'package:flutter/material.dart';

class DateTimeFormatter {
  DateTimeFormatter._();

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static String monthDayYear(DateTime date) {
    return '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  static String relativeDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = target.difference(today).inDays;
    if (difference == 0) return ' (Today)';
    if (difference == 1) return ' (Tomorrow)';
    return '';
  }

  static String time12h(TimeOfDay time) {
    final period = time.hour < 12 ? 'AM' : 'PM';
    final hour12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour12:$minute $period';
  }
}
