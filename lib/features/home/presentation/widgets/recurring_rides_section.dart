import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/core/utils/date_time_formatter.dart';
import 'package:acepool/core/utils/ride_matcher.dart';
import 'package:acepool/features/home/presentation/bloc/home_bloc.dart';
import 'package:acepool/features/home/presentation/widgets/vehicle_type_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:acepool/features/home/presentation/widgets/glass_card.dart';

class RecurringRidesSection extends StatefulWidget {
  const RecurringRidesSection({
    super.key,
    required this.fromAddress,
    required this.toAddress,
    this.fromLat,
    this.fromLng,
    this.toLat,
    this.toLng,
    required this.vehicleType,
    required this.onFromTap,
    required this.onToTap,
    required this.onSwap,
  });

  final String? fromAddress;
  final String? toAddress;
  final double? fromLat;
  final double? fromLng;
  final double? toLat;
  final double? toLng;
  final VehicleType vehicleType;
  final VoidCallback onFromTap;
  final VoidCallback onToTap;
  final VoidCallback onSwap;

  @override
  State<RecurringRidesSection> createState() => _RecurringRidesSectionState();
}

class _RecurringRidesSectionState extends State<RecurringRidesSection> {
  bool _isExpanded = false;
  final Set<String> _selectedDays = {};
  DateTime? _fromDate;
  DateTime? _untilDate;
  TimeOfDay? _selectedTime;
  int _seatCount = 1;
  VehicleType _vehicleType = VehicleType.car;

  @override
  Widget build(BuildContext context) {
    double? distanceKm;
    if (widget.fromLat != null && widget.fromLng != null && widget.toLat != null && widget.toLng != null) {
      distanceKm = RideMatcher.distanceKm(widget.fromLat!, widget.fromLng!, widget.toLat!, widget.toLng!);
    }
    final int durationMinutes = distanceKm != null ? (distanceKm * 2.5).round() : 0; // Simple estimation logic

    return BlocListener<HomeBloc, HomeState>(
      listenWhen: (previous, current) =>
          previous.status == HomeStatus.loading &&
          current.status == HomeStatus.success,
      listener: (context, state) {
        if (_isExpanded) {
          setState(() {
            _isExpanded = false;
            _selectedDays.clear();
            _fromDate = null;
            _untilDate = null;
            _selectedTime = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recurring rides scheduled successfully!')),
          );
        }
      },
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 16,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDFDFD),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/recurring_icon.png',
                      width: 20,
                      height: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Recurring Rides',
                        style: GoogleFonts.mulish(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          height: 20 / 17,
                          color: const Color(0xFF1D1D1D),
                        ),
                      ),
                      Text(
                        'Schedule your office commute',
                        style: GoogleFonts.mulish(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          height: 16 / 12,
                          color: const Color(0xFF757474),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: const Color(0xFF757474),
                  size: 24,
                ),
              ],
            ),
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 16),
            _RecurringVehicleTypeToggle(
              selected: _vehicleType,
              onChanged: (type) => setState(() => _vehicleType = type),
            ),
            const SizedBox(height: 16),
            _RouteSection(
              fromAddress: widget.fromAddress,
              toAddress: widget.toAddress,
              distanceKm: distanceKm,
              durationMinutes: durationMinutes,
              onFromTap: widget.onFromTap,
              toTap: widget.onToTap,
              onSwap: widget.onSwap,
            ),
            const SizedBox(height: 16),
            _buildSectionLabel('Select Office Days'),
            const SizedBox(height: 16),
            _DayPicker(
              selectedDays: _selectedDays,
              onChanged: (day) {
                setState(() {
                  if (_selectedDays.contains(day)) {
                    _selectedDays.remove(day);
                  } else {
                    _selectedDays.add(day);
                  }
                });
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: Color(0xFFEDEDED)),
            ),
            _buildSectionLabelWithIcon(Icons.calendar_today_outlined, 'Schedule Dates'),
            const SizedBox(height: 16),
            _DateRangePicker(
              fromDate: _fromDate,
              untilDate: _untilDate,
              onFromTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _fromDate = picked);
              },
              onUntilTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _fromDate ?? DateTime.now(),
                  firstDate: _fromDate ?? DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _untilDate = picked);
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: Color(0xFFEDEDED)),
            ),
            _TimeAndSeatsRow(
              selectedTime: _selectedTime,
              seatCount: _seatCount,
              vehicleType: widget.vehicleType,
              onTimeTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (picked != null) setState(() => _selectedTime = picked);
              },
              onSeatCountChanged: (val) => setState(() => _seatCount = val),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: Color(0xFFEDEDED)),
            ),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (widget.fromAddress != null &&
                        widget.toAddress != null &&
                        _selectedDays.isNotEmpty &&
                        _fromDate != null &&
                        _untilDate != null &&
                        _selectedTime != null)
                    ? () {
                        context.read<HomeBloc>().add(RecurringRideScheduled(
                              days: _selectedDays.toList(),
                              fromDate: _fromDate!,
                              untilDate: _untilDate!,
                              time: _selectedTime!,
                              seatCount: _seatCount,
                              vehicleType: _vehicleType,
                            ));
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1E1E),
                  disabledBackgroundColor: const Color(0xFF1E1E1E).withValues(alpha: 0.6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Schedule recurring ride',
                  style: GoogleFonts.mulish(
                    color: const Color(0xFFFEFEFE),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    height: 1.0,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SummaryText(
              days: _selectedDays,
              fromDate: _fromDate,
              untilDate: _untilDate,
              time: _selectedTime,
            ),
          ],
        ],
      ),
    ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.mulish(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 20 / 16,
          letterSpacing: 16 * 0.01,
          color: const Color(0xFF757474),
        ),
      ),
    );
  }

  Widget _buildSectionLabelWithIcon(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF757474)),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.mulish(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 20 / 16,
            letterSpacing: 16 * 0.01,
            color: const Color(0xFF757474),
          ),
        ),
      ],
    );
  }
}

