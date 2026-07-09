import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/core/utils/ride_matcher.dart';
import 'package:acepool/features/home/domain/entities/upcoming_trip.dart';
import 'package:acepool/features/rides/presentation/pages/drives_detail_page.dart';
import 'package:acepool/features/trips/presentation/widgets/drive_trip_card.dart';
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

  static const _tabs = ['Rides', 'Drives'];

  static final _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'acepool',
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    _tabController.addListener(() => setState(() {}));
    _ridesFuture = _fetchAvailableRides();
    _drivesFuture = _fetchTrips('offer');
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

    String userHomeAddress = '';
    String userOfficeAddress = '';
    double? userHomeLat;
    double? userHomeLng;
    double? userOfficeLat;
    double? userOfficeLng;
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      final userData = userDoc.data();
      userHomeAddress = userData?['homeAddress'] as String? ?? '';
      userOfficeAddress = userData?['officeAddress'] as String? ?? '';
      userHomeLat = (userData?['homeLat'] as num?)?.toDouble();
      userHomeLng = (userData?['homeLng'] as num?)?.toDouble();
      userOfficeLat = (userData?['officeLat'] as num?)?.toDouble();
      userOfficeLng = (userData?['officeLng'] as num?)?.toDouble();
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
          .where('status', isEqualTo: 'accepted')
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
      final rideFromLat = (d['fromLat'] as num?)?.toDouble();
      final rideFromLng = (d['fromLng'] as num?)?.toDouble();
      final rideToLat = (d['toLat'] as num?)?.toDouble();
      final rideToLng = (d['toLng'] as num?)?.toDouble();

      final match = _calcMatch(
        userHome: userHomeAddress,
        userOffice: userOfficeAddress,
        userHomeLat: userHomeLat,
        userHomeLng: userHomeLng,
        userOfficeLat: userOfficeLat,
        userOfficeLng: userOfficeLng,
        rideFrom: rideFrom,
        rideTo: rideTo,
        rideFromLat: rideFromLat,
        rideFromLng: rideFromLng,
        rideToLat: rideToLat,
        rideToLng: rideToLng,
      );

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
        matchPercent: match.matchPercent,
        distanceKm: match.distanceKm,
        defaultPickupPoint:
            userHomeAddress.isNotEmpty ? userHomeAddress : rideFrom,
      ));
    }

    rides.sort((a, b) => b.matchPercent.compareTo(a.matchPercent));
    return rides;
  }

  _MatchResult _calcMatch({
    required String userHome,
    required String userOffice,
    double? userHomeLat,
    double? userHomeLng,
    double? userOfficeLat,
    double? userOfficeLng,
    required String rideFrom,
    required String rideTo,
    double? rideFromLat,
    double? rideFromLng,
    double? rideToLat,
    double? rideToLng,
  }) {
    final haveUserCoords = userHomeLat != null &&
        userHomeLng != null &&
        userOfficeLat != null &&
        userOfficeLng != null;
    final haveRideCoords = rideFromLat != null &&
        rideFromLng != null &&
        rideToLat != null &&
        rideToLng != null;

    if (haveUserCoords && haveRideCoords) {
      final fromKm =
          RideMatcher.distanceKm(userHomeLat, userHomeLng, rideFromLat, rideFromLng);
      final toKm =
          RideMatcher.distanceKm(userOfficeLat, userOfficeLng, rideToLat, rideToLng);
      final worstKm = fromKm > toKm ? fromKm : toKm;
      return _MatchResult(RideMatcher.matchPercentFromDistance(worstKm), fromKm);
    }

    final fromMatch = RideMatcher.fuzzyAddressMatches(userHome, rideFrom);
    final toMatch = RideMatcher.fuzzyAddressMatches(userOffice, rideTo);
    int percent;
    if (fromMatch && toMatch) {
      percent = 100;
    } else if (toMatch) {
      percent = 80;
    } else if (fromMatch) {
      percent = 60;
    } else {
      percent = 40;
    }
    return _MatchResult(percent, null);
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
                  color: AppColors.grey300,
                ),
                const SizedBox(height: 16),
                Text(
                  emptyLabel,
                  style: TextStyle(
                    color: AppColors.grey500,
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
                  child: DriveTripCard(trip: trips[i]),
                )
              : DriveTripCard(trip: trips[i]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.grey200,
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
                            color: active ? AppColors.black : AppColors.transparent,
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
                              color: active ? AppColors.white : AppColors.black54,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

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
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.grey300),
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
                        color: AppColors.grey600,
                      ),
                    ],
                  ),
                ),
              ),
            ),

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
                                  color: AppColors.red400, fontSize: 13),
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
                                  color: AppColors.grey300),
                              const SizedBox(height: 16),
                              Text('No available rides from other users',
                                  style: TextStyle(
                                      color: AppColors.grey500,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchResult {
  const _MatchResult(this.matchPercent, this.distanceKm);

  final int matchPercent;
  final double? distanceKm;
}

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
    required this.distanceKm,
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
  final double? distanceKm;

  String? get distanceLabel =>
      distanceKm == null ? null : RideMatcher.formatDistance(distanceKm!);

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

  final _messageController = TextEditingController();
  bool _submitting = false;
  bool _justRequested = false;

  @override
  void dispose() {
    _messageController.dispose();
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

      final pickupPoint = widget.ride.defaultPickupPoint;

      final requestRef = widget.db.collection('ride_requests').doc();
      final rideRef = widget.db.collection('rides').doc(widget.ride.id);
      final batch = widget.db.batch();
      batch.set(requestRef, {
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
        'status': 'accepted',
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
    final r = widget.ride;
    final requested = r.alreadyRequested || _justRequested;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top banner + match% overlay (pinned to extreme corners) ──
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
                          horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_outline,
                              color: AppColors.white, size: 15),
                          const SizedBox(width: 6),
                          Text(
                            '${r.seatsFilled}/${r.seatsTotal} seats filled',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${r.matchPercent}% Match',
                        style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.more_vert, size: 18, color: AppColors.grey600),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      r.dateLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.black87,
                      ),
                    ),
                    const Spacer(),
                    Transform.translate(
                      offset: const Offset(0, -2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_walk,
                              size: 14, color: AppColors.grey600),
                          const SizedBox(width: 4),
                          Text(
                            r.distanceLabel ??
                                (r.vehicleType == 'bike' ? 'Bike' : 'Car'),
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.grey600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.chevron_right,
                              size: 14, color: AppColors.grey400),
                          const SizedBox(width: 6),
                          Icon(
                            r.vehicleType == 'bike'
                                ? Icons.two_wheeler
                                : Icons.directions_car,
                            size: 16,
                            color: AppColors.grey700,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 2),

          Text(
            r.timeLabel,
            style: const TextStyle(color: AppColors.black45, fontSize: 12),
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              _dot(filled: false),
              const SizedBox(width: 10),
              Expanded(
                child: Text(r.fromAddress,
                    style: const TextStyle(fontSize: 13, color: AppColors.black54),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
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
                  color: AppColors.black26,
                ),
              ),
            ),
          ),
          Row(
            children: [
              _dot(filled: true),
              const SizedBox(width: 10),
              Expanded(
                child: Text(r.toAddress,
                    style: const TextStyle(fontSize: 13, color: AppColors.black54),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Divider(color: AppColors.grey200, height: 1),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '₹ 600 / seat',
                style: TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'View Details',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.black54,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.only(
                left: 16, right: 4, top: 4, bottom: 4),
            decoration: BoxDecoration(
              color: AppColors.grey100,
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
                          fontSize: 13, color: AppColors.grey400),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: requested ? AppColors.grey400 : AppColors.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.white),
                          )
                        : Icon(
                            requested ? Icons.check : Icons.send_rounded,
                            color: AppColors.white,
                            size: 16,
                          ),
                  ),
                ),
              ],
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
          ? const BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryGreen)
          : BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryGreen, width: 1.5),
            ),
    );
  }
}
