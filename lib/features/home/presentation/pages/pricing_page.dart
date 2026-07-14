import 'package:acepool/core/constants/fare_constants.dart';
import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/core/theme/app_theme.dart';
import 'package:acepool/di/injection.dart';
import 'package:acepool/features/home/domain/entities/fare_breakdown.dart';
import 'package:acepool/features/home/presentation/bloc/pricing_bloc.dart';
import 'package:acepool/features/home/presentation/pages/ride_published_page.dart';
import 'package:acepool/features/home/presentation/widgets/fare_field_box.dart';
import 'package:acepool/features/home/presentation/widgets/glass_card.dart';
import 'package:acepool/features/home/presentation/widgets/rider_count_stepper.dart';
import 'package:acepool/features/home/presentation/widgets/schedule_ride_button.dart';
import 'package:flutter/material.dart';
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
        ..add(PricingStarted(
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
        )),
      child: const _PricingView(),
    );
  }
}

class _PricingView extends StatelessWidget {
  const _PricingView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<PricingBloc, PricingState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          (current.status == PricingStatus.published ||
              current.status == PricingStatus.failure),
      listener: (context, state) {
        if (state.status == PricingStatus.published) {
          final fare = state.fare!;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => RidePublishedPage(
                fromAddress: state.fromAddress,
                toAddress: state.toAddress,
                farePerSeat: fare.farePerSeat,
                seatsOffered: fare.riderCount,
                estimatedEarnings: fare.driverEarnings,
              ),
            ),
            result: true,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'Something went wrong')),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          backgroundColor: AppColors.transparent,
          elevation: 0,
          foregroundColor: AppColors.black87,
          centerTitle: true,
          title: const Text(
            'Pricing',
            style: TextStyle(color: AppColors.black87, fontWeight: FontWeight.w600),
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
                                _SectionLabel('SHARED TRIP COST'),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () =>
                                      bloc.add(TollsIncludedToggled(!fare.includeTolls)),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Checkbox(
                                          value: fare.includeTolls,
                                          onChanged: (v) =>
                                              bloc.add(TollsIncludedToggled(v ?? false)),
                                          activeColor: AppTheme.scheduleButtonColor,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'Include toll charges',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: FareFieldBox(
                                        label: 'DISTANCE',
                                        value: fare.distanceCost,
                                        onChanged: (v) => bloc.add(DistanceCostChanged(v)),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: FareFieldBox(
                                        label: 'TOLLS',
                                        value: fare.tollCost,
                                        enabled: fare.includeTolls,
                                        onChanged: (v) => bloc.add(TollCostChanged(v)),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: FareFieldBox(
                                        label: 'DETOUR',
                                        value: fare.detourCost,
                                        onChanged: (v) => bloc.add(DetourCostChanged(v)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'e.g. Distance cost = ${fare.distanceKm.toStringAsFixed(1)} km × ₹${FareConstants.ratePerKm.toStringAsFixed(0)}',
                                  style: TextStyle(fontSize: 11, color: AppColors.grey500),
                                ),
                                const SizedBox(height: 12),
                                Divider(color: AppColors.grey200, height: 1),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total shared cost',
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                    Text(
                                      '₹${fare.totalSharedCost.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _SectionLabel('NUMBER OF RIDERS'),
                                        Text(
                                          '÷ split equally',
                                          style: TextStyle(fontSize: 11, color: AppColors.grey500),
                                        ),
                                      ],
                                    ),
                                    RiderCountStepper(
                                      count: fare.riderCount,
                                      max: state.vehicleType == 'bike' ? 1 : 4,
                                      onChanged: (v) => bloc.add(RiderCountChanged(v)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.info_outline, size: 16, color: AppColors.orange400),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Recommended fare is based on fuel, tolls & detour. '
                                        'Final cost may vary due to traffic, route changes, or '
                                        'additional tolls during the trip.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.orange400,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
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
                      border: Border.all(color: AppColors.primaryGreen, width: 1.5),
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
                    Text(
                      fromAddress,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      toAddress,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
              Icon(Icons.location_on_outlined, size: 15, color: AppColors.grey600),
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

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.fare,
    required this.isPublishing,
    required this.onContinue,
  });

  final FareBreakdown fare;
  final bool isPublishing;
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your earnings',
                      style: TextStyle(fontSize: 11, color: AppColors.grey600),
                    ),
                    Text(
                      '₹${fare.driverEarnings.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Per passenger',
                      style: TextStyle(fontSize: 11, color: AppColors.grey600),
                    ),
                    Text(
                      '₹${fare.farePerSeat.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ScheduleRideButton(
              onPressed: isPublishing ? null : onContinue,
              label: 'Continue to Offer Ride',
              isLoading: isPublishing,
            ),
          ],
        ),
      ),
    );
  }
}
