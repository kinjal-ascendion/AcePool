import 'package:acepool/features/chat/presentation/pages/chat_page.dart';
import 'package:acepool/features/home/domain/entities/upcoming_trip.dart';
import 'package:acepool/features/home/presentation/widgets/trip_card.dart';
import 'package:acepool/features/rides/presentation/pages/drives_detail_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class TripsPage extends StatefulWidget {
  const TripsPage({super.key});

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  late Future<List<_AvailableRide>> _ridesFuture;
  late final Future<List<UpcomingTrip>> _drivesFuture;
  late final Future<List<_RideRequest>> _requestsFuture;

  static const _tabs = ['Rides', 'Drives', 'Requests'];

  static final _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'acepool',
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _tabController.addListener(() => setState(() {}));
    _ridesFuture = _fetchAvailableRides();
    _drivesFuture = _fetchTrips('offer');
    _requestsFuture = _fetchMyRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<UpcomingTrip>> _fetchTrips(String rideMode) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);

    final snapshot = await _db
        .collection('rides')
        .where('uid', isEqualTo: uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
        .orderBy('date')
        .get();

    return snapshot.docs
        .where((doc) => doc.data()['rideMode'] == rideMode)
        .map((doc) {
      final data = doc.data();
      final date = (data['date'] as Timestamp).toDate();
      final timeMap = data['time'] as Map<String, dynamic>;
      return UpcomingTrip(
        id: doc.id,
        date: DateTime(date.year, date.month, date.day),
        time: TimeOfDay(
          hour: timeMap['hour'] as int,
          minute: timeMap['minute'] as int,
        ),
        fromAddress: data['fromAddress'] as String,
        toAddress: data['toAddress'] as String,
        seatsFilled: (data['seatsFilled'] as int?) ?? 0,
        seatsTotal: data['seatCount'] as int,
      );
    }).toList();
  }

  Future<List<_AvailableRide>> _fetchAvailableRides() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);

    // Load user profile for match calculation and default pickup point
    String userHomeAddress = '';
    String userOfficeAddress = '';
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      userHomeAddress = userDoc.data()?['homeAddress'] as String? ?? '';
      userOfficeAddress = userDoc.data()?['officeAddress'] as String? ?? '';
    } catch (_) {}

    final snap = await _db
        .collection('rides')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
        .get();

    Set<String> requestedRideIds = {};
    try {
      final myRequestsSnap = await _db
          .collection('ride_requests')
          .where('riderId', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .get();
      requestedRideIds = myRequestsSnap.docs
          .map((d) => d.data()['rideId'] as String)
          .toSet();
    } catch (_) {}

    final rides = <_AvailableRide>[];
    for (final doc in snap.docs) {
      final d = doc.data();
      if (d['rideMode'] != 'offer') continue;
      if (d['uid'] == uid) continue;
      final seatCount = d['seatCount'] as int;
      final seatsFilled = (d['seatsFilled'] as int?) ?? 0;
      if (seatsFilled >= seatCount) continue;

      String driverName = '';
      try {
        final driverDoc =
            await _db.collection('users').doc(d['uid'] as String).get();
        driverName = driverDoc.data()?['fullName'] as String? ?? '';
      } catch (_) {}

      final date = (d['date'] as Timestamp).toDate();
      final timeMap = d['time'] as Map<String, dynamic>;
      final rideFrom = d['fromAddress'] as String;
      final rideTo = d['toAddress'] as String;

      rides.add(_AvailableRide(
        id: doc.id,
        driverId: d['uid'] as String,
        driverName: driverName,
        date: date,
        time: TimeOfDay(
            hour: timeMap['hour'] as int, minute: timeMap['minute'] as int),
        fromAddress: rideFrom,
        toAddress: rideTo,
        seatsFilled: seatsFilled,
        seatsTotal: seatCount,
        vehicleType: d['vehicleType'] as String? ?? 'car',
        alreadyRequested: requestedRideIds.contains(doc.id),
        matchPercent: _calcMatch(
            userHomeAddress, userOfficeAddress, rideFrom, rideTo),
        defaultPickupPoint: userHomeAddress,
      ));
    }

    rides.removeWhere((r) => r.matchPercent < 60);
    rides.sort((a, b) => b.matchPercent.compareTo(a.matchPercent));
    return rides;
  }

  int _calcMatch(String userHome, String userOffice, String rideFrom,
      String rideTo) {
    final fromMatch = _similar(userHome, rideFrom);
    final toMatch = _similar(userOffice, rideTo);
    if (fromMatch && toMatch) return 100;
    if (toMatch) return 80;
    if (fromMatch) return 60;
    return 40;
  }

  bool _similar(String a, String b) {
    if (a.isEmpty || b.isEmpty) return false;
    final an = a.toLowerCase().trim();
    final bn = b.toLowerCase().trim();
    if (an.contains(bn) || bn.contains(an)) return true;
    return an
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 3)
        .any((w) => bn.contains(w));
  }

  Future<List<_RideRequest>> _fetchMyRequests() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    try {
      final snap = await _db
          .collection('ride_requests')
          .where('riderId', isEqualTo: uid)
          .get();

      final results = snap.docs.map((doc) {
        final d = doc.data();
        final rideTimeMap =
            d['rideTime'] as Map<String, dynamic>? ?? {'hour': 0, 'minute': 0};
        final rideDate = (d['rideDate'] as Timestamp?)?.toDate() ?? DateTime.now();
        return _RideRequest(
          id: doc.id,
          rideFrom: d['rideFrom'] as String? ?? '',
          rideTo: d['rideTo'] as String? ?? '',
          rideDate: rideDate,
          rideTime: TimeOfDay(
            hour: rideTimeMap['hour'] as int,
            minute: rideTimeMap['minute'] as int,
          ),
          driverName: d['driverName'] as String? ?? '',
          driverId: d['driverId'] as String? ?? '',
          status: d['status'] as String? ?? 'pending',
        );
      }).toList();
      results.sort((a, b) => b.rideDate.compareTo(a.rideDate));
      return results;
    } catch (_) {
      return [];
    }
  }

  Widget _buildList(
    Future<List<UpcomingTrip>> future,
    String emptyLabel, {
    void Function(UpcomingTrip)? onTap,
  }) {
    return FutureBuilder<List<UpcomingTrip>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final trips = snapshot.data ?? [];
        if (trips.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.directions_car_outlined,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  emptyLabel,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          itemCount: trips.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) => onTap != null
              ? GestureDetector(
                  onTap: () => onTap(trips[i]),
                  child: TripCard(trip: trips[i]),
                )
              : TripCard(trip: trips[i]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 14),
              child: Center(
                child: Text(
                  'Trips',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Pill tab bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: List.generate(_tabs.length, (i) {
                    final active = _tabController.index == i;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _tabController.animateTo(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: active ? Colors.black : Colors.transparent,
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Text(
                            _tabs[i],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: active
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: active ? Colors.white : Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            // Upcoming filter chip
            Padding(
              padding: const EdgeInsets.only(right: 20, top: 12, bottom: 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Upcoming',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  FutureBuilder<List<_AvailableRide>>(
                    future: _ridesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: TextStyle(
                                  color: Colors.red.shade400, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      final rides = snapshot.data ?? [];
                      if (rides.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.event_seat_outlined,
                                  size: 64,
                                  color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text('No available rides from other users',
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 15)),
                            ],
                          ),
                        );
                      }
                      return ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        itemCount: rides.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 14),
                        itemBuilder: (_, i) => _AvailableRideCard(
                          ride: rides[i],
                          db: _db,
                          onRequested: () => setState(() {
                            _ridesFuture = _fetchAvailableRides();
                          }),
                        ),
                      );
                    },
                  ),
                  _buildList(
                    _drivesFuture,
                    'No drives scheduled yet',
                    onTap: (trip) => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DrivesDetailPage(trip: trip),
                      ),
                    ),
                  ),
                  FutureBuilder<List<_RideRequest>>(
                    future: _requestsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      final requests = snapshot.data ?? [];
                      if (requests.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inbox_outlined,
                                  size: 64,
                                  color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                'No ride requests yet',
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 15),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        itemCount: requests.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) =>
                            _RequestCard(request: requests[i]),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────

