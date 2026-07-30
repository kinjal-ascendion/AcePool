import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/di/injection.dart';
import 'package:acepool/features/home/domain/entities/fare_breakdown.dart';
import 'package:acepool/features/home/domain/entities/vehicle_option.dart';
import 'package:acepool/features/home/presentation/bloc/pricing_bloc.dart';
import 'package:acepool/features/home/presentation/pages/ride_published_page.dart';
import 'package:acepool/features/home/presentation/widgets/glass_card.dart';
import 'package:acepool/features/home/presentation/widgets/schedule_ride_button.dart';
import 'package:acepool/features/profile/presentation/pages/vehicle_info_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
          ),
        ),
      child: const _PricingView(),
    );
  }
}

class _PricingView extends StatefulWidget {
  const _PricingView();

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
              final fare = state.fare!;
              final farePerSeat = fare.totalCost / state.seatCount;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => RidePublishedPage(
                    fromAddress: state.fromAddress,
                    toAddress: state.toAddress,
                    farePerSeat: farePerSeat,
                    seatsOffered: state.seatCount,
                    estimatedEarnings: fare.totalCost,
                  ),
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
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          backgroundColor: AppColors.transparent,
          elevation: 0,
          foregroundColor: AppColors.black87,
          centerTitle: true,
          title: const Text(
            'Pricing',
            style: TextStyle(
              color: AppColors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: SafeArea(
          child: BlocBuilder<PricingBloc, PricingState>(
            builder: (context, state) {
              final fare = state.fare;
              if (fare == null) {
                return const Center(child: CircularProgressIndicator());
              }
              final bloc = context.read<PricingBloc>();
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel('SET FARE'),
                          const SizedBox(height: 8),
                          _RouteSummaryCard(
                            fromAddress: state.fromAddress,
                            toAddress: state.toAddress,
                            fare: fare,
                          ),
                          const SizedBox(height: 16),
                          GlassCard(
                            borderRadius: 20,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionLabel('VEHICLE TYPE'),
                                const SizedBox(height: 10),
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
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _RateInputBox(
                                        value: fare.ratePerKm,
                                        onChanged: (v) =>
                                            bloc.add(RatePerKmChanged(v)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Note: Rate per km changes based on the vehicle '
                                  'type you select',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.grey500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _BottomBar(
                    fare: fare,
                    isPublishing: state.status == PricingStatus.publishing,
                    canContinue: state.isFormValid,
                    onContinue: () => bloc.add(const PublishRideRequested()),
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
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.grey600,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _RouteSummaryCard extends StatelessWidget {
  const _RouteSummaryCard({
    required this.fromAddress,
    required this.toAddress,
    required this.fare,
  });

  final String fromAddress;
  final String toAddress;
  final FareBreakdown fare;

  Widget _addressLine(String text) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.grey700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.map_outlined, size: 14, color: AppColors.grey600),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryGreen,
                        width: 1.5,
                      ),
                    ),
                  ),
                  ...List.generate(
                    3,
                    (_) => Container(
                      width: 1.5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: AppColors.black26,
                    ),
                  ),
                  Container(
                    width: 11,
                    height: 11,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _addressLine(fromAddress),
                    const SizedBox(height: 18),
                    _addressLine(toAddress),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: AppColors.grey200, height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 15,
                color: AppColors.grey600,
              ),
              const SizedBox(width: 4),
              Text(
                '${fare.distanceKm.toStringAsFixed(1)} km',
                style: TextStyle(fontSize: 12, color: AppColors.grey600),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 15, color: AppColors.grey600),
              const SizedBox(width: 4),
              Text(
                '${fare.durationMinutes} mins est.',
                style: TextStyle(fontSize: 12, color: AppColors.grey600),
              ),
            ],
          ),
        ],
      ),
    );
  }
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
      hint: const Text('e.g. SUV'),
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
          borderSide: BorderSide(color: AppColors.grey300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.grey300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.black, width: 2),
        ),
      ),
      items: vehicles
          .map((v) => DropdownMenuItem(value: v.id, child: Text(v.label)))
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
  const _RateInputBox({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.grey300),
      ),
      alignment: Alignment.centerLeft,
      child: TextFormField(
        key: ValueKey(value),
        initialValue: value > 0 ? value.round().toString() : '',
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(
          color: AppColors.black87,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: 'Enter Rate/km',
          hintStyle: TextStyle(color: AppColors.grey400, fontSize: 13),
        ),
        onChanged: (text) => onChanged(double.tryParse(text) ?? 0),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.fare,
    required this.isPublishing,
    required this.canContinue,
    required this.onContinue,
  });

  final FareBreakdown fare;
  final bool isPublishing;
  final bool canContinue;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total Cost',
                      style: TextStyle(fontSize: 11, color: AppColors.grey600),
                    ),
                    Text(
                      '₹${fare.totalCost.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ScheduleRideButton(
              onPressed: (isPublishing || !canContinue) ? null : onContinue,
              label: 'Continue to Offer Ride',
              isLoading: isPublishing,
            ),
          ],
        ),
      ),
    );
  }
}
