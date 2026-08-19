import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/core/utils/location_share_helper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:acepool/di/injection.dart';
import 'package:acepool/features/home/domain/entities/upcoming_trip.dart';
import 'package:acepool/features/home/presentation/bloc/home_bloc.dart';
import 'package:acepool/features/rides/domain/entities/ride_match.dart';
import 'package:acepool/features/rides/domain/repositories/rides_repository.dart';
import 'package:acepool/features/rides/presentation/pages/drives_detail_page.dart';
import 'package:acepool/features/rides/presentation/pages/ride_details_page.dart';
import 'package:acepool/features/trips/domain/entities/available_ride.dart';
import 'package:acepool/features/trips/domain/entities/driver_profile_stats.dart';
import 'package:acepool/features/trips/domain/entities/requested_ride.dart';
import 'package:acepool/features/trips/domain/repositories/trips_repository.dart';
import 'package:acepool/features/trips/presentation/bloc/trips_bloc.dart';
import 'package:acepool/features/trips/presentation/widgets/cancel_ride_dialog.dart';
import 'package:acepool/features/trips/presentation/widgets/drive_trip_card.dart';
import 'package:acepool/features/home/presentation/pages/pricing_page.dart';
import 'package:acepool/features/rides/presentation/pages/payment_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class TripsPage extends StatefulWidget {
  const TripsPage({super.key, this.onBack, this.initialFilter});

  final VoidCallback? onBack;
  final String? initialFilter;

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TripsBloc _bloc;

  bool _hasCommuteLocation = false;

  late String _findRideFilter;
  static const _findRideFilters = ['Suggested Rides', 'Ride Requests'];

  late final List<String> _tabs;
  late final String? _travelPreference;

  @override
  void initState() {
    super.initState();
    _bloc = sl<TripsBloc>();
    final homeState = context.read<HomeBloc>().state;
    _travelPreference = homeState.travelPreference;

    if (_travelPreference == 'ride') {
      _tabs = ['Find ride'];
    } else if (_travelPreference == 'drive') {
      _tabs = ['Offer ride'];
    } else {
      _tabs = ['Find ride', 'Offer ride'];
    }

    int initialIdx = 0;

    if (_travelPreference == 'drive') {
      initialIdx = 0; // The only tab is "Offer ride"
    } else if (_travelPreference == 'ride') {
      initialIdx = 0; // The only tab is "Find ride"
    } else {
      // Both
      if (widget.initialFilter != null) {
        initialIdx = 0; // "Find ride" tab
      } else {
        initialIdx = homeState.rideMode == RideMode.offer ? 1 : 0;
      }
    }

    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: initialIdx,
    );
    _tabController.addListener(() => setState(() {}));

    _hasCommuteLocation =
        (homeState.fromAddress?.trim().isNotEmpty ?? false) &&
        (homeState.toAddress?.trim().isNotEmpty ?? false);

    if (widget.initialFilter != null && _findRideFilters.contains(widget.initialFilter)) {
      _findRideFilter = widget.initialFilter!;
    } else {
      _findRideFilter = _hasCommuteLocation ? 'Suggested Rides' : 'Ride Requests';
    }

    _requestAvailableRidesFromHomeState();
    _bloc.add(const TripsDrivesRequested());
    _requestRideRequestsFromHomeState();
  }

  void _requestAvailableRidesFromHomeState() {
    final homeState = context.read<HomeBloc>().state;
    _bloc.add(
      TripsAvailableRidesRequested(
        fromAddress: homeState.fromAddress,
        toAddress: homeState.toAddress,
        fromLat: homeState.fromLat,
        fromLng: homeState.fromLng,
        toLat: homeState.toLat,
        toLng: homeState.toLng,
      ),
    );
  }

  void _requestRideRequestsFromHomeState() {
    final homeState = context.read<HomeBloc>().state;
    _bloc.add(
      TripsRequestedRidesRequested(
        homeFromAddress: homeState.fromAddress,
        homeToAddress: homeState.toAddress,
        homeFromLat: homeState.fromLat,
        homeFromLng: homeState.fromLng,
        homeToLat: homeState.toLat,
        homeToLng: homeState.toLng,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bloc.close();
    super.dispose();
  }

  Widget _buildList(
    TripsSectionStatus status,
    List<UpcomingTrip> trips,
    String emptyLabel, {
    void Function(UpcomingTrip)? onTap,
  }) {
    if (status == TripsSectionStatus.initial ||
        status == TripsSectionStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 64,
              color: AppColors.grey300,
            ),
            const SizedBox(height: 16),
            Text(
              emptyLabel,
              style: TextStyle(color: AppColors.grey500, fontSize: 16),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: trips.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final trip = trips[index];
        return DriveTripCard(
          trip: trip,
          onTap: () => onTap?.call(trip),
          onStartRide: () => _updateTripStatus(trip.id, 'in_progress'),
          onEndRide: () => _updateTripStatus(trip.id, 'completed'),
          onCancel: () => _handleCancelRide(trip),
          onEditFare: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PricingPage(
                  fromAddress: trip.fromAddress,
                  toAddress: trip.toAddress,
                  fromLat: trip.fromLat,
                  fromLng: trip.fromLng,
                  toLat: trip.toLat,
                  toLng: trip.toLng,
                  date: trip.date,
                  time: trip.time,
                  seatCount: trip.seatsTotal,
                  vehicleType: trip.vehicleType ?? 'car',
                  rideMode: 'offer',
                ),
              ),
            );
          },
          onEditPayment: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentPage(
                  rideId: trip.id,
                  rideData: {
                    'fromAddress': trip.fromAddress,
                    'toAddress': trip.toAddress,
                    'date': trip.date,
                    'time': {
                      'hour': trip.time.hour,
                      'minute': trip.time.minute,
                    },
                    'fare': {'farePerSeat': trip.farePerSeat},
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleCancelRide(UpcomingTrip trip) async {
    final tripsContext = context;
    await showDialog<void>(
      context: tripsContext,
      barrierDismissible: false,
      builder: (dialogContext) => CancelRideDialog(
        fromAddress: trip.fromAddress,
        toAddress: trip.toAddress,
        coPassengersCount: trip.seatsFilled,
        onCancelConfirmed: (reason) async {
          try {
            await sl<TripsRepository>().cancelOfferedRide(
              trip.id,
              reason: reason,
            );

            if (mounted) {
              Navigator.pop(dialogContext); // Close dialog
              tripsContext.push(
                '/ride-cancelled',
                extra: {
                  'fromAddress': trip.fromAddress,
                  'toAddress': trip.toAddress,
                },
              );
              _bloc.add(const TripsDrivesRequested());
              tripsContext.read<HomeBloc>().add(const RefreshUpcomingTrips());
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(tripsContext).showSnackBar(
                const SnackBar(
                  content: Text('Could not cancel ride. Please try again.'),
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _updateTripStatus(String tripId, String status) async {
    try {
      await sl<TripsRepository>().updateTripStatus(tripId, status);
      if (mounted) {
        context.read<HomeBloc>().add(const RefreshUpcomingTrips());
      }
      _bloc.add(const TripsDrivesRequested());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update trip: $e')));
      }
    }
  }

  Widget _buildTabToggle() {
    if (_tabs.length == 1) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Text(
            _tabs[0],
            style: GoogleFonts.mulish(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              height: 1.0,
            ),
          ),
        ),
      );
    }

    return Center(
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F1F2),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.10),
              blurRadius: 5,
              blurStyle: BlurStyle.inner,
            ),
          ],
        ),
        child: IntrinsicWidth(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(_tabs.length, (i) {
              final selected = _tabController.index == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _tabController.animateTo(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.toggleActiveBlack
                          : AppColors.transparent,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Text(
                      _tabs[i],
                      style: GoogleFonts.mulish(
                        color: selected ? AppColors.white : AppColors.black87,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 14,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<TripsBloc, TripsState>(
        builder: (context, tripsState) => _buildScaffold(context, tripsState),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, TripsState tripsState) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Trips',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
            child: _buildTabToggle(),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          if (_travelPreference != 'drive')
            // Find ride tab
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: 45,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F1F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFDDDDDD)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _findRideFilter,
                            isDense: true,
                            items: _findRideFilters
                                .map(
                                  (f) => DropdownMenuItem(
                                    value: f,
                                    child: Text(
                                      f,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _findRideFilter = val);
                              }
                            },
                            icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _findRideFilter == 'Suggested Rides'
                      ? _buildAvailableRidesSection(tripsState)
                      : _buildRequestedRidesSection(tripsState),
                ),
              ],
            ),

          if (_travelPreference != 'ride')
            // Offer ride tab
            _buildList(
              tripsState.drivesStatus,
              tripsState.drives,
              'You haven\'t offered any rides yet.',
              onTap: (trip) {
                final homeBloc = context.read<HomeBloc>();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: homeBloc,
                      child: DrivesDetailPage(trip: trip),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAvailableRidesSection(TripsState tripsState) {
    if (tripsState.availableRidesStatus == TripsSectionStatus.initial ||
        tripsState.availableRidesStatus == TripsSectionStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!tripsState.hasCommuteLocation) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'Enter your commute details on the Home tab to find matching rides.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.grey600, fontSize: 16),
          ),
        ),
      );
    }
    final rides = tripsState.availableRides;
    if (rides.isEmpty) {
      return Center(
        child: Text(
          'No matching rides found for your commute.',
          style: TextStyle(color: AppColors.grey500, fontSize: 16),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => _requestAvailableRidesFromHomeState(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: rides.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) => _AvailableRideCard(
          ride: rides[index],
          onRequested: () {
            _requestAvailableRidesFromHomeState();
            _requestRideRequestsFromHomeState();
          },
          onFindDriver: () {
            final r = rides[index];
            final homeBloc = context.read<HomeBloc>();
            homeBloc.add(FromAddressChanged(r.userFromAddress, lat: r.userFromLat, lng: r.userFromLng));
            homeBloc.add(ToAddressChanged(r.userToAddress, lat: r.userToLat, lng: r.userToLng));
            
            _bloc.add(
              TripsAvailableRidesRequested(
                fromAddress: r.userFromAddress,
                toAddress: r.userToAddress,
                fromLat: r.userFromLat,
                fromLng: r.userFromLng,
                toLat: r.userToLat,
                toLng: r.userToLng,
              ),
            );
            setState(() {
              _findRideFilter = 'Suggested Rides';
            });
          },
        ),
      ),
    );
  }

  Widget _buildRequestedRidesSection(TripsState tripsState) {
    if (tripsState.requestedRidesStatus == TripsSectionStatus.initial ||
        tripsState.requestedRidesStatus == TripsSectionStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final requests = tripsState.requestedRides;
    if (requests.isEmpty) {
      return Center(
        child: Text(
          'You haven\'t requested any rides yet.',
          style: TextStyle(color: AppColors.grey500, fontSize: 16),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => _requestRideRequestsFromHomeState(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) => _RequestedRideCard(
          request: requests[index],
          onCancelled: () => _requestRideRequestsFromHomeState(),
          onFindDriver: () {
            final r = requests[index];
            final homeBloc = context.read<HomeBloc>();
            homeBloc.add(FromAddressChanged(r.riderStartAddress, lat: r.riderStartLat, lng: r.riderStartLng));
            homeBloc.add(ToAddressChanged(r.riderEndAddress, lat: r.riderEndLat, lng: r.riderEndLng));
            
            _bloc.add(
              TripsAvailableRidesRequested(
                fromAddress: r.riderStartAddress,
                toAddress: r.riderEndAddress,
                fromLat: r.riderStartLat,
                fromLng: r.riderStartLng,
                toLat: r.riderEndLat,
                toLng: r.riderEndLng,
              ),
            );
            setState(() {
              _findRideFilter = 'Suggested Rides';
            });
          },
        ),
      ),
    );
  }
}

class _AvailableRideCard extends StatefulWidget {
  const _AvailableRideCard({
    required this.ride,
    required this.onRequested,
    this.onFindDriver,
  });

  final AvailableRide ride;
  final VoidCallback onRequested;
  final VoidCallback? onFindDriver;

  @override
  State<_AvailableRideCard> createState() => _AvailableRideCardState();
}

class _AvailableRideCardState extends State<_AvailableRideCard> {
  final _messageController = TextEditingController();
  final _priceController = TextEditingController();
  bool _submitting = false;
  bool _justRequested = false;
  bool _negotiating = false;
  bool _offerSent = false;
  bool _offerDeclined = false;
  String _offeredPrice = '';

  @override
  void initState() {
    super.initState();
    if (widget.ride.negotiatedPrice != null) {
      _offeredPrice = widget.ride.negotiatedPrice!.toInt().toString();
      if (widget.ride.negotiationStatus == 'declined') {
        _offerDeclined = true;
      } else {
        _offerSent = true;
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _requestRide() async {
    final messageText = _messageController.text.trim();
    if (_submitting) return;

    final requested = widget.ride.alreadyRequested || _justRequested;

    if (requested) {
      if (messageText.isEmpty) return;
      setState(() => _submitting = true);
      try {
        await _sendMessage(messageText);
        if (mounted) {
          _messageController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Message sent to driver')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
        }
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
      return;
    }

    setState(() => _submitting = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await sl<TripsRepository>().requestAvailableRide(
        ride: widget.ride,
        message: messageText,
        negotiatedPrice: _offerSent ? double.tryParse(_offeredPrice) : null,
      );

      if (messageText.isNotEmpty) {
        await _sendMessage(messageText);
      }

      if (mounted) {
        setState(() {
          _justRequested = true;
          _submitting = false;
        });
        _messageController.clear();
        widget.onRequested();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not request ride: $e')));
      }
    }
  }

  Future<void> _sendMessage(String text) async {
    await sl<RidesRepository>().sendRideChatMessage(
      driverId: widget.ride.driverId,
      driverName: widget.ride.driverName,
      text: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.ride;
    final requested = r.alreadyRequested || _justRequested;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDDDDD)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top banner + match% overlay ──
          SizedBox(
            width: double.infinity,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  child: ColoredBox(
                    color: AppColors.primaryGreen,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.person_outline,
                            color: Colors.white,
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${r.seatsFilled}/${r.seatsTotal} seats filled',
                            style: GoogleFonts.mulish(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 18 / 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${r.matchPercent}% Match',
                        style: GoogleFonts.mulish(
                          color: AppColors.primaryGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 18 / 14,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.more_vert,
                        size: 18,
                        color: Color(0xFF757474),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      r.dateLabel,
                      style: GoogleFonts.mulish(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        height: 18 / 16,
                        color: const Color(0xFF1E1E1E),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.directions_walk,
                          size: 12,
                          color: Color(0xFF757474),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          r.distanceLabel ?? '500 m',
                          style: GoogleFonts.mulish(
                            fontSize: 12,
                            color: const Color(0xFF757474),
                            fontWeight: FontWeight.w600,
                            height: 18 / 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.chevron_right,
                          size: 14,
                          color: Color(0xFFDDDDDD),
                        ),
                        const SizedBox(width: 6),
                        Image.asset(
                          'assets/images/location_pin.png',
                          width: 14,
                          height: 14,
                          color: const Color(0xFF757474),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Row: time + vehicle pill ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      r.timeLabel,
                      style: GoogleFonts.mulish(
                        color: const Color(0xFF1E1E1E),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 18 / 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFDDDDDD)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            r.vehicleType == 'bike'
                                ? Icons.two_wheeler
                                : Icons.directions_car,
                            size: 14,
                            color: const Color(0xFF1D1D1D),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            r.vehicleType == 'bike' ? 'Bike' : 'Car',
                            style: GoogleFonts.mulish(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF1D1D1D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                const Divider(height: 1, color: Color(0xFFDDDDDD)),
                const SizedBox(height: 8),

                // Driver info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFF0F1F2),
                      backgroundImage: r.driverPhotoUrl.isNotEmpty
                          ? NetworkImage(r.driverPhotoUrl)
                          : null,
                      child: r.driverPhotoUrl.isEmpty
                          ? const Icon(Icons.person, color: Color(0xFFB6B6B6))
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.driverName,
                            style: GoogleFonts.mulish(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              height: 18 / 16,
                              color: const Color(0xFF1D1D1D),
                            ),
                          ),
                          Text(
                            'Verified ID',
                            style: GoogleFonts.mulish(
                              color: const Color(0xFF757474),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 18 / 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: r.driverPhone.isNotEmpty
                          ? () => LocationShareHelper.launchDialer(
                                r.driverPhone,
                              )
                          : null,
                      child: const Icon(
                        Icons.phone_outlined,
                        size: 18,
                        color: Color(0xFF757474),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '|',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {},
                      child: Image.asset(
                        'assets/images/chat_square.png',
                        width: 18,
                        height: 18,
                        color: const Color(0xFF757474),
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.chat_bubble_outline,
                          size: 18,
                          color: Color(0xFF757474),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    _dot(filled: false),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        r.fromAddress,
                        style: GoogleFonts.mulish(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 18 / 16,
                          color: const Color(0xFF4C515B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      3,
                      (i) => Container(
                        width: 1.5,
                        height: 3,
                        margin: EdgeInsets.only(
                          top: i == 0 ? 0 : 1,
                          bottom: i == 2 ? 0 : 1,
                        ),
                        color: const Color(0xFFDDDDDD),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    _dot(filled: true),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        r.toAddress,
                        style: GoogleFonts.mulish(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 18 / 16,
                          color: const Color(0xFF4C515B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(color: Color(0xFFDDDDDD), height: 1),
                const SizedBox(height: 12),

                // ── Price + Negotiate ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      r.farePerSeat != null
                          ? '₹${r.farePerSeat!.toStringAsFixed(2)} / seat'
                          : 'Fare not set',
                      style: GoogleFonts.mulish(
                        color: const Color(0xFF1B8A3F),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 18 / 16,
                      ),
                    ),
                    if (_offerDeclined)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC82323).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFC82323).withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          '₹ $_offeredPrice - Declined',
                          style: GoogleFonts.mulish(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 16.5 / 12,
                            color: const Color(0xFFC82323),
                          ),
                        ),
                      )
                    else if (_offerSent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF046B4B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF046B4B).withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          'Offer : ₹ $_offeredPrice',
                          style: GoogleFonts.mulish(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 16.5 / 12,
                            color: const Color(0xFF046B4B),
                          ),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _negotiating = !_negotiating;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDDDDDD).withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFDDDDDD)),
                          ),
                          child: Text(
                            _negotiating ? 'Cancel' : 'Negotiate',
                            style: GoogleFonts.mulish(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 16.5 / 12,
                              color: const Color(0xFF1E1E1E),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                if (_offerDeclined) ...[
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFFC82323), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Driver declined your offer. Try a higher offer or find another driver.',
                          style: GoogleFonts.mulish(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 1.4, // 20 / 14
                            color: const Color(0xFFC82323),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onFindDriver,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFDDDDDD)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: const Color(0xFF1E1E1E),
                          ),
                          child: Text(
                            'Find Driver',
                            style: GoogleFonts.mulish(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _offerDeclined = false;
                              _negotiating = true;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFEFEFE),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFFDDDDDD)),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Revise Offer',
                            style: GoogleFonts.mulish(
                              color: const Color(0xFF1E1E1E),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ] else if (_offerSent) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Offer Sent - waiting for driver to respond',
                    style: GoogleFonts.mulish(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.125, // 18/16
                      color: const Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else if (_negotiating) ...[
                  const SizedBox(height: 16),
                  Text(
                    'What would you like to offer ?',
                    style: GoogleFonts.mulish(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.125, // 18/16
                      color: const Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDDDDD).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDDDDDD)),
                    ),
                    child: TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.mulish(fontSize: 16, color: const Color(0xFF1E1E1E)),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Enter your price',
                        hintStyle: TextStyle(fontSize: 16, color: Color(0xFF616874), fontWeight: FontWeight.normal),
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.currency_rupee, size: 16, color: Color(0xFF1E1E1E)),
                        prefixIconConstraints: BoxConstraints(minWidth: 24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _offerSent = true;
                        _offeredPrice = _priceController.text;
                        _negotiating = false;
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Send Offer - ₹ ${_priceController.text.isEmpty ? '0' : _priceController.text}/seat',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.mulish(
                          color: const Color(0xFFFEFEFE),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFDDDDDD)),
                const SizedBox(height: 16),

                Text(
                  'Payment Method',
                  style: GoogleFonts.mulish(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.125, // 18/16
                    color: const Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined, size: 20, color: Color(0xFF1E1E1E)),
                        const SizedBox(width: 6),
                        Text(
                          'UPI',
                          style: GoogleFonts.mulish(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                            color: const Color(0xFF1E1E1E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.payments_outlined, size: 20, color: Color(0xFF1E1E1E)),
                        const SizedBox(width: 4),
                        Text(
                          'Cash',
                          style: GoogleFonts.mulish(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                            color: const Color(0xFF1E1E1E),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 4,
                    top: 4,
                    bottom: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F1F2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          enabled: !_submitting,
                          style: GoogleFonts.mulish(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            height: 18 / 16,
                            color: const Color(0xFF616874),
                          ),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: requested
                                ? 'Request Sent. Share a message'
                                : 'Share message with driver',
                            hintStyle: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF616874),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 6,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _submitting ? null : _requestRide,
                        child: Container(
                          padding: _messageController.text.trim().isEmpty && requested
                              ? const EdgeInsets.all(10)
                              : const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                          decoration: BoxDecoration(
                            color: _messageController.text.trim().isEmpty && requested
                                ? Colors.transparent
                                : (_messageController.text.trim().isEmpty && !requested
                                    ? const Color(0xFFDDDDDD)
                                    : AppColors.primaryGreen),
                            borderRadius: BorderRadius.circular(30),
                            border: _messageController.text.trim().isEmpty && requested
                                ? Border.all(color: AppColors.primaryGreen, width: 1.5)
                                : null,
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : _messageController.text.trim().isEmpty && requested
                                  ? const Icon(
                                      Icons.check,
                                      color: AppColors.primaryGreen,
                                      size: 20,
                                    )
                                  : Text(
                                      _messageController.text.trim().isNotEmpty
                                          ? 'Send'
                                          : 'Requested',
                                      style: GoogleFonts.mulish(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        height: 1.28, // 18 / 14
                                      ),
                                    ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RideDetailsPage(
                            ride: RideMatch(
                              id: r.id,
                              driverId: r.driverId,
                              driverName: r.driverName,
                              date: r.date,
                              time: r.time,
                              fromAddress: r.fromAddress,
                              toAddress: r.toAddress,
                              seatsFilled: r.seatsFilled,
                              seatsTotal: r.seatsTotal,
                              vehicleType: r.vehicleType,
                              alreadyRequested: r.alreadyRequested,
                              distanceKm: r.distanceKm,
                              matchPercent: r.matchPercent,
                              farePerSeat: r.farePerSeat,
                              fromLat: r.fromLat,
                              fromLng: r.fromLng,
                              toLat: r.toLat,
                              toLng: r.toLng,
                            ),
                            riderFromAddress: r.userFromAddress,
                            riderFromLat: r.userFromLat,
                            riderFromLng: r.userFromLng,
                            riderToAddress: r.userToAddress,
                            riderToLat: r.userToLat,
                            riderToLng: r.userToLng,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'View Ride Details',
                      style: GoogleFonts.mulish(
                        fontSize: 14,
                        color: const Color(0xFF616874),
                        fontWeight: FontWeight.w400,
                        height: 18 / 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot({required bool filled}) {
    return Container(
      width: 10,
      height: 10,
      decoration: filled
          ? const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryGreen,
            )
          : BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryGreen, width: 1.5),
            ),
    );
  }
}

class _RequestedRideCard extends StatefulWidget {
  const _RequestedRideCard({
    required this.request,
    required this.onCancelled,
    required this.onFindDriver,
  });

  final RequestedRide request;
  final VoidCallback onCancelled;
  final VoidCallback onFindDriver;

  @override
  State<_RequestedRideCard> createState() => _RequestedRideCardState();
}

class _RequestedRideCardState extends State<_RequestedRideCard> {
  final _messageController = TextEditingController();
  final _priceController = TextEditingController();
  bool _submitting = false;
  bool _negotiating = false;
  bool _offerSent = false;
  bool _offerDeclined = false;
  String _offeredPrice = '';

  @override
  void initState() {
    super.initState();
    if (widget.request.negotiatedPrice != null) {
      _offeredPrice = widget.request.negotiatedPrice!.toInt().toString();
      if (widget.request.negotiationStatus == 'declined') {
        _offerDeclined = true;
      } else {
        _offerSent = true;
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _submitting) return;

    setState(() => _submitting = true);
    try {
      await sl<RidesRepository>().sendRideChatMessage(
        driverId: widget.request.driverId,
        driverName: widget.request.driverName,
        text: text,
      );

      if (mounted) {
        _messageController.clear();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Message sent to driver')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _handleCancelRequest() async {
    final r = widget.request;
    final riderContext = context;
    await showDialog<void>(
      context: riderContext,
      barrierDismissible: false,
      builder: (dialogContext) => CancelRideDialog(
        fromAddress: r.fromAddress,
        toAddress: r.toAddress,
        coPassengersCount: r.seatsFilled,
        onCancelConfirmed: (reason) async {
          try {
            await sl<TripsRepository>().cancelRideRequest(
              requestId: r.id,
              rideId: r.rideId,
              reason: reason,
            );

            if (mounted) {
              Navigator.pop(dialogContext); // Close dialog
              riderContext.push(
                '/ride-cancelled',
                extra: {'fromAddress': r.fromAddress, 'toAddress': r.toAddress},
              );
              widget.onCancelled();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(riderContext).showSnackBar(
                const SnackBar(
                  content: Text('Could not cancel ride. Please try again.'),
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _showDriverProfile(BuildContext context) async {
    final r = widget.request;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: FutureBuilder<DriverProfileStats>(
          future: sl<TripsRepository>().getDriverProfileStats(r.driverId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final stats = snapshot.data ?? const DriverProfileStats();
            final employeeId = stats.employeeId;
            final completedRides = stats.completedRidesCount;
            final rating = stats.rating;
            final ratingCount = stats.ratingCount;

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.grey200,
                            backgroundImage: r.driverPhotoUrl.isNotEmpty
                                ? NetworkImage(r.driverPhotoUrl)
                                : null,
                            child: r.driverPhotoUrl.isEmpty
                                ? Icon(
                                    Icons.person,
                                    size: 40,
                                    color: AppColors.grey400,
                                  )
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  r.driverName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: r.driverPhone.isNotEmpty
                                          ? () =>
                                                LocationShareHelper.launchDialer(
                                                  r.driverPhone,
                                                )
                                          : null,
                                      child: Icon(
                                        Icons.phone_outlined,
                                        size: 18,
                                        color: AppColors.grey600,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '|',
                                      style: TextStyle(
                                        color: AppColors.grey400,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    GestureDetector(
                                      onTap: () {},
                                      child: Icon(
                                        Icons.chat_bubble_outline,
                                        size: 18,
                                        color: AppColors.grey600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Text(
                              employeeId,
                              style: TextStyle(
                                color: AppColors.grey500,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$completedRides rides completed',
                              style: TextStyle(
                                color: AppColors.grey600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primaryGreen,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Verified ID',
                                  style: TextStyle(
                                    color: AppColors.grey600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.orange,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$rating ($ratingCount)',
                                  style: TextStyle(
                                    color: AppColors.grey600,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDDDDD)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top banner + match% overlay
          SizedBox(
            width: double.infinity,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  child: ColoredBox(
                    color: AppColors.primaryGreen,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.person_outline,
                            color: Colors.white,
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${r.seatsFilled}/${r.seatsTotal} seats filled',
                            style: GoogleFonts.mulish(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 18 / 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${r.matchPercent}% Match',
                        style: GoogleFonts.mulish(
                          color: AppColors.primaryGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 18 / 14,
                        ),
                      ),
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.more_vert,
                          color: Color(0xFF757474),
                          size: 18,
                        ),
                        onSelected: (val) {
                          if (val == 'cancel') _handleCancelRequest();
                        },
                        offset: const Offset(8, 0),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'cancel',
                            child: Row(
                              children: [
                                Icon(Icons.cancel_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('Cancel Ride'),
                              ],
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

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      r.dateLabel,
                      style: GoogleFonts.mulish(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        height: 18 / 16,
                        color: const Color(0xFF1E1E1E),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.directions_walk,
                          size: 12,
                          color: Color(0xFF757474),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          r.distanceLabel ?? '500 m',
                          style: GoogleFonts.mulish(
                            fontSize: 12,
                            color: const Color(0xFF757474),
                            fontWeight: FontWeight.w600,
                            height: 18 / 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.chevron_right,
                          size: 14,
                          color: Color(0xFFDDDDDD),
                        ),
                        const SizedBox(width: 6),
                        Image.asset(
                          'assets/images/location_pin.png',
                          width: 14,
                          height: 14,
                          color: const Color(0xFF757474),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 14),

                // ── Row: time + vehicle pill ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      r.timeLabel,
                      style: GoogleFonts.mulish(
                        color: const Color(0xFF1E1E1E),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 18 / 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFDDDDDD)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            r.vehicleType == 'bike'
                                ? Icons.two_wheeler
                                : Icons.directions_car,
                            size: 14,
                            color: const Color(0xFF1D1D1D),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            r.vehicleType == 'bike' ? 'Bike' : 'Car',
                            style: GoogleFonts.mulish(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF1D1D1D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),
                const Divider(height: 1, color: Color(0xFFDDDDDD)),
                const SizedBox(height: 6),

                // Driver info
                GestureDetector(
                  onTap: () => _showDriverProfile(context),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFF0F1F2),
                        backgroundImage: r.driverPhotoUrl.isNotEmpty
                            ? NetworkImage(r.driverPhotoUrl)
                            : null,
                        child: r.driverPhotoUrl.isEmpty
                            ? const Icon(Icons.person, color: Color(0xFFB6B6B6))
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.driverName,
                              style: GoogleFonts.mulish(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                height: 18 / 16,
                                color: const Color(0xFF1D1D1D),
                              ),
                            ),
                            Text(
                              'Verified ID',
                              style: GoogleFonts.mulish(
                                color: const Color(0xFF757474),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                height: 18 / 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: r.driverPhone.isNotEmpty
                            ? () => LocationShareHelper.launchDialer(
                                r.driverPhone,
                              )
                            : null,
                        child: const Icon(
                          Icons.phone_outlined,
                          size: 18,
                          color: Color(0xFF757474),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '|',
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {},
                        child: Image.asset(
                          'assets/images/chat_square.png',
                          width: 18,
                          height: 18,
                          color: const Color(0xFF757474),
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.chat_bubble_outline,
                            size: 18,
                            color: Color(0xFF757474),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    _dot(filled: false),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        r.fromAddress,
                        style: GoogleFonts.mulish(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 18 / 16,
                          color: const Color(0xFF4C515B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Container(
                    width: 1.5,
                    height: 10,
                    color: const Color(0xFFDDDDDD),
                  ),
                ),
                Row(
                  children: [
                    _dot(filled: true),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        r.toAddress,
                        style: GoogleFonts.mulish(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 18 / 16,
                          color: const Color(0xFF4C515B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(color: Color(0xFFDDDDDD), height: 1),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      r.farePerSeat != null
                          ? '₹${r.farePerSeat!.toStringAsFixed(2)} / seat'
                          : 'Fare not set',
                      style: GoogleFonts.mulish(
                        color: const Color(0xFF1B8A3F),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 18 / 16,
                      ),
                    ),
                    if (_offerDeclined)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC82323).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFC82323).withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          '₹ $_offeredPrice - Declined',
                          style: GoogleFonts.mulish(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 16.5 / 12,
                            color: const Color(0xFFC82323),
                          ),
                        ),
                      )
                    else if (_offerSent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF046B4B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF046B4B).withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          'Offer : ₹ $_offeredPrice',
                          style: GoogleFonts.mulish(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 16.5 / 12,
                            color: const Color(0xFF046B4B),
                          ),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _negotiating = !_negotiating;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDDDDDD).withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFDDDDDD)),
                          ),
                          child: Text(
                            _negotiating ? 'Cancel' : 'Negotiate',
                            style: GoogleFonts.mulish(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 16.5 / 12,
                              color: const Color(0xFF1E1E1E),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                if (_offerDeclined) ...[
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFFC82323), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Driver declined your offer. Try a higher offer or find another driver.',
                          style: GoogleFonts.mulish(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 1.4, // 20 / 14
                            color: const Color(0xFFC82323),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onFindDriver,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFDDDDDD)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: const Color(0xFF1E1E1E),
                          ),
                          child: Text(
                            'Find Driver',
                            style: GoogleFonts.mulish(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _offerDeclined = false;
                              _negotiating = true;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFEFEFE),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFFDDDDDD)),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Revise Offer',
                            style: GoogleFonts.mulish(
                              color: const Color(0xFF1E1E1E),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ] else if (_offerSent) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Offer Sent - waiting for driver to respond',
                    style: GoogleFonts.mulish(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.125, // 18/16
                      color: const Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else if (_negotiating) ...[
                  const SizedBox(height: 16),
                  Text(
                    'What would you like to offer ?',
                    style: GoogleFonts.mulish(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.125, // 18/16
                      color: const Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDDDDD).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDDDDDD)),
                    ),
                    child: TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.mulish(fontSize: 16, color: const Color(0xFF1E1E1E)),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Enter your price',
                        hintStyle: TextStyle(fontSize: 16, color: Color(0xFF616874), fontWeight: FontWeight.normal),
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.currency_rupee, size: 16, color: Color(0xFF1E1E1E)),
                        prefixIconConstraints: BoxConstraints(minWidth: 24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _offerSent = true;
                        _offeredPrice = _priceController.text;
                        _negotiating = false;
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Send Offer - ₹ ${_priceController.text.isEmpty ? '0' : _priceController.text}/seat',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.mulish(
                          color: const Color(0xFFFEFEFE),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFDDDDDD)),
                const SizedBox(height: 16),

                Text(
                  'Payment Method',
                  style: GoogleFonts.mulish(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.125, // 18/16
                    color: const Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined, size: 20, color: Color(0xFF1E1E1E)),
                        const SizedBox(width: 6),
                        Text(
                          'UPI',
                          style: GoogleFonts.mulish(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                            color: const Color(0xFF1E1E1E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.payments_outlined, size: 20, color: Color(0xFF1E1E1E)),
                        const SizedBox(width: 4),
                        Text(
                          'Cash',
                          style: GoogleFonts.mulish(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                            color: const Color(0xFF1E1E1E),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 4,
                    top: 4,
                    bottom: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F1F2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          enabled: !_submitting,
                          style: GoogleFonts.mulish(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            height: 18 / 16,
                            color: const Color(0xFF616874),
                          ),
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'Request Sent. Share a message',
                            hintStyle: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF616874),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 6,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _submitting ? null : _sendMessage,
                        child: Container(
                          padding: _messageController.text.trim().isEmpty
                              ? const EdgeInsets.all(10)
                              : const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                          decoration: BoxDecoration(
                            color: _messageController.text.trim().isEmpty
                                ? Colors.transparent
                                : AppColors.primaryGreen,
                            borderRadius: BorderRadius.circular(30),
                            border: _messageController.text.trim().isEmpty
                                ? Border.all(color: AppColors.primaryGreen, width: 1.5)
                                : null,
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : _messageController.text.trim().isEmpty
                                  ? const Icon(
                                      Icons.check,
                                      color: AppColors.primaryGreen,
                                      size: 20,
                                    )
                                  : Text(
                                      'Send',
                                      style: GoogleFonts.mulish(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        height: 1.28, // 18 / 14
                                      ),
                                    ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RideDetailsPage(
                            ride: RideMatch(
                              id: r.rideId,
                              driverId: r.driverId,
                              driverName: r.driverName,
                              driverPhotoUrl: r.driverPhotoUrl,
                              date: r.date,
                              time: r.time,
                              fromAddress: r.fromAddress,
                              toAddress: r.toAddress,
                              seatsFilled: r.seatsFilled,
                              seatsTotal: r.seatsTotal,
                              vehicleType: r.vehicleType,
                              alreadyRequested: true,
                              distanceKm: null,
                              matchPercent: 100,
                              farePerSeat: r.farePerSeat,
                            ),
                            riderFromAddress: r.riderStartAddress,
                            riderToAddress: r.riderEndAddress,
                            riderFromLat: r.riderStartLat,
                            riderFromLng: r.riderStartLng,
                            riderToLat: r.riderEndLat,
                            riderToLng: r.riderEndLng,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'View Ride Details',
                      style: GoogleFonts.mulish(
                        fontSize: 14,
                        color: const Color(0xFF616874),
                        fontWeight: FontWeight.w400,
                        height: 18 / 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot({required bool filled}) {
    return Container(
      width: 10,
      height: 10,
      decoration: filled
          ? const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryGreen,
            )
          : BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryGreen, width: 1.5),
            ),
    );
  }
}