class _RideRequest {
  const _RideRequest({
    required this.id,
    required this.rideFrom,
    required this.rideTo,
    required this.rideDate,
    required this.rideTime,
    required this.driverName,
    required this.driverId,
    required this.status,
  });

  final String id;
  final String rideFrom;
  final String rideTo;
  final DateTime rideDate;
  final TimeOfDay rideTime;
  final String driverName;
  final String driverId;
  final String status;

  Color get statusColor {
    switch (status) {
      case 'accepted':
        return const Color(0xFF1B8A3F);
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }
}

// ── Request card ──────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final _RideRequest request;

  static const _green = Color(0xFF1B8A3F);

  String _timeLabel(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomRight: Radius.circular(14),
                ),
                child: ColoredBox(
                  color: request.statusColor,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    child: Text(
                      request.statusLabel,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_monthDay(request.rideDate)}  •  ${_timeLabel(request.rideTime)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 10),

                // Route
                Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _green, width: 1.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(request.rideFrom,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 3.5),
                  child: Column(
                    children: List.generate(
                      3,
                      (_) => Container(
                        width: 1.5,
                        height: 3.5,
                        margin:
                            const EdgeInsets.symmetric(vertical: 1),
                        color: Colors.black26,
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: _green),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(request.rideTo,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),

                if (request.driverName.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.directions_car_outlined,
                          size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Driver: ${request.driverName}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ),
                      if (request.status == 'accepted' &&
                          request.driverId.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            final myId = FirebaseAuth.instance.currentUser?.uid;
                            if (myId == null) return;
                            final ids = [myId, request.driverId];
                            ids.sort();
                            final chatId = ids.join('_');

                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChatPage(
                                  chatId: chatId,
                                  title: request.driverName,
                                  receiverId: request.driverId,
                                  receiverName: request.driverName,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.chat_bubble_outline,
                                    size: 12, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'Chat',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _monthDay(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month]} ${d.day}, ${d.year}';
  }
}

// ── Available ride data class ─────────────────────────────────────────────────

class _AvailableRide {
  const _AvailableRide({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.date,
    required this.time,
    required this.fromAddress,
    required this.toAddress,
    required this.seatsFilled,
    required this.seatsTotal,
    required this.vehicleType,
    required this.alreadyRequested,
    required this.matchPercent,
    required this.defaultPickupPoint,
  });

  final String id;
  final String driverId;
  final String driverName;
  final DateTime date;
  final TimeOfDay time;
  final String fromAddress;
  final String toAddress;
  final int seatsFilled;
  final int seatsTotal;
  final String vehicleType;
  final bool alreadyRequested;
  final int matchPercent;
  final String defaultPickupPoint;

  String get timeLabel {
    final h = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final m = time.minute.toString().padLeft(2, '0');
    final p = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  String get dateLabel {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }
}

// ── Available ride card ───────────────────────────────────────────────────────

class _AvailableRideCard extends StatefulWidget {
  const _AvailableRideCard({
    required this.ride,
    required this.db,
    required this.onRequested,
  });

  final _AvailableRide ride;
  final FirebaseFirestore db;
  final VoidCallback onRequested;

  @override
  State<_AvailableRideCard> createState() => _AvailableRideCardState();
}

class _AvailableRideCardState extends State<_AvailableRideCard> {
  static const _green = Color(0xFF1B8A3F);
  static const _badgeBg = Color(0xFF5A5A5A);

  final _messageController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<String?> _resolvePickupPoint() async {
    if (widget.ride.defaultPickupPoint.isNotEmpty) {
      return widget.ride.defaultPickupPoint;
    }
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter pickup location'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Building A, Gate 2',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    controller.dispose();
    return (result != null && result.isNotEmpty) ? result : null;
  }

  Future<void> _requestRide() async {
    final pickupPoint = await _resolvePickupPoint();
    if (pickupPoint == null) return;

    setState(() => _submitting = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      String riderName = '';
      String? riderPhotoUrl;
      try {
        final userDoc =
            await widget.db.collection('users').doc(uid).get();
        riderName = userDoc.data()?['fullName'] as String? ?? '';
        riderPhotoUrl =
            userDoc.data()?['profileImageUrl'] as String?;
      } catch (_) {}

      await widget.db.collection('ride_requests').add({
        'rideId': widget.ride.id,
        'riderId': uid,
        'riderName': riderName,
        'riderPhotoUrl': riderPhotoUrl,
        'pickupPoint': pickupPoint,
        'pickupTime': {
          'hour': widget.ride.time.hour,
          'minute': widget.ride.time.minute,
        },
        'message': _messageController.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'rideFrom': widget.ride.fromAddress,
        'rideTo': widget.ride.toAddress,
        'rideDate': Timestamp.fromDate(widget.ride.date),
        'rideTime': {
          'hour': widget.ride.time.hour,
          'minute': widget.ride.time.minute,
        },
        'driverId': widget.ride.driverId,
        'driverName': widget.ride.driverName,
      });

      if (mounted) widget.onRequested();
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.ride;
    final requested = r.alreadyRequested;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge + match %
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: _badgeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_outline,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      '${r.seatsFilled}/${r.seatsTotal} seats filled',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '${r.matchPercent}% Match',
                style: const TextStyle(
                  color: _green,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Date + vehicle icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                r.dateLabel,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Spacer(),
              Icon(Icons.directions_walk,
                  size: 13, color: Colors.grey.shade500),
              const SizedBox(width: 3),
              Icon(
                r.vehicleType == 'bike'
                    ? Icons.two_wheeler
                    : Icons.directions_car_outlined,
                size: 15,
                color: Colors.grey.shade500,
              ),
            ],
          ),

          const SizedBox(height: 3),

          Text(
            r.timeLabel,
            style:
                TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),

          const SizedBox(height: 12),

          // Route
          Row(
            children: [
              _dot(filled: false),
              const SizedBox(width: 10),
              Expanded(
                child: Text(r.fromAddress,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 7),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  children: List.generate(
                    4,
                    (_) => Container(
                      width: 1.5,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 2),
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              _dot(filled: true),
              const SizedBox(width: 10),
              Expanded(
                child: Text(r.toAddress,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Message + request button
          Container(
            padding: const EdgeInsets.only(
                left: 16, right: 6, top: 5, bottom: 5),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !requested && !_submitting,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: requested
                          ? 'Request sent'
                          : 'Share message with driver',
                      hintStyle: TextStyle(
                          fontSize: 13, color: Colors.grey.shade400),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 6),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: requested || _submitting ? null : _requestRide,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 11),
                    decoration: BoxDecoration(
                      color: requested ? Colors.grey.shade400 : _green,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            requested ? 'Requested' : 'Request ride',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
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
          ? const BoxDecoration(shape: BoxShape.circle, color: _green)
          : BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _green, width: 1.5),
            ),
    );
  }
}
