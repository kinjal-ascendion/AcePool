import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/core/utils/ride_matcher.dart';
import 'package:acepool/di/injection.dart';
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
    _bloc = sl<DrivesDetailBloc>()..add(DrivesDetailStarted(widget.trip));
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
            await sl<RidesRepository>().cancelRide(currentTrip.id, reason: reason);

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
          backgroundColor: AppColors.white,
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
                    color: AppColors.red50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.warning_amber_rounded,
                      color: AppColors.red600, size: 30),
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
                      fontSize: 13.5, color: AppColors.grey600, height: 1.4),
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
                          foregroundColor: AppColors.black87,
                          side: BorderSide(color: AppColors.grey300),
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
                                await sl<RidesRepository>().cancelRiderRequest(
                                  requestId: requestId,
                                  rideId: widget.trip.id,
                                );
                                _bloc.add(const DrivesDetailReloadRequested());
                                if (ctx.mounted) Navigator.of(ctx).pop();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.red600,
                          foregroundColor: AppColors.white,
                          disabledBackgroundColor: AppColors.red300,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                        child: isCancelling
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.white),
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

    await sl<RidesRepository>().ensureGroupChat(
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
                            onStartRide: () => _bloc
                                .add(const DrivesDetailStatusChangeRequested('in_progress')),
                            onEndRide: () => _bloc
                                .add(const DrivesDetailStatusChangeRequested('completed')),
                            onCancel: () => _handleCancelRide(currentTrip),
                            onChatTap: () => _onChatTap(state.riders),
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
                                  style: TextStyle(color: AppColors.red600, fontSize: 13),
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
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppColors.black,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'Riders confirmed',
                                        style: TextStyle(
                                          color: AppColors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => _openMap(state.riders),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        minimumSize: Size.zero,
                                      ),
                                      child: const Text(
                                        'View On Map',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.black,
                                          decoration: TextDecoration.underline,
                                          fontWeight: FontWeight.bold,
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
            style: TextStyle(color: AppColors.grey500, fontSize: 14),
          ),
        ),
      );
    }
    return Column(
      children: riders.map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _RiderCard(
          rider: r,
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
    required this.fallbackPickupLat,
    required this.fallbackPickupLng,
    required this.onCancel,
  });

  final RideRider rider;

  /// Trip's own from-lat/lng, used when the rider's own pickup coordinates
  /// are missing — matches the original `_fetchRiders`' guaranteed
  /// non-null `position` fallback.
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

    final distanceLabel = km != null ? RideMatcher.formatDistance(km) : '2.5 km';
    final timeLabel = km != null ? RideMatcher.formatDuration((km * 2).round() + 5) : '15 min';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: rider.riderPhotoUrl != null
                    ? NetworkImage(rider.riderPhotoUrl!)
                    : null,
                backgroundColor: AppColors.grey400,
                child: rider.riderPhotoUrl == null
                    ? Text(
                        rider.riderName.isNotEmpty
                            ? rider.riderName[0].toUpperCase()
                            : '?',
                        style:
                            const TextStyle(fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rider.riderName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    if (rider.employeeId.isNotEmpty)
                      Text(rider.employeeId, style: TextStyle(color: AppColors.grey600, fontSize: 12)),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.directions_car, size: 15, color: AppColors.grey700),
                  const SizedBox(width: 4),
                  Text(
                    timeLabel,
                    style: TextStyle(fontSize: 12, color: AppColors.grey700),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.location_on_outlined, size: 14, color: AppColors.grey600),
                  const SizedBox(width: 2),
                  Text(
                    distanceLabel,
                    style: TextStyle(fontSize: 11, color: AppColors.grey600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 13),
              children: [
                const TextSpan(text: 'Pick up point: ', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: rider.pickupPoint),
              ],
            ),
          ),
          Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 13),
              children: [
                const TextSpan(text: 'Time: ', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: rider.pickupTimeLabel),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final myId = FirebaseAuth.instance.currentUser?.uid;
                      if (myId == null) return;
                      final ids = [myId, rider.riderId];
                      ids.sort();
                      final chatId = ids.join('_');

                      await sl<ChatRepository>().ensureChatExists(
                        chatId: chatId,
                        participantIds: [myId, rider.riderId],
                        participantNames: {
                          myId: FirebaseAuth.instance.currentUser?.displayName ?? 'Driver',
                          rider.riderId: rider.riderName,
                        },
                        participantPhotos: {
                          if (rider.riderPhotoUrl != null) rider.riderId: rider.riderPhotoUrl!,
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
                      foregroundColor: AppColors.black87,
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.black87),
                    label: const Text('Chat', style: TextStyle(color: AppColors.black87)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.red),
                    ),
                    child: const Text('Cancel ride', style: TextStyle(color: AppColors.red)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
