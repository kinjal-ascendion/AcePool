import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/core/utils/ride_matcher.dart';
import 'package:acepool/di/injection.dart';
import 'package:acepool/features/home/domain/entities/fare_breakdown.dart';
import 'package:acepool/features/home/domain/entities/vehicle_option.dart';
import 'package:acepool/features/home/presentation/bloc/pricing_bloc.dart';
import 'package:acepool/features/home/presentation/pages/ride_published_page.dart';
import 'package:acepool/features/home/presentation/widgets/schedule_ride_button.dart';
import 'package:acepool/features/profile/presentation/pages/vehicle_info_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:acepool/features/home/presentation/pages/cab_booked_page.dart';

class PricingPage extends StatelessWidget {
  const PricingPage({
    super.key,
    required this.fromAddress,
    required this.toAddress,
    this.fromLat,
    this.fromLng,
    this.toLat,
    this.toLng,
    required this.date,
    required this.time,
    required this.seatCount,
    required this.vehicleType,
    required this.rideMode,
    this.hasReturnRide = false,
    this.returnTime,
    this.returnSeatCount = 1,
    this.rideId,
  });

  final String fromAddress;
  final String toAddress;
  final double? fromLat;
  final double? fromLng;
  final double? toLat;
  final double? toLng;
  final DateTime date;
  final TimeOfDay time;
  final int seatCount;
  final String vehicleType;
  final String rideMode;

  final bool hasReturnRide;
  final TimeOfDay? returnTime;
  final int returnSeatCount;
  final String? rideId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PricingBloc>()
        ..add(
          PricingStarted(
            fromAddress: fromAddress,
            toAddress: toAddress,
            fromLat: fromLat,
            fromLng: fromLng,
            toLat: toLat,
            toLng: toLng,
            date: date,
            time: time,
            seatCount: seatCount,
            vehicleType: vehicleType,
            rideMode: rideMode,
            hasReturnRide: hasReturnRide,
            returnTime: returnTime,
            returnSeatCount: returnSeatCount,
            rideId: rideId,
          ),
        ),
      child: _PricingView(
  rideMode: rideMode,
  fromAddress: fromAddress,
  toAddress: toAddress,
  date: date,
  time: time,
  seatCount: seatCount,
),
    );
  }
}

class _PricingView extends StatefulWidget {
  const _PricingView({
    required this.rideMode,
    required this.fromAddress,
    required this.toAddress,
    required this.date,
    required this.time,
    required this.seatCount,
  });

  final String rideMode;
  final String fromAddress;
  final String toAddress;
  final DateTime date;
  final TimeOfDay time;
  final int seatCount;

  @override
  State<_PricingView> createState() => _PricingViewState();
}