class _RecurringVehicleTypeToggle extends StatelessWidget {
  const _RecurringVehicleTypeToggle({required this.selected, required this.onChanged});

  final VehicleType selected;
  final ValueChanged<VehicleType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RadioOption(
          label: 'Car',
          selected: selected == VehicleType.car,
          onTap: () => onChanged(VehicleType.car),
        ),
        const SizedBox(width: 24),
        _RadioOption(
          label: 'Bike',
          selected: selected == VehicleType.bike,
          onTap: () => onChanged(VehicleType.bike),
        ),
        const SizedBox(width: 24),
        _RadioOption(
          label: 'Cab',
          selected: selected == VehicleType.cab,
          onTap: () => onChanged(VehicleType.cab),
        ),
      ],
    );
  }
}

class _RadioOption extends StatelessWidget {
  const _RadioOption({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color activeColor = const Color(0xFF1E1E1E);
    final Color inactiveColor = const Color(0xFF757474);

    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: selected ? activeColor : inactiveColor, width: 2),
            ),
            child: selected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: activeColor, shape: BoxShape.circle),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.mulish(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              height: 18 / 16,
              color: selected ? activeColor : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteSection extends StatelessWidget {
  const _RouteSection({
    required this.fromAddress,
    required this.toAddress,
    this.distanceKm,
    required this.durationMinutes,
    required this.onFromTap,
    required this.toTap,
    required this.onSwap,
  });

  final String? fromAddress;
  final String? toAddress;
  final double? distanceKm;
  final int durationMinutes;
  final VoidCallback onFromTap;
  final VoidCallback toTap;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    final addressStyle = GoogleFonts.mulish(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 18 / 16,
      color: const Color(0xFF000000),
    );

    final statsStyle = GoogleFonts.mulish(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 20 / 14,
      letterSpacing: 14 * 0.01,
      color: const Color(0xFF1D1D1D),
    );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFEDEDED)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Column(
                  children: [
                    const SizedBox(height: 18), // Centers first dot in 14+18/2 context
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryGreen, width: 1.5),
                      ),
                    ),
                    Container(width: 1, height: 40, color: const Color(0xFFEDEDED)),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: onFromTap,
                        child: Text(
                          fromAddress ?? 'Enter start location',
                          style: addressStyle.copyWith(
                            color: fromAddress != null ? Colors.black : const Color(0xFFB6B6B6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Divider(height: 1, color: Color(0xFFEDEDED)),
                      const SizedBox(height: 15),
                      InkWell(
                        onTap: toTap,
                        child: Text(
                          toAddress ?? 'Enter office location',
                          style: addressStyle.copyWith(
                            color: toAddress != null ? Colors.black : const Color(0xFFB6B6B6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    const Icon(Icons.map_outlined, size: 20, color: Color(0xFFB6B6B6)),
                    const SizedBox(height: 16),
                    const Icon(Icons.map_outlined, size: 20, color: Color(0xFFB6B6B6)),
                  ],
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onSwap,
                  icon: const Icon(Icons.swap_vert, color: Color(0xFFB6B6B6)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16 + 5), // Align with dot center (16 padding + 5 radius)
            child: const Divider(height: 1, color: Color(0xFFEDEDED)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF1D1D1D)),
                      const SizedBox(width: 6),
                      Text(
                        '${(distanceKm ?? 0.0).toStringAsFixed(1)} km',
                        style: statsStyle,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 18, color: Color(0xFF1D1D1D)),
                      const SizedBox(width: 6),
                      Text(
                        durationMinutes > 0 ? RideMatcher.formatDuration(durationMinutes) : '0 mins est.',
                        style: statsStyle,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayPicker extends StatelessWidget {
  const _DayPicker({required this.selectedDays, required this.onChanged});
  final Set<String> selectedDays;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days.map((day) {
        final isSelected = selectedDays.contains(day);
        return GestureDetector(
          onTap: () => onChanged(day),
          child: Container(
            width: 42.28571319580078,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? const Color(0xFF1E1E1E) : const Color(0xFFEDEDED),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              day,
              style: GoogleFonts.mulish(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                height: 20 / 14,
                letterSpacing: 14 * 0.01,
                color: isSelected ? const Color(0xFFF0F1F2) : const Color(0xFF000000),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DateRangePicker extends StatelessWidget {
  const _DateRangePicker({
    required this.fromDate,
    required this.untilDate,
    required this.onFromTap,
    required this.onUntilTap,
  });
  final DateTime? fromDate;
  final DateTime? untilDate;
  final VoidCallback onFromTap;
  final VoidCallback onUntilTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _DateBox(label: 'From', date: fromDate, onTap: onFromTap)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('—', style: TextStyle(color: Color(0xFF8A8A8A))),
        ),
        Expanded(child: _DateBox(label: 'Until', date: untilDate, onTap: onUntilTap)),
      ],
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({required this.label, this.date, required this.onTap});
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFEDEDED)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.mulish(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 20 / 14,
                letterSpacing: 14 * 0.01,
                color: const Color(0xFF000000),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date != null ? DateTimeFormatter.monthDayYear(date!) : 'Select',
              style: GoogleFonts.mulish(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 20 / 16,
                letterSpacing: 16 * 0.01,
                color: const Color(0xFF000000),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeAndSeatsRow extends StatelessWidget {
  const _TimeAndSeatsRow({
    required this.selectedTime,
    required this.seatCount,
    required this.vehicleType,
    required this.onTimeTap,
    required this.onSeatCountChanged,
  });
  final TimeOfDay? selectedTime;
  final int seatCount;
  final VehicleType vehicleType;
  final VoidCallback onTimeTap;
  final ValueChanged<int> onSeatCountChanged;

  @override
  Widget build(BuildContext context) {
    final maxSeats = vehicleType == VehicleType.bike ? 1 : 4;
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onTimeTap,
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 20, color: Color(0xFF1E1E1E)),
                const SizedBox(width: 12),
                Text(
                  selectedTime != null ? DateTimeFormatter.time12h(selectedTime!) : 'Choose time',
                  style: GoogleFonts.mulish(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 20 / 16,
                    letterSpacing: 16 * 0.01,
                    color: const Color(0xFF757474),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          width: 1,
          height: 20,
          color: const Color(0xFFEDEDED),
          margin: const EdgeInsets.symmetric(horizontal: 16),
        ),
        PopupMenuButton<int>(
          onSelected: onSeatCountChanged,
          itemBuilder: (context) => List.generate(
            maxSeats,
            (i) => PopupMenuItem(value: i + 1, child: Text('${i + 1}')),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 18, // Visual size closest to 11x13 with padding
                color: Color(0xFF757474),
              ),
              const SizedBox(width: 3.5),
              Text(
                '$seatCount',
                style: GoogleFonts.mulish(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF757474),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 18, // Visual size closest to 12x6
                color: Color(0xFF757474),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryText extends StatelessWidget {
  const _SummaryText({required this.days, this.fromDate, this.untilDate, this.time});
  final Set<String> days;
  final DateTime? fromDate;
  final DateTime? untilDate;
  final TimeOfDay? time;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();
    final daysStr = days.join(', ');
    final rangeStr = (fromDate != null && untilDate != null)
        ? '${DateTimeFormatter.monthDayYear(fromDate!)} → ${DateTimeFormatter.monthDayYear(untilDate!)}'
        : '';
    final timeStr = time != null ? 'at ${DateTimeFormatter.time12h(time!)}' : '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: 16, color: Color(0xFFD97706)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Every $daysStr $rangeStr $timeStr',
            style: GoogleFonts.mulish(
              fontSize: 14,
              color: const Color(0xFFD97706),
              fontWeight: FontWeight.w400,
              height: 18 / 14,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}
