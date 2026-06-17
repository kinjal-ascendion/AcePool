import 'package:flutter/material.dart';
import 'package:acepool/core/utils/date_time_formatter.dart';

class ScheduleDateTimeRow extends StatelessWidget {
  const ScheduleDateTimeRow({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.seatCount,
    required this.onDateTap,
    required this.onTimeTap,
    required this.onSeatCountChanged,
  });

  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final int seatCount;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;
  final ValueChanged<int> onSeatCountChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onDateTap,
          child: Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.black87),
              const SizedBox(width: 12),
              Text(
                selectedDate != null
                    ? DateTimeFormatter.monthDayYear(selectedDate!)
                    : 'Select date',
                style: TextStyle(
                  color: selectedDate != null ? Colors.black87 : Colors.black45,
                ),
              ),
            ],
          ),
        ),
        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onTimeTap,
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 18, color: Colors.black87),
                    const SizedBox(width: 12),
                    Text(
                      selectedTime != null
                          ? DateTimeFormatter.time12h(selectedTime!)
                          : 'Choose time',
                      style: TextStyle(
                        color: selectedTime != null ? Colors.black87 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              height: 18,
              width: 1,
              color: Colors.black12,
              margin: const EdgeInsets.symmetric(horizontal: 12),
            ),
            PopupMenuButton<int>(
              initialValue: seatCount,
              onSelected: onSeatCountChanged,
              itemBuilder: (context) => List.generate(
                4,
                (i) => PopupMenuItem(value: i + 1, child: Text('${i + 1}')),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 18, color: Colors.black87),
                  const SizedBox(width: 6),
                  Text('$seatCount', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.black87),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
