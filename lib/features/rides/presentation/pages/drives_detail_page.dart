import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/core/utils/ride_matcher.dart';
import 'package:acepool/di/injection.dart';
import 'package:get_it/get_it.dart';
import 'package:acepool/features/home/presentation/pages/pricing_page.dart';
import 'package:acepool/features/rides/presentation/pages/payment_page.dart';
import 'package:acepool/features/chat/domain/repositories/chat_repository.dart';
import 'package:acepool/features/chat/presentation/pages/chat_page.dart';
import 'package:acepool/features/home/domain/entities/upcoming_trip.dart';
import 'package:acepool/features/home/presentation/bloc/home_bloc.dart';
import 'package:acepool/features/rides/domain/entities/ride_rider.dart';
import 'package:acepool/features/rides/domain/repositories/rides_repository.dart';
import 'package:acepool/features/rides/presentation/bloc/drives_detail_bloc.dart';
import 'package:acepool/features/rides/presentation/pages/ride_map_page.dart';
import 'package:acepool/features/trips/presentation/widgets/drive_trip_card.dart';
import 'package:acepool/features/trips/presentation/widgets/cancel_ride_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DrivesDetailPage extends StatefulWidget {
  const DrivesDetailPage({super.key, required this.trip});

  final UpcomingTrip trip;

  @override
  State<DrivesDetailPage> createState() => _DrivesDetailPageState();
}

class _DrivesDetailPageState extends State<DrivesDetailPage> {
  late final DrivesDetailBloc _bloc;
  int _lastStatusTick = 0;