class _PricingViewState extends State<_PricingView> {
  Future<void> _promptAddVehicle(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add a vehicle'),
        content: const Text(
          'You need to add a vehicle before you can offer a ride.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const VehicleInfoPage()));
    if (!context.mounted) return;
    context.read<PricingBloc>().add(const VehiclesRefreshRequested());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<PricingBloc, PricingState>(
          listenWhen: (previous, current) =>
              previous.status != current.status &&
              (current.status == PricingStatus.published ||
                  current.status == PricingStatus.failure),
          listener: (context, state) {
            if (state.status == PricingStatus.published) {
              final rides = <RideSummary>[];

              // Add main ride
              final fare = state.fare!;
              rides.add(RideSummary(
                label: 'Going',
                fromAddress: state.fromAddress,
                toAddress: state.toAddress,
                farePerSeat: fare.totalCost / state.seatCount,
                seatsOffered: state.seatCount,
                estimatedEarnings: fare.totalCost,
              ));

              // Add return ride if scheduled
              if (state.hasReturnRide && state.returnFare != null) {
                final rf = state.returnFare!;
                rides.add(RideSummary(
                  label: 'Return',
                  fromAddress: state.toAddress,
                  toAddress: state.fromAddress,
                  farePerSeat: rf.totalCost / state.returnSeatCount,
                  seatsOffered: state.returnSeatCount,
                  estimatedEarnings: rf.totalCost,
                ));
              }

              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => RidePublishedPage(rides: rides),
                ),
                result: true,
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage ?? 'Something went wrong'),
                ),
              );
            }
          },
        ),
        BlocListener<PricingBloc, PricingState>(
          listenWhen: (previous, current) =>
              previous.status != current.status &&
              current.status == PricingStatus.ready &&
              current.vehicles.isEmpty,
          listener: (context, state) => _promptAddVehicle(context),
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              size: 26,
              color: Colors.black,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          title: Text(
            'Pricing',
            style: GoogleFonts.mulish(
              color: Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: 24,
              height: 1.0,
            ),
          ),
        ),
        body: SafeArea(
          child: BlocBuilder<PricingBloc, PricingState>(
            builder: (context, state) {
              final fare = state.activeTab == PricingTab.current
                  ? state.fare
                  : state.returnFare;
              if (fare == null) {
                return const Center(child: CircularProgressIndicator());
              }
              final bloc = context.read<PricingBloc>();

              return Column(
                children: [
                  if (state.hasReturnRide) ...[
                    const SizedBox(height: 16),
                    _RideToggle(
                      activeTab: state.activeTab,
                      onChanged: (tab) => bloc.add(PricingTabChanged(tab)),
                    ),
                  ],
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionLabel('SET FARE'),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFDDDDDD)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: _RouteSummarySection(
                              fromAddress: state.activeTab == PricingTab.current
                                  ? state.fromAddress
                                  : state.toAddress,
                              toAddress: state.activeTab == PricingTab.current
                                  ? state.toAddress
                                  : state.fromAddress,
                              fare: fare,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const _SectionLabel('VEHICLE TYPE'),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _VehicleDropdown(
                                  vehicles: state.vehicles,
                                  selectedId: fare.vehicleId,
                                  onChanged: (id, label) => bloc.add(
                                    VehicleSelected(id, label),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _RateInputBox(
                                  value: fare.ratePerKm,
                                  onChanged: (v) => bloc.add(RatePerKmChanged(v)),
                                  rideMode: widget.rideMode,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                             widget.rideMode == 'cab'
      ? 'Note: The pricing shown is current as of now and may change in the future'
      : 'Note: Rate per km changes based on the vehicle type you select',
                            style: GoogleFonts.mulish(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 18 / 14,
                              color: const Color(0xFF4C515B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _BottomBar(
                    fare: fare,
                    seatCount: state.activeTab == PricingTab.current
                        ? state.seatCount
                        : state.returnSeatCount,
                    isPublishing: state.status == PricingStatus.publishing,
                    canContinue: state.isFormValid,
                    rideMode: widget.rideMode,
                   onContinue: () {
  if (widget.rideMode == 'cab') {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CabBookedPage(
          fromAddress: widget.fromAddress,
          toAddress: widget.toAddress,
          estimatedFare: fare.totalCost,
          seatCount: state.seatCount,
          date: widget.date,
          time: widget.time,
        ),
      ),
    );
    return;
  }

  bloc.add(const PublishRideRequested());
},
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.mulish(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 15 / 14,
        color: const Color(0xFF4C515B),
        letterSpacing: 0.8,
      ),
    );
  }
}

class _RideToggle extends StatelessWidget {
  final PricingTab activeTab;
  final ValueChanged<PricingTab> onChanged;

  const _RideToggle({required this.activeTab, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            alignment: activeTab == PricingTab.current
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: Container(
              width: 125,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(PricingTab.current),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      'Current Ride',
                      style: GoogleFonts.mulish(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: activeTab == PricingTab.current
                            ? Colors.white
                            : const Color(0xFF1E1E1E),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(PricingTab.returnRide),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      'Return Ride',
                      style: GoogleFonts.mulish(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: activeTab == PricingTab.returnRide
                            ? Colors.white
                            : const Color(0xFF1E1E1E),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteSummarySection extends StatelessWidget {
  const _RouteSummarySection({
    required this.fromAddress,
    required this.toAddress,
    required this.fare,
  });

  final String fromAddress;
  final String toAddress;
  final FareBreakdown fare;

  @override
  Widget build(BuildContext context) {
    final addressStyle = GoogleFonts.mulish(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 18 / 16,
      color: Colors.black,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryGreen,
                        width: 1.5,
                      ),
                    ),
                  ),
                  Container(
                    width: 1.5,
                    height: 32,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    child: CustomPaint(painter: _DashedLinePainter()),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            fromAddress,
                            style: addressStyle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.map_outlined, size: 20, color: Color(0xFF757474)),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(color: Color(0xFFDDDDDD), height: 1),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            toAddress,
                            style: addressStyle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.map_outlined, size: 20, color: Color(0xFF757474)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.swap_vert, size: 24, color: Color(0xFF757474)),
            ],
          ),
        ),
        const Divider(color: Color(0xFFDDDDDD), height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Image.asset('assets/images/distance_map_icon.png', width: 16, height: 16),
              const SizedBox(width: 6),
              Text(
                '${fare.distanceKm.toStringAsFixed(1)} km',
                style: GoogleFonts.mulish(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 20 / 14,
                  letterSpacing: 14 * 0.01,
                  color: const Color(0xFF1D1D1D),
                ),
              ),
              const SizedBox(width: 32),
              Image.asset('assets/images/estimation_timer.png', width: 16, height: 16),
              const SizedBox(width: 6),
              Text(
                '${RideMatcher.formatDuration(fare.durationMinutes)} est.',
                style: GoogleFonts.mulish(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 20 / 14,
                  letterSpacing: 14 * 0.01,
                  color: const Color(0xFF1D1D1D),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 5, dashSpace = 3, startY = 0;
    final paint = Paint()
      ..color = AppColors.black26
      ..strokeWidth = size.width;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _VehicleDropdown extends StatelessWidget {
  const _VehicleDropdown({
    required this.vehicles,
    required this.selectedId,
    required this.onChanged,
  });

  final List<VehicleOption> vehicles;
  final String? selectedId;
  final void Function(String id, String label) onChanged;

  @override
  Widget build(BuildContext context) {
    final validSelectedId = vehicles.any((v) => v.id == selectedId)
        ? selectedId
        : null;
    return DropdownButtonFormField<String>(
      value: validSelectedId,
      isExpanded: true,
      hint: Text(
        'e.g. SUV',
        style: GoogleFonts.mulish(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFB6B6B6),
        ),
      ),
      icon: Image.asset(
        'assets/images/expand.png',
        width: 12,
        height: 12,
        color: const Color(0xFF757474),
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.keyboard_arrow_down, color: Color(0xFF757474)),
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.black, width: 1),
        ),
      ),
      items: vehicles
          .map((v) => DropdownMenuItem(
                value: v.id,
                child: Text(
                  v.label,
                  style: GoogleFonts.mulish(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ))
          .toList(),
      onChanged: vehicles.isEmpty
          ? null
          : (id) {
              if (id == null) return;
              final vehicle = vehicles.firstWhere((v) => v.id == id);
              onChanged(id, vehicle.label);
            },
    );
  }
}

class _RateInputBox extends StatelessWidget {
  const _RateInputBox({required this.value, required this.onChanged, required this.rideMode,});

  final double value;
  final ValueChanged<double> onChanged;
  final String rideMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      alignment: Alignment.centerLeft,
      child: TextFormField(
        key: ValueKey(value),
        initialValue: value > 0 ? value.round().toString() : '',
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: GoogleFonts.mulish(
          color: AppColors.black87,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: rideMode == 'cab'
    ? 'Enter Price'
    : 'Enter Rate/km',
          hintStyle: GoogleFonts.mulish(
            color: const Color(0xFFB6B6B6),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        onChanged: (text) => onChanged(double.tryParse(text) ?? 0),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.fare,
    required this.seatCount,
    required this.isPublishing,
    required this.canContinue,
    required this.rideMode,
    required this.onContinue,
  });

  final FareBreakdown fare;
  final int seatCount;
  final bool isPublishing;
  final bool canContinue;
  final String rideMode;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final earnings = fare.totalCost;
    final perPassenger = seatCount > 0 ? earnings / seatCount : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFDDDDDD), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your earnings',
                      style: GoogleFonts.mulish(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF757474),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${earnings.toStringAsFixed(0)}',
                      style: GoogleFonts.mulish(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0D9488), // primaryGreen-like
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Per passenger',
                      style: GoogleFonts.mulish(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF757474),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${perPassenger.toStringAsFixed(0)}',
                      style: GoogleFonts.mulish(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E1E1E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ScheduleRideButton(
              onPressed: (isPublishing || !canContinue) ? null : onContinue,
              label: rideMode == 'cab'
              ? 'Book Cab'
              : 'Continue to Offer Ride',
              isLoading: isPublishing,
            ),
          ],
        ),
      ),
    );
  }
}
