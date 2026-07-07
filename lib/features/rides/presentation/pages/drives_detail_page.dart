import 'package:acepool/features/chat/presentation/pages/chat_page.dart';
import 'package:acepool/features/home/domain/entities/upcoming_trip.dart';
import 'package:acepool/features/rides/presentation/pages/ride_map_page.dart';
import 'package:acepool/features/trips/presentation/widgets/drive_trip_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

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
      riders.add(_RiderInfo(
        requestId: doc.id,
        riderId: d['riderId'] as String? ?? '',
        riderName: d['riderName'] as String? ?? '',
        riderPhotoUrl: d['riderPhotoUrl'] as String?,
        employeeId: employeeId,
        pickupPoint: d['pickupPoint'] as String? ?? '',
        pickupTime: TimeOfDay(
          hour: pickupTimeMap['hour'] as int,
          minute: pickupTimeMap['minute'] as int,
        ),
      ));
    }
    return riders;
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
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.warning_amber_rounded,
                      color: Colors.red.shade600, size: 30),
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
                      fontSize: 13.5, color: Colors.grey.shade600, height: 1.4),
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
                          side: BorderSide(color: Colors.grey.shade300),
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
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.red.shade300,
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

  Future<void> _cancelRider(String requestId) async {
    await _db
        .collection('ride_requests')
        .doc(requestId)
        .update({'status': 'rejected'});
    await _db.collection('rides').doc(widget.trip.id).update({
      'seatsFilled': FieldValue.increment(-1),
    });
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
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
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {},
                  ),
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

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Riders',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  RideMapPage(trip: widget.trip),
                            ),
                          ),
                          child: const Text(
                            'View On Map',
                            style: TextStyle(
                              fontSize: 13,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    FutureBuilder<List<_RiderInfo>>(
                      future: _ridersFuture,
                      builder: (context, snapshot) =>
                          _buildRiderList(context, snapshot),
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

  Widget _buildRiderList(
    BuildContext context,
    AsyncSnapshot<List<_RiderInfo>> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    final riders = snapshot.data ?? [];
    if (riders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Text(
            'No riders joined yet',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
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
    required this.pickupTime,
  });

  final String requestId;
  final String riderId;
  final String riderName;
  final String? riderPhotoUrl;
  final String employeeId;
  final String pickupPoint;
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
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
                backgroundColor: Colors.grey.shade400,
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
                      Text(rider.employeeId, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Pick up point: ${rider.pickupPoint}', style: const TextStyle(fontSize: 13)),
          Text('Time: ${rider.pickupTimeLabel}', style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 14),
          Row(
            children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final myId = FirebaseAuth.instance.currentUser?.uid;
                      if (myId == null) return;
                      final ids = [myId, rider.riderId];
                      ids.sort();
                      final chatId = ids.join('_');
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ChatPage(
                          chatId: chatId,
                          title: rider.riderName,
                          receiverId: rider.riderId,
                          receiverName: rider.riderName,
                        ),
                      ));
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 14),
                    label: const Text('Chat'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    child: const Text('Cancel ride', style: TextStyle(color: Colors.red)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