  @override
  void initState() {
    super.initState();
    _bloc = GetIt.instance<DrivesDetailBloc>()..add(DrivesDetailStarted(widget.trip));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  Future<void> _handleCancelRide(UpcomingTrip currentTrip) async {
    final detailContext = context;
    await showDialog<void>(
      context: detailContext,
      barrierDismissible: false,
      builder: (dialogContext) => CancelRideDialog(
        fromAddress: currentTrip.fromAddress,
        toAddress: currentTrip.toAddress,
        coPassengersCount: currentTrip.seatsFilled,
        onCancelConfirmed: (reason) async {
          try {
            await GetIt.instance<RidesRepository>().cancelRide(currentTrip.id, reason: reason);

            if (mounted) {
              Navigator.pop(dialogContext); // Close dialog
              detailContext.push(
                '/ride-cancelled',
                extra: {
                  'fromAddress': currentTrip.fromAddress,
                  'toAddress': currentTrip.toAddress,
                },
              );
              detailContext.read<HomeBloc>().add(const RefreshUpcomingTrips());
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(detailContext).showSnackBar(
                const SnackBar(
                    content: Text('Could not cancel ride. Please try again.')),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _confirmCancelRider(
      BuildContext context, String riderName, String requestId) async {
    var isCancelling = false;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.warning_amber_rounded,
                      color: Colors.red[600], size: 30),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Cancel this ride?',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  riderName.isNotEmpty
                      ? '$riderName will be removed from this trip and notified of the cancellation. This action cannot be undone.'
                      : 'This rider will be removed from this trip. This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13.5, color: Colors.grey[600], height: 1.4),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isCancelling
                            ? null
                            : () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: BorderSide(color: Colors.grey[300]!),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text('Keep ride',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isCancelling
                            ? null
                            : () async {
                                setDialogState(() => isCancelling = true);
                                await GetIt.instance<RidesRepository>().cancelRiderRequest(
                                  requestId: requestId,
                                  rideId: widget.trip.id,
                                );
                                _bloc.add(const DrivesDetailReloadRequested());
                                if (ctx.mounted) Navigator.of(ctx).pop();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.red[300],
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                        child: isCancelling
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Cancel ride',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openMap(List<RideRider> riders) {
    final List<PickupPoint> points = [];

    // Add driver's dynamic start point
    points.add(PickupPoint(
      location: widget.trip.fromAddress.split(',')[0],
      sub: 'Start Point',
      time: widget.trip.timeLabel,
      position: LatLng(widget.trip.fromLat ?? 0, widget.trip.fromLng ?? 0),
      isFirst: true,
      isPinned: false,
      iconColor: const Color(0xFF00A19A),
    ));

    // Add riders as dynamic pickup points
    for (var r in riders) {
        final position = (r.pickupLat != null && r.pickupLng != null)
            ? LatLng(r.pickupLat!, r.pickupLng!)
            : LatLng(widget.trip.fromLat ?? 0, widget.trip.fromLng ?? 0);
        final dropOffPosition = (r.dropOffLat != null && r.dropOffLng != null)
            ? LatLng(r.dropOffLat!, r.dropOffLng!)
            : null;
        points.add(PickupPoint(
            location: r.pickupPoint.split(',')[0],
            sub: 'Rider Pickup',
            time: r.pickupTimeLabel,
            position: position,
            dropOffPosition: dropOffPosition,
            isPinned: false,
            iconColor: Colors.grey,
        ));
    }

    // Add dynamic trip destination
    points.add(PickupPoint(
      location: widget.trip.toAddress.split(',')[0],
      sub: 'Destination',
      time: '10:30',
      position: LatLng(widget.trip.toLat ?? 0, widget.trip.toLng ?? 0),
      isLast: true,
      iconColor: Colors.red.shade400,
    ));

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RideMapPage(
            trip: widget.trip,
            pickupPoints: points,
          ),
        ),
      );
    }
  }

  Future<void> _onChatTap(List<RideRider> riders) async {
    final myId = FirebaseAuth.instance.currentUser?.uid;
    if (myId == null) return;

    final participantIds = riders.map((r) => r.riderId).toList();
    participantIds.add(myId);

    final participantNames = {
      for (var r in riders) r.riderId: r.riderName,
      myId: FirebaseAuth.instance.currentUser?.displayName ?? 'Driver'
    };

    final participantPhotos = {
      for (var r in riders) if (r.riderPhotoUrl != null) r.riderId: r.riderPhotoUrl!,
      if (FirebaseAuth.instance.currentUser?.photoURL != null)
        myId: FirebaseAuth.instance.currentUser!.photoURL!
    };

    await GetIt.instance<RidesRepository>().ensureGroupChat(
      rideId: widget.trip.id,
      groupTitle: "${widget.trip.dateLabel} ; ${widget.trip.timeLabel}",
      rideDate: widget.trip.date,
      participantIds: participantIds,
      participantNames: participantNames,
      participantPhotos: participantPhotos,
    );

    final profileImages = riders
        .where((r) => r.riderPhotoUrl != null)
        .map((r) => r.riderPhotoUrl!)
        .toList();

    if (mounted) {
      final namesList = participantNames.entries
          .map((e) => e.key == myId ? "You" : e.value)
          .toList();

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatPage(
            chatId: widget.trip.id,
            title: "${widget.trip.dateLabel} ; ${widget.trip.timeLabel}",
            subtitle: namesList.join(', '),
            profileImages: profileImages,
            participantNames: participantNames,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<DrivesDetailBloc, DrivesDetailState>(
        listener: (context, state) {
          if (state.statusUpdateTick != _lastStatusTick) {
            _lastStatusTick = state.statusUpdateTick;
            context.read<HomeBloc>().add(const RefreshUpcomingTrips());
            if (state.lastUpdatedStatus == 'completed' ||
                state.lastUpdatedStatus == 'cancelled') {
              Navigator.of(context).pop();
            }
          }
          if (state.snackbarMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.snackbarMessage!)),
            );
          }
        },
        builder: (context, state) {
          final currentTrip = state.currentTrip ?? widget.trip;
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const Expanded(
                          child: Text(
                            'Drives',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48), // Spacer for centering title
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DriveTripCard(
                            trip: currentTrip,
                            showViewDetails: false,
                            onCancel: () => _handleCancelRide(currentTrip),
                            onChatTap: () => _onChatTap(state.riders),
                            onEditFare: () async {
                              final updated = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PricingPage(
                                    fromAddress: currentTrip.fromAddress,
                                    toAddress: currentTrip.toAddress,
                                    fromLat: currentTrip.fromLat,
                                    fromLng: currentTrip.fromLng,
                                    toLat: currentTrip.toLat,
                                    toLng: currentTrip.toLng,
                                    date: currentTrip.date,
                                    time: currentTrip.time,
                                    seatCount: currentTrip.seatsTotal,
                                    vehicleType: currentTrip.vehicleType ?? 'car',
                                    rideMode: 'offer',
                                    rideId: currentTrip.id,
                                  ),
                                ),
                              );
                              if (updated == true && mounted) {
                                _bloc.add(const DrivesDetailReloadRequested());
                                context.read<HomeBloc>().add(const RefreshUpcomingTrips());
                              }
                            },
                            onEditPayment: () async {
                              final updated = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PaymentPage(
                                    rideId: currentTrip.id,
                                    rideData: {
                                      'fromAddress': currentTrip.fromAddress,
                                      'toAddress': currentTrip.toAddress,
                                      'date': currentTrip.date,
                                      'time': {
                                        'hour': currentTrip.time.hour,
                                        'minute': currentTrip.time.minute,
                                      },
                                      'fare': {'farePerSeat': currentTrip.farePerSeat},
                                    },
                                  ),
                                ),
                              );
                              if (updated == true && mounted) {
                                _bloc.add(const DrivesDetailReloadRequested());
                                context.read<HomeBloc>().add(const RefreshUpcomingTrips());
                              }
                            },
                          ),

                          const SizedBox(height: 24),

                          if (state.ridersStatus == DrivesDetailRidersStatus.initial ||
                              state.ridersStatus == DrivesDetailRidersStatus.loading)
                            const Center(child: CircularProgressIndicator())
                          else if (state.ridersStatus == DrivesDetailRidersStatus.error)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: Text(
                                  'Error loading riders: ${state.ridersError}',
                                  style: TextStyle(color: Colors.red[600], fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'RIDERS CONFIRMED',
                                      style: GoogleFonts.mulish(
                                        color: const Color(0xFF4C515B),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                        height: 15 / 14,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => _openMap(state.riders),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        minimumSize: Size.zero,
                                      ),
                                      child: Text(
                                        'View On Map',
                                        style: GoogleFonts.mulish(
                                          fontSize: 14,
                                          color: const Color(0xFF757474),
                                          decoration: TextDecoration.underline,
                                          fontWeight: FontWeight.w400,
                                          height: 18 / 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildRiderListFromData(context, state.riders),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRiderListFromData(
    BuildContext context,
    List<RideRider> riders,
  ) {
    if (riders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Text(
            'No riders joined yet',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ),
      );
    }
    return Column(
      children: riders.map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _RiderCard(
          rider: r,
          farePerSeat: widget.trip.farePerSeat,
          fallbackPickupLat: widget.trip.fromLat,
          fallbackPickupLng: widget.trip.fromLng,
          onCancel: () => _confirmCancelRider(context, r.riderName, r.requestId),
        ),
      )).toList(),
    );
  }
}

class _RiderCard extends StatelessWidget {
  const _RiderCard({
    required this.rider,
    this.farePerSeat,
    required this.fallbackPickupLat,
    required this.fallbackPickupLng,
    required this.onCancel,
  });

  final RideRider rider;
  final double? farePerSeat;
  final double? fallbackPickupLat;
  final double? fallbackPickupLng;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final pickupLat = rider.pickupLat ?? fallbackPickupLat ?? 0;
    final pickupLng = rider.pickupLng ?? fallbackPickupLng ?? 0;
    final double? km = (rider.dropOffLat != null && rider.dropOffLng != null)
        ? RideMatcher.distanceKm(
            pickupLat,
            pickupLng,
            rider.dropOffLat!,
            rider.dropOffLng!,
          )
        : null;

    final timeLabel =
        km != null ? RideMatcher.formatDuration((km * 2).round() + 5) : '8 min';

    final bool isNegotiating = rider.negotiatedPrice != null &&
        rider.negotiationStatus != 'accepted' &&
        rider.negotiationStatus != 'declined';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDDDDD)), // Outline
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: rider.riderPhotoUrl != null
                    ? NetworkImage(rider.riderPhotoUrl!)
                    : null,
                backgroundColor: const Color(0xFFC4C4C4),
                child: rider.riderPhotoUrl == null
                    ? Text(
                        rider.riderName.isNotEmpty
                            ? rider.riderName[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.mulish(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rider.riderName,
                      style: GoogleFonts.mulish(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        height: 18 / 14,
                        color: const Color(0xFF1D1D1D),
                      ),
                    ),
                    Text(
                      rider.employeeId.isNotEmpty
                          ? rider.employeeId
                          : 'AE2610002',
                      style: GoogleFonts.mulish(
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        height: 18 / 12,
                        color: const Color(0xFF757474),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.directions_car,
                    size: 16,
                    color: Color(0xFF757474),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    timeLabel,
                    style: GoogleFonts.mulish(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 18 / 12,
                      color: const Color(0xFF1D1D1D),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Image.asset(
                    'assets/images/location_pin.png',
                    width: 16,
                    height: 16,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              style: GoogleFonts.mulish(
                fontSize: 14,
                height: 18 / 14,
                color: const Color(0xFF1D1D1D),
              ),
              children: [
                TextSpan(
                  text: 'Pick up point: ',
                  style: GoogleFonts.mulish(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: rider.pickupPoint,
                  style: GoogleFonts.mulish(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              style: GoogleFonts.mulish(
                fontSize: 14,
                height: 18 / 14,
                color: const Color(0xFF1D1D1D),
              ),
              children: [
                TextSpan(
                  text: 'Time: ',
                  style: GoogleFonts.mulish(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: rider.pickupTimeLabel,
                  style: GoogleFonts.mulish(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          if (isNegotiating) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDDDDDD)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${rider.riderName} countered your offer',
                    style: GoogleFonts.mulish(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text(
                            'YOUR OFFER',
                            style: GoogleFonts.mulish(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF616874),
                              height: 16.5 / 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${farePerSeat?.toInt() ?? 0}',
                            style: GoogleFonts.mulish(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF616874),
                              decoration: TextDecoration.lineThrough,
                              height: 24 / 16,
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Icon(Icons.arrow_forward,
                            size: 16, color: Color(0xFF616874)),
                      ),
                      Column(
                        children: [
                          Text(
                            'COUNTER',
                            style: GoogleFonts.mulish(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF308666),
                              height: 16.5 / 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${rider.negotiatedPrice?.toInt()}',
                            style: GoogleFonts.mulish(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF308666),
                              height: 24 / 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            context.read<DrivesDetailBloc>().add(
                                  DrivesDetailNegotiationResponded(
                                    requestId: rider.requestId,
                                    status: 'declined',
                                  ),
                                );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFDDDDDD)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Colors.white,
                          ),
                          child: Text(
                            'Decline',
                            style: GoogleFonts.mulish(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E1E1E),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            context.read<DrivesDetailBloc>().add(
                                  DrivesDetailNegotiationResponded(
                                    requestId: rider.requestId,
                                    status: 'accepted',
                                  ),
                                );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E1E1E),
                            foregroundColor: const Color(0xFFFDFDFD),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                          child: Text(
                            'Accept ₹${rider.negotiatedPrice?.toInt()}',
                            style: GoogleFonts.mulish(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final myId = FirebaseAuth.instance.currentUser?.uid;
                    if (myId == null) return;
                    final ids = [myId, rider.riderId];
                    ids.sort();
                    final chatId = ids.join('_');

                    await GetIt.instance<ChatRepository>().ensureChatExists(
                      chatId: chatId,
                      participantIds: [myId, rider.riderId],
                      participantNames: {
                        myId: FirebaseAuth.instance.currentUser?.displayName ??
                            'Driver',
                        rider.riderId: rider.riderName,
                      },
                      participantPhotos: {
                        if (rider.riderPhotoUrl != null)
                          rider.riderId: rider.riderPhotoUrl!,
                      },
                      type: 'private',
                    );

                    if (!context.mounted) return;
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ChatPage(
                        chatId: chatId,
                        title: rider.riderName,
                        receiverId: rider.riderId,
                        receiverName: rider.riderName,
                      ),
                    ));
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1D1D1D)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/chat_square.png',
                        width: 18,
                        height: 18,
                        color: const Color(0xFF1D1D1D),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Chat',
                        style: GoogleFonts.mulish(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 18 / 14,
                          color: const Color(0xFF1D1D1D),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEA0000)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Cancel ride',
                    style: GoogleFonts.mulish(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 18 / 14,
                      color: const Color(0xFFEA0000),
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
