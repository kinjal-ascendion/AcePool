import 'package:acepool/core/utils/date_time_formatter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class FindRideResultsPage extends StatefulWidget {
  const FindRideResultsPage({
    super.key,
    required this.fromAddress,
    required this.toAddress,
    required this.date,
    required this.time,
    required this.vehicleType,
  });

  final String fromAddress;
  final String toAddress;
  final DateTime date;
  final TimeOfDay time;
  final String vehicleType;

  @override
  State<FindRideResultsPage> createState() => _FindRideResultsPageState();
}

class _FindRideResultsPageState extends State<FindRideResultsPage> {
  static final _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'acepool',
  );

  late Future<List<_RideResult>> _resultsFuture;

  @override
  void initState() {
    super.initState();
    _resultsFuture = _fetchResults();
  }

  Future<List<_RideResult>> _fetchResults() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final startOfDay =
        DateTime(widget.date.year, widget.date.month, widget.date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snap = await _db
        .collection('rides')
        .where('rideMode', isEqualTo: 'offer')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    final myRequestsSnap = await _db
        .collection('ride_requests')
        .where('riderId', isEqualTo: uid)
        .where('status', isEqualTo: 'accepted')
        .get();
    final requestedRideIds = myRequestsSnap.docs
        .map((d) => d.data()['rideId'] as String)
        .toSet();

    final results = <_RideResult>[];
    for (final doc in snap.docs) {
      final d = doc.data();
      if (d['uid'] == uid) continue;
      final vehicleType = d['vehicleType'] as String? ?? 'car';
      if (vehicleType != widget.vehicleType) continue;
      final seatCount = d['seatCount'] as int;
      final seatsFilled = (d['seatsFilled'] as int?) ?? 0;
      if (seatsFilled >= seatCount) continue;

      final rideFrom = d['fromAddress'] as String;
      final rideTo = d['toAddress'] as String;
      if (!_addressMatches(rideFrom, widget.fromAddress) ||
          !_addressMatches(rideTo, widget.toAddress)) {
        continue;
      }

      String driverName = '';
      String? driverPhotoUrl;
      try {
        final driverDoc =
            await _db.collection('users').doc(d['uid'] as String).get();
        final dd = driverDoc.data();
        driverName = dd?['fullName'] as String? ?? '';
        driverPhotoUrl = dd?['profileImageUrl'] as String?;
      } catch (_) {}

      final date = (d['date'] as Timestamp).toDate();
      final timeMap = d['time'] as Map<String, dynamic>;

      results.add(_RideResult(
        id: doc.id,
        driverId: d['uid'] as String,
        driverName: driverName,
        driverPhotoUrl: driverPhotoUrl,
        date: date,
        time: TimeOfDay(
            hour: timeMap['hour'] as int, minute: timeMap['minute'] as int),
        fromAddress: rideFrom,
        toAddress: rideTo,
        seatsFilled: seatsFilled,
        seatsTotal: seatCount,
        vehicleType: vehicleType,
        alreadyRequested: requestedRideIds.contains(doc.id),
      ));
    }

    return results;
  }

  bool _addressMatches(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();

  void _refresh() => setState(() => _resultsFuture = _fetchResults());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Find a Ride',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Upcoming filter chip mirroring Trips page
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Upcoming',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down,
                              size: 18, color: Colors.grey.shade600),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Results list
            Expanded(
              child: FutureBuilder<List<_RideResult>>(
                future: _resultsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }
                  final results = snapshot.data ?? [];
                  if (results.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'No rides available for this date',
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
                        const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: results.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 14),
                    itemBuilder: (_, i) => _RideResultCard(
                      result: results[i],
                      riderFromAddress: widget.fromAddress,
                      riderTime: widget.time,
                      db: _db,
                      onRequested: _refresh,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────

class _RideResult {
  const _RideResult({
    required this.id,
    required this.driverId,
    required this.driverName,
    this.driverPhotoUrl,
    required this.date,
    required this.time,
    required this.fromAddress,
    required this.toAddress,
    required this.seatsFilled,
    required this.seatsTotal,
    required this.vehicleType,
    required this.alreadyRequested,
  });

  final String id;
  final String driverId;
  final String driverName;
  final String? driverPhotoUrl;
  final DateTime date;
  final TimeOfDay time;
  final String fromAddress;
  final String toAddress;
  final int seatsFilled;
  final int seatsTotal;
  final String vehicleType;
  final bool alreadyRequested;

  String get timeLabel => DateTimeFormatter.time12h(time);
  String get dateLabel =>
      DateTimeFormatter.monthDayYear(date) +
      DateTimeFormatter.relativeDayLabel(date);
}

// ── Ride result card ──────────────────────────────────────────────────────────

class _RideResultCard extends StatefulWidget {
  const _RideResultCard({
    required this.result,
    required this.riderFromAddress,
    required this.riderTime,
    required this.db,
    required this.onRequested,
  });

  final _RideResult result;
  final String riderFromAddress;
  final TimeOfDay riderTime;
  final FirebaseFirestore db;
  final VoidCallback onRequested;

  @override
  State<_RideResultCard> createState() => _RideResultCardState();
}

class _RideResultCardState extends State<_RideResultCard> {
  static const _green = Color(0xFF1B8A3F);
  static const _badgeBg = Color(0xFF5A5A5A);

  final _messageController = TextEditingController();
  late final _pickupController =
      TextEditingController(text: widget.riderFromAddress);
  bool _submitting = false;
  bool _justRequested = false;

  @override
  void dispose() {
    _messageController.dispose();
    _pickupController.dispose();
    super.dispose();
  }

  Future<void> _requestRide() async {
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

      final pickupPoint = _pickupController.text.trim().isNotEmpty
          ? _pickupController.text.trim()
          : widget.riderFromAddress;

      final requestRef = widget.db.collection('ride_requests').doc();
      final rideRef = widget.db.collection('rides').doc(widget.result.id);
      final batch = widget.db.batch();
      batch.set(requestRef, {
        'rideId': widget.result.id,
        'riderId': uid,
        'riderName': riderName,
        'riderPhotoUrl': riderPhotoUrl,
        'pickupPoint': pickupPoint,
        'pickupTime': {
          'hour': widget.riderTime.hour,
          'minute': widget.riderTime.minute,
        },
        'message': _messageController.text.trim(),
        'status': 'accepted',
        'createdAt': FieldValue.serverTimestamp(),
        'rideFrom': widget.result.fromAddress,
        'rideTo': widget.result.toAddress,
        'rideDate': Timestamp.fromDate(widget.result.date),
        'rideTime': {
          'hour': widget.result.time.hour,
          'minute': widget.result.time.minute,
        },
        'driverId': widget.result.driverId,
        'driverName': widget.result.driverName,
      });
      batch.update(rideRef, {'seatsFilled': FieldValue.increment(1)});
      await batch.commit();

      if (mounted) {
        setState(() {
          _justRequested = true;
          _submitting = false;
        });
        widget.onRequested();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not request ride: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final requested = r.alreadyRequested || _justRequested;

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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: badge ─────────────────────────────────────────
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
              ],
            ),

            const SizedBox(height: 12),

            // ── Row 2: date + distance indicator ───────────────────
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
                Text(
                  r.vehicleType == 'bike' ? 'Bike' : 'Car',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(width: 4),
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

            // ── Row 3: time ─────────────────────────────────────────
            Text(
              r.timeLabel,
              style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 13),
            ),

            const SizedBox(height: 12),

            // ── Route ───────────────────────────────────────────────
            Row(
              children: [
                _routeDot(filled: false),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    r.fromAddress,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
                _routeDot(filled: true),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    r.toAddress,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Pickup point ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.only(left: 16, right: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _pickupController,
                      enabled: !requested && !_submitting,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Pickup point (e.g. Building A, Gate 2)',
                        hintStyle: TextStyle(
                            fontSize: 13, color: Colors.grey.shade400),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ── Message + Request button ─────────────────────────────
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
      ),
    );
  }

  Widget _routeDot({required bool filled}) {
    const _green = Color(0xFF1B8A3F);
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
