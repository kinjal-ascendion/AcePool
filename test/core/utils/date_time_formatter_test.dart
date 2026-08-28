import 'package:acepool/core/utils/date_time_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DateTimeFormatter.monthDayYear', () {
    test('formats a January date correctly', () {
      expect(DateTimeFormatter.monthDayYear(DateTime(2026, 1, 5)), 'January 5, 2026');
    });

    test('formats a December date correctly', () {
      expect(DateTimeFormatter.monthDayYear(DateTime(2026, 12, 25)), 'December 25, 2026');
    });

    test('formats every month name correctly', () {
      const expectedNames = [
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
      for (var month = 1; month <= 12; month++) {
        final result = DateTimeFormatter.monthDayYear(DateTime(2024, month, 1));
        expect(result, '${expectedNames[month - 1]} 1, 2024');
      }
    });

    test('does not zero-pad the day', () {
      expect(DateTimeFormatter.monthDayYear(DateTime(2026, 3, 3)), 'March 3, 2026');
    });
  });

  group('DateTimeFormatter.relativeDayLabel', () {
    test('returns " (Today)" for the current date', () {
      final now = DateTime.now();
      expect(DateTimeFormatter.relativeDayLabel(now), ' (Today)');
    });

    test('returns " (Today)" regardless of time-of-day component', () {
      final now = DateTime.now();
      final sameDayDifferentTime = DateTime(now.year, now.month, now.day, 23, 59);
      expect(DateTimeFormatter.relativeDayLabel(sameDayDifferentTime), ' (Today)');
    });

    test('returns " (Tomorrow)" for the day after today', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(DateTimeFormatter.relativeDayLabel(tomorrow), ' (Tomorrow)');
    });

    test('returns empty string for a date two days out', () {
      final dayAfterTomorrow = DateTime.now().add(const Duration(days: 2));
      expect(DateTimeFormatter.relativeDayLabel(dayAfterTomorrow), '');
    });

    test('returns empty string for a date in the past', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(DateTimeFormatter.relativeDayLabel(yesterday), '');
    });

    test('returns empty string for a date far in the future', () {
      final future = DateTime.now().add(const Duration(days: 30));
      expect(DateTimeFormatter.relativeDayLabel(future), '');
    });
  });

  group('DateTimeFormatter.time12h', () {
    test('formats midnight (00:00) as 12:00 AM', () {
      expect(DateTimeFormatter.time12h(const TimeOfDay(hour: 0, minute: 0)), '12:00 AM');
    });

    test('formats noon (12:00) as 12:00 PM', () {
      expect(DateTimeFormatter.time12h(const TimeOfDay(hour: 12, minute: 0)), '12:00 PM');
    });

    test('formats an early-morning hour with AM', () {
      expect(DateTimeFormatter.time12h(const TimeOfDay(hour: 9, minute: 5)), '9:05 AM');
    });

    test('formats an afternoon hour with PM', () {
      expect(DateTimeFormatter.time12h(const TimeOfDay(hour: 15, minute: 30)), '3:30 PM');
    });

    test('formats 23:00 as 11:00 PM', () {
      expect(DateTimeFormatter.time12h(const TimeOfDay(hour: 23, minute: 0)), '11:00 PM');
    });

    test('formats 11:00 as 11:00 AM', () {
      expect(DateTimeFormatter.time12h(const TimeOfDay(hour: 11, minute: 0)), '11:00 AM');
    });

    test('pads single-digit minutes with a leading zero', () {
      expect(DateTimeFormatter.time12h(const TimeOfDay(hour: 4, minute: 7)), '4:07 AM');
    });

    test('does not pad double-digit minutes', () {
      expect(DateTimeFormatter.time12h(const TimeOfDay(hour: 4, minute: 45)), '4:45 AM');
    });

    test('does not zero-pad single-digit hour12', () {
      expect(DateTimeFormatter.time12h(const TimeOfDay(hour: 1, minute: 0)), '1:00 AM');
    });
  });
}
