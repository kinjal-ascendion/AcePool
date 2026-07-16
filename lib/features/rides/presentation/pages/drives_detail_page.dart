import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/di/injection.dart';
import 'package:acepool/features/chat/domain/repositories/chat_repository.dart';
import 'package:acepool/features/chat/presentation/pages/chat_page.dart';
import 'package:acepool/features/home/domain/entities/upcoming_trip.dart';
import 'package:acepool/features/rides/presentation/pages/ride_map_page.dart';
import 'package:acepool/features/trips/presentation/widgets/drive_trip_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DrivesDetailPage extends StatefulWidget {
  const DrivesDetailPage({super.key, required this.trip});

  final UpcomingTrip trip;

  @override
  State<DrivesDetailPage> createState() => _DrivesDetailPageState();
}

class _DrivesDetailPageState extends State<DrivesDetailPage> {
  static final _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'acepool',
  );

  late Future<List<_RiderInfo>> _ridersFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _ridersFuture = _fetchRiders('accepted');
  }

  Future<List<_RiderInfo>> _fetchRiders(String status) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final snap = await _db
        .collection('ride_requests')
        .where('rideId', isEqualTo: widget.trip.id)
        .where('driverId', isEqualTo: uid)
        .where('status', isEqualTo: status)
        .get();

    final riders = <_RiderInfo>[];
    for (final doc in snap.docs) {
      final d = doc.data();
      String employeeId = '';
      try {
        final userDoc = await _db
            .collection('users')
            .doc(d['riderId'] as String)
            .get();
        employeeId = userDoc.data()?['employeeId'] as String? ?? '';
      } catch (_) {}

      final pickupTimeMap =
          d['pickupTime'] as Map<String, dynamic>? ?? {'hour': 0, 'minute': 0};

      LatLng? position;
      if (d['pickupLatLng'] != null) {
        final latLngMap = d['pickupLatLng'] as Map<String, dynamic>;
        position = LatLng(
          (latLngMap['latitude'] as num).toDouble(),
          (latLngMap['longitude'] as num).toDouble(),
        );
      } else if (widget.trip.fromLat != null && widget.trip.fromLng != null) {
        position = LatLng(widget.trip.fromLat!, widget.trip.fromLng!);
      }

      LatLng? dropOffPosition;
      if (d['dropOffLatLng'] != null) {
        final latLngMap = d['dropOffLatLng'] as Map<String, dynamic>;
        dropOffPosition = LatLng(
          (latLngMap['latitude'] as num).toDouble(),
          (latLngMap['longitude'] as num).toDouble(),
        );
      }

      riders.add(_RiderInfo(
        requestId: doc.id,
        riderId: d['riderId'] as String? ?? '',
        riderName: d['riderName'] as String? ?? '',
        riderPhotoUrl: d['riderPhotoUrl'] as String?,
        employeeId: employeeId,
        pickupPoint: d['pickupPoint'] as String? ?? '',
        position: position ?? LatLng(widget.trip.fromLat ?? 0, widget.trip.fromLng ?? 0),
        dropOffPosition: dropOffPosition,
        pickupTime: TimeOfDay(
          hour: (pickupTimeMap['hour'] as num).toInt(),
          minute: (pickupTimeMap['minute'] as num).toInt(),
        ),
      ));
    }

    if (status == 'accepted') {
      await _reconcileSeatsFilled(riders.length);
    }

    return riders;
  }

  Future<void> _reconcileSeatsFilled(int acceptedCount) async {
    final rideRef = _db.collection('rides').doc(widget.trip.id);
    final snap = await rideRef.get();
    final current = (snap.data()?['seatsFilled'] as int?) ?? 0;
    if (current != acceptedCount) {
      await rideRef.update({'seatsFilled': acceptedCount});
    }
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
                                await _cancelRider(requestId);
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

  Future<void> _cancelRider(String requestId) async {
    await _db
        .collection('ride_requests')
        .doc(requestId)
        .update({'status': 'rejected'});

    final rideRef = _db.collection('rides').doc(widget.trip.id);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(rideRef);
      final current = (snap.data()?['seatsFilled'] as int?) ?? 0;
      if (current > 0) {
        tx.update(rideRef, {'seatsFilled': current - 1});
      }
    });

    setState(_reload);
  }

  void _openMap(List<_RiderInfo> riders) {
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
        points.add(PickupPoint(
            location: r.pickupPoint.split(',')[0],
            sub: 'Rider Pickup',
            time: r.pickupTimeLabel,
            position: r.position,
            dropOffPosition: r.dropOffPosition,
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

  @override
  Widget build(BuildContext context) {
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
                      trip: widget.trip,
                      showViewDetails: false,
                      onChatTap: () async {
                        final riders = await _ridersFuture;
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

                        await _db.collection('chats').doc(widget.trip.id).set({
                          'participants': FieldValue.arrayUnion(participantIds),
                          'type': 'group',
                          'groupTitle': "${widget.trip.dateLabel} ; ${widget.trip.timeLabel}",
                          'rideDate': Timestamp.fromDate(widget.trip.date),
                          'participantNames': participantNames,
                          'participantPhotos': participantPhotos,
                          'lastMessageTime': FieldValue.serverTimestamp(),
                        }, SetOptions(merge: true));

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
                      },
                    ),

                    const SizedBox(height: 24),

                    FutureBuilder<List<_RiderInfo>>(
                      future: _ridersFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: Text(
                                'Error loading riders: ${snapshot.error}',
                                style: TextStyle(color: AppColors.red600, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }
                        
                        final riders = snapshot.data ?? [];
                        
                        return Column(
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
                                  onPressed: () => _openMap(riders),
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
                            _buildRiderListFromData(context, riders),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiderListFromData(
    BuildContext context,
    List<_RiderInfo> riders,
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
          onCancel: () => _confirmCancelRider(context, r.riderName, r.requestId),
        ),
      )).toList(),
    );
  }
}

class _RiderInfo {
  const _RiderInfo({
    required this.requestId,
    required this.riderId,
    required this.riderName,
    this.riderPhotoUrl,
    required this.employeeId,
    required this.pickupPoint,
    required this.position,
    this.dropOffPosition,
    required this.pickupTime,
  });

  final String requestId;
  final String riderId;
  final String riderName;
  final String? riderPhotoUrl;
  final String employeeId;
  final String pickupPoint;
  final LatLng position;
  final LatLng? dropOffPosition;
  final TimeOfDay pickupTime;

  String get pickupTimeLabel {
    final h = pickupTime.hourOfPeriod == 0 ? 12 : pickupTime.hourOfPeriod;
    final m = pickupTime.minute.toString().padLeft(2, '0');
    final period = pickupTime.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }
}

class _RiderCard extends StatelessWidget {
  const _RiderCard({
    required this.rider,
    required this.onCancel,
  });

  final _RiderInfo rider;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
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
                    '25mins',
                    style: TextStyle(fontSize: 12, color: AppColors.grey700),
                  ),
                  Icon(Icons.chevron_right, size: 16, color: AppColors.grey500),
                  Icon(Icons.location_on_outlined, size: 16, color: AppColors.grey600),
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
