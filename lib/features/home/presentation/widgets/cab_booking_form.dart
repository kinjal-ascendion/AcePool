import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/features/home/domain/entities/picked_location.dart';
import 'package:acepool/features/home/presentation/bloc/home_bloc.dart';
import 'package:acepool/features/home/presentation/widgets/glass_card.dart';
import 'package:acepool/features/home/presentation/widgets/vehicle_type_toggle.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CabBookingForm extends StatefulWidget {
  const CabBookingForm({
    super.key,
    required this.rideMode,
    required this.onVehicleTypeChanged,
    required this.startAddress,
    required this.destinationAddress,
    required this.onStartTap,
    required this.onDestinationTap,
    required this.onLocationTap,
    required this.selectedDate,
    required this.selectedTime,
    required this.onDateTap,
    required this.onTimeTap,
    required this.onBookPressed,
    required this.passengerCount,
    required this.onPassengerCountChanged,
  });

final RideMode rideMode;
  final ValueChanged<VehicleType> onVehicleTypeChanged;

  final String? startAddress;
  final String? destinationAddress;

  final VoidCallback onStartTap;
  final VoidCallback onDestinationTap;

  final Future<PickedLocation?> Function(
    String title,
    String? current,
  ) onLocationTap;

  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;

  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;

  final VoidCallback onBookPressed;

final int passengerCount;
final ValueChanged<int> onPassengerCountChanged;

  @override
  State<CabBookingForm> createState() => _CabBookingFormState();
}

class _CabStopDraft {
  String? pickup;
  String? dropOff;

  _CabStopDraft({
    this.pickup,
    this.dropOff,
  });
}

class _CabBookingFormState extends State<CabBookingForm> {
  final List<_CabStopDraft> _stops = [
    _CabStopDraft(),
  ];

  int _passengerCount = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          borderRadius: 26,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(),

              const SizedBox(height: 22),

              _buildVehicleRow(),

              const SizedBox(height: 18),

              _buildRouteSection(),

              const SizedBox(height: 8),

              _buildAddStopButton(),

              const SizedBox(height: 12),

              Divider(
                height: 1,
                color: AppColors.grey300,
              ),

              _buildDateRow(),

              Divider(
                height: 1,
                color: AppColors.grey300,
              ),

              _buildTimeAndPassengerRow(),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: widget.onBookPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    'Book Cab',
                    style: GoogleFonts.mulish(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline,
              size: 17,
              color: Color(0xFFD19A42),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                'Pickup and drop-off locations are required for each rider '
                'when booking a cab',
                style: GoogleFonts.mulish(
                  fontSize: 13,
                  height: 1.35,
                  color: const Color(0xFFD19A42),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.grey200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How Cab sharing works',
            style: GoogleFonts.mulish(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.black87,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Set your pickup & drop-off points',
            style: _descriptionStyle(),
          ),
          Text(
            'Add stops to pick up co-passengers',
            style: _descriptionStyle(),
          ),
          Text(
            'Split the fare with everyone on board',
            style: _descriptionStyle(),
          ),
        ],
      ),
    );
  }

  TextStyle _descriptionStyle() {
    return GoogleFonts.mulish(
      fontSize: 15,
      height: 1.45,
      color: AppColors.grey700,
      fontWeight: FontWeight.w500,
    );
  }

  Widget _buildVehicleRow() {
    return Row(
      children: [
        Expanded(
          child: FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: VehicleTypeToggle(
              selected: VehicleType.cab,
              rideMode: widget.rideMode,
              onChanged: widget.onVehicleTypeChanged,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 0,
          ),
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.grey200,
            ),
          ),
          child: Text(
            'Book & share',
            style: GoogleFonts.mulish(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.black87,
            ),
          ),
        ),
      ],
    );
  }

