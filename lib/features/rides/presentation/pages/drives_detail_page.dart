import 'package:acepool/features/chat/presentation/pages/chat_page.dart';
import 'package:acepool/features/home/domain/entities/upcoming_trip.dart';
import 'package:acepool/features/home/presentation/widgets/glass_card.dart';
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
  static const _green = Color(0xFF1B8A3F);
  static final _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'acepool',
  );

  int _activeTab = 0;
  late Future<List<_RiderInfo>> _requestsFuture;
  late Future<List<_RiderInfo>> _confirmedFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _requestsFuture = _fetchRiders('pending');
    _confirmedFuture = _fetchRiders('accepted');
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

  Future<void> _acceptRequest(String requestId) async {
    await _db
        .collection('ride_requests')
        .doc(requestId)
        .update({'status': 'accepted'});
    await _db.collection('rides').doc(widget.trip.id).update({
      'seatsFilled': FieldValue.increment(1),
    });
    setState(_reload);
  }

  Future<void> _rejectRequest(String requestId) async {
    await _db
        .collection('ride_requests')
        .doc(requestId)
        .update({'status': 'rejected'});
    setState(_reload);
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
            // App bar
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
                    // Trip summary card
                    GlassCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(18),
                                  bottomRight: Radius.circular(20),
                                ),
                                child: ColoredBox(
                                  color: _green,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.person_outline,
                                            color: Colors.white, size: 15),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${widget.trip.seatsFilled}/${widget.trip.seatsTotal} seats filled',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.only(right: 4, top: 4),
                                child: IconButton(
                                  icon: const Icon(Icons.more_vert,
                                      color: Colors.black54),
                                  onPressed: () {},
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            ],
                          ),

                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.trip.dateLabel,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.trip.timeLabel,
                                  style: const TextStyle(
                                      color: Colors.black54, fontSize: 13),
                                ),
                                const SizedBox(height: 12),

                                // Route
                                Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: _green, width: 1.5),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        widget.trip.fromAddress,
                                        style:
                                            const TextStyle(fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Column(
                                    children: List.generate(
                                      3,
                                      (_) => Container(
                                        width: 1.5,
                                        height: 4,
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 1.5),
                                        color: Colors.black26,
                                      ),
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _green,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        widget.trip.toAddress,
                                        style:
                                            const TextStyle(fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Chat bar
                                Container(
                                  padding: const EdgeInsets.only(
                                      left: 16, right: 6, top: 6, bottom: 6),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'Start your chat with all riders',
                                          style: TextStyle(
                                              color: Colors.black38,
                                              fontSize: 14),
                                        ),
                                      ),
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: const BoxDecoration(
                                          color: _green,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                            Icons.send_rounded,
                                            color: Colors.white,
                                            size: 18),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Tab toggle
                    Row(
                      children: [
                        _TabPill(
                          label: 'Riders requests',
                          active: _activeTab == 0,
                          onTap: () => setState(() => _activeTab = 0),
                        ),
                        const SizedBox(width: 8),
                        _TabPill(
                          label: 'Riders confirmed',
                          active: _activeTab == 1,
                          onTap: () => setState(() => _activeTab = 1),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Rider list
                    if (_activeTab == 0)
                      FutureBuilder<List<_RiderInfo>>(
                        future: _requestsFuture,
                        builder: (context, snapshot) =>
                            _buildRiderList(context, snapshot, isConfirmed: false),
                      )
                    else
                      FutureBuilder<List<_RiderInfo>>(
                        future: _confirmedFuture,
                        builder: (context, snapshot) =>
                            _buildRiderList(context, snapshot, isConfirmed: true),
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
    AsyncSnapshot<List<_RiderInfo>> snapshot, {
    required bool isConfirmed,
  }) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.only(top: 40),
        child: CircularProgressIndicator(),
      ));
    }
    final riders = snapshot.data ?? [];
    if (riders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Center(
          child: Text(
            isConfirmed ? 'No confirmed riders yet' : 'No pending requests',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ),
      );
    }
    return Column(
      children: riders
          .map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RiderCard(
                  rider: r,
                  isConfirmed: isConfirmed,
                  onAccept: () => _acceptRequest(r.requestId),
                  onReject: () => _rejectRequest(r.requestId),
                  onCancel: () => _cancelRider(r.requestId),
                ),
              ))
          .toList(),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: active ? Colors.black : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.black54,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
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
    final h =
        pickupTime.hourOfPeriod == 0 ? 12 : pickupTime.hourOfPeriod;
    final m = pickupTime.minute.toString().padLeft(2, '0');
    final period =
        pickupTime.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }
}

class _RiderCard extends StatelessWidget {
  const _RiderCard({
    required this.rider,
    required this.isConfirmed,
    required this.onAccept,
    required this.onReject,
    required this.onCancel,
  });

  final _RiderInfo rider;
  final bool isConfirmed;
  final VoidCallback onAccept;
  final VoidCallback onReject;
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
                radius: 22,
                backgroundImage: rider.riderPhotoUrl != null
                    ? NetworkImage(rider.riderPhotoUrl!)
                    : null,
                backgroundColor: Colors.grey.shade300,
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
                    Text(
                      rider.riderName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    if (rider.employeeId.isNotEmpty)
                      Text(
                        rider.employeeId,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12),
                      ),
                  ],
                ),
              ),
              Icon(Icons.location_on_outlined,
                  size: 16, color: Colors.grey.shade400),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            'Pick up point: ${rider.pickupPoint.isNotEmpty ? rider.pickupPoint : "Not specified"}',
            style: const TextStyle(fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Time: ${rider.pickupTimeLabel}',
            style: const TextStyle(fontSize: 13),
          ),

          const SizedBox(height: 14),

          if (!isConfirmed)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black45),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('Reject ride',
                        style: TextStyle(
                            color: Colors.black87, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('Accept ride',
                        style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            receiverId: rider.riderId,
                            receiverName: rider.riderName,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 14),
                    label: const Text('Chat',
                        style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: Colors.black45),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('Cancel ride',
                        style:
                            TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