Widget _buildRouteSection() {
  const double rowHeight = 40.0;
  const double markerColumnWidth = 28.0;

  final int totalRows = 2 + (_stops.length * 2);
  final double routeHeight = totalRows * rowHeight;

  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: markerColumnWidth,
        height: routeHeight,
        child: CustomPaint(
          painter: _RouteLinePainter(
            topCenterY: rowHeight / 2,
            bottomCenterY: routeHeight - (rowHeight / 2),
          ),
        ),
      ),

      Expanded(
        child: Column(
          children: [
            SizedBox(
              height: rowHeight,
              child: _LocationRow(
                text: widget.startAddress ?? 'Enter start location',
                placeholder: widget.startAddress == null,
                onTap: widget.onStartTap,
                dividerWidth: 280.0,
              ),
            ),

            for (int i = 0; i < _stops.length; i++)
              _buildStop(i),

            SizedBox(
              height: rowHeight,
              child: _LocationRow(
                text: widget.destinationAddress ??
                    'Enter drop-off destination',
                placeholder: widget.destinationAddress == null,
                onTap: widget.onDestinationTap,
                dividerWidth: 280.0,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _buildStop(int index) {
  final stop = _stops[index];

  return SizedBox(
    height: 85.0,
    child: Stack(
      children: [
        Column(
          children: [
            SizedBox(
              height: 40.0,
              child: _LocationRow(
                text: stop.pickup ?? 'Pickup stop ${index + 1}',
                placeholder: stop.pickup == null,
                showClear: true,

                // KEEP EXISTING LOCATION SEARCH LOGIC
                onTap: () async {
                  final result = await widget.onLocationTap(
                    'Pickup stop ${index + 1}',
                    stop.pickup,
                  );

                  if (result != null) {
                    setState(() {
                      stop.pickup = result.address;
                    });
                  }
                },

                onClear: () {
                  setState(() {
                    _stops.removeAt(index);
                  });
                },

                dividerWidth: 280.0,
              ),
            ),

            SizedBox(
              height: 40.0,
              child: _LocationRow(
                text: stop.dropOff ??
                    'Drop-off destination ${index + 1}',
                placeholder: stop.dropOff == null,
                showClear: true,

                // KEEP EXISTING LOCATION SEARCH LOGIC
                onTap: () async {
                  final result = await widget.onLocationTap(
                    'Drop-off destination ${index + 1}',
                    stop.dropOff,
                  );

                  if (result != null) {
                    setState(() {
                      stop.dropOff = result.address;
                    });
                  }
                },

                onClear: () {
                  setState(() {
                    _stops.removeAt(index);
                  });
                },

                dividerWidth: 280.0,
              ),
            ),
          ],
        ),

        // Swap icon between the two rows
        Positioned(
          right: 8.0,
          top: 25.0,
          child: InkWell(
            onTap: () {
              setState(() {
                final temp = stop.pickup;
                stop.pickup = stop.dropOff;
                stop.dropOff = temp;
              });
            },
            child: const SizedBox(
              width: 18.0,
              height: 18.0,
              child: Icon(
                Icons.swap_vert,
                size: 25.0,
                color: Color(0xFF8A8A8A),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildAddStopButton() {
    return InkWell(
      onTap: () {
        setState(() {
          _stops.add(_CabStopDraft());
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            const Icon(
              Icons.add_circle_outline,
              size: 24,
              color: AppColors.black87,
            ),
            const SizedBox(width: 9),
            Text(
              'Add passenger pickup and drop-off stop',
              style: GoogleFonts.mulish(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRow() {
    final label = widget.selectedDate == null
        ? 'Select date'
        : '${widget.selectedDate!.day.toString().padLeft(2, '0')}/'
            '${widget.selectedDate!.month.toString().padLeft(2, '0')}/'
            '${widget.selectedDate!.year}';

    return InkWell(
      onTap: widget.onDateTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 23,
              color:Color(0xFF8A8A8A),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.mulish(
                fontSize: 16,
                color: widget.selectedDate == null
                    ? const Color(0xFF8A8A8A)
                    : AppColors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeAndPassengerRow() {
    final timeLabel = widget.selectedTime == null
        ? 'Choose time'
        : widget.selectedTime!.format(context);

    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: widget.onTimeTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time_outlined,
                    size: 24,
                    color:Color(0xFF8A8A8A),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    timeLabel,
                    style: GoogleFonts.mulish(
                      fontSize: 16,
                      color: widget.selectedTime == null
                          ? const Color(0xFF8A8A8A)
                          : AppColors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        Container(
          width: 1,
          height: 28,
          color: AppColors.grey300,
        ),

        PopupMenuButton<int>(
  initialValue: widget.passengerCount,
  onSelected: (value) {
    widget.onPassengerCountChanged(value);
  },
          itemBuilder: (_) => List.generate(
            5,
            (index) => PopupMenuItem(
              value: index,
              child: Text('$index'),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 2,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 23,
                  color: AppColors.grey,
                ),
                const SizedBox(width: 10),
                Text(
                  '${widget.passengerCount}',
                  style: GoogleFonts.mulish(
                    fontSize: 16,
                    color: AppColors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 22,
                  color: AppColors.grey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.text,
    required this.placeholder,
    required this.onTap,
    this.showClear = false,
    this.onClear,
    this.dividerWidth,
  });

  final String text;
  final bool placeholder;
  final VoidCallback onTap;
  final bool showClear;
  final VoidCallback? onClear;
  final double? dividerWidth;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 59,
        child: Stack(
          children: [
            // Text
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(
                  right: showClear ? 44 : 0,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.mulish(
                      fontSize: 16,
                      color: placeholder
                          ? const Color(0xFF8A8A8A)
                          : AppColors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            // Clear X
            if (showClear)
              Positioned(
                right: 50,
                top: 5,
                child: InkWell(
                  onTap: onClear,
                  child: const SizedBox(
                    width: 32,
                    height: 32,
                    child: Center(
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: Color(0xFF8A8A8A),
                      ),
                    ),
                  ),
                ),
              ),

            // Short divider
            if (dividerWidth != null)
              Positioned(
                left: 0,
                bottom: 0,
                child: SizedBox(
                  width: dividerWidth!,
                  child: const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.grey,
                  ),
                ),
              )
            else
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
class _RouteLinePainter extends CustomPainter {
  const _RouteLinePainter({
    required this.topCenterY,
    required this.bottomCenterY,
  });

  final double topCenterY;
  final double bottomCenterY;

  static const Color green = Color(0xFF1E8E5A);

  @override
  void paint(Canvas canvas, Size size) {
    const double centerX = 9.5;

    final topCirclePaint = Paint()
      ..color = green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(
      Offset(centerX, topCenterY),
      4.0,
      topCirclePaint,
    );

    final bottomCirclePaint = Paint()
      ..color = green
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(centerX, bottomCenterY),
      4.0,
      bottomCirclePaint,
    );

    final dotPaint = Paint()
      ..color = green
      ..style = PaintingStyle.fill;

    const double dotRadius = 1.0;
    const double dotSpacing = 6.0;

    double y = topCenterY + 5.0;

    while (y < bottomCenterY - 5.0) {
      canvas.drawCircle(
        Offset(centerX, y),
        dotRadius,
        dotPaint,
      );

      y += dotSpacing;
    }
  }

  @override
  bool shouldRepaint(covariant _RouteLinePainter oldDelegate) {
    return oldDelegate.topCenterY != topCenterY ||
        oldDelegate.bottomCenterY != bottomCenterY;
  }
}