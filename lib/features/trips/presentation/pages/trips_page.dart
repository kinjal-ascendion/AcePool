import 'package:acepool/core/services/directions_service.dart';
import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/core/utils/ride_matcher.dart';
import 'package:acepool/features/home/domain/entities/upcoming_trip.dart';
import 'package:acepool/features/home/presentation/bloc/home_bloc.dart';
import 'package:acepool/features/rides/domain/entities/ride_match.dart';
import 'package:acepool/features/rides/presentation/pages/drives_detail_page.dart';
import 'package:acepool/features/rides/presentation/pages/ride_details_page.dart';
import 'package:acepool/features/trips/presentation/widgets/drive_trip_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  bool _hasCommuteLocation = false;

  static const _tabs = ['Find ride', 'Offer ride'];

  static final _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'acepool',
  );
  static final _directions = DirectionsService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    _tabController.addListener(() => setState(() {}));
    _ridesFuture = _fetchAvailableRidesFromHomeState();
    _drivesFuture = _fetchTrips('offer');
  }

  /// Re-reads whatever's currently on Home's Find-ride form (shared
  /// `HomeBloc`) and fetches matches for it — blank form means no rides.
  Future<List<_AvailableRide>> _fetchAvailableRidesFromHomeState() {
    final homeState = context.read<HomeBloc>().state;
    return _fetchAvailableRides(
      fromAddress: homeState.fromAddress,
      toAddress: homeState.toAddress,
      fromLat: homeState.fromLat,
      fromLng: homeState.fromLng,
      toLat: homeState.toLat,
      toLng: homeState.toLng,
    );
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
      
      final fromLat = (data['fromLat'] as num?)?.toDouble();
      final fromLng = (data['fromLng'] as num?)?.toDouble();
      final toLat = (data['toLat'] as num?)?.toDouble();
      final toLng = (data['toLng'] as num?)?.toDouble();

      final fromLatLngMap = data['fromLatLng'] as Map<String, dynamic>?;
      final toLatLngMap = data['toLatLng'] as Map<String, dynamic>?;

      return UpcomingTrip(
        id: doc.id,
        date: DateTime(date.year, date.month, date.day),
        time: TimeOfDay(
          hour: timeMap['hour'] as int,
          minute: timeMap['minute'] as int,
        ),
        fromAddress: data['fromAddress'] as String,
        toAddress: data['toAddress'] as String,
        fromLat: fromLat ?? (fromLatLngMap?['latitude'] as num?)?.toDouble(),
        fromLng: fromLng ?? (fromLatLngMap?['longitude'] as num?)?.toDouble(),
        toLat: toLat ?? (toLatLngMap?['latitude'] as num?)?.toDouble(),
        toLng: toLng ?? (toLatLngMap?['longitude'] as num?)?.toDouble(),
        seatsFilled: (data['seatsFilled'] as int?) ?? 0,
        seatsTotal: data['seatCount'] as int,
        note: data['note'] as String?,
        durationMinutes: (data['routeDurationMinutes'] as num?)?.toInt(),
      );
    }).toList();
  }

  /// [fromAddress]/[toAddress] are whatever's currently entered on Home's
  /// Find-ride form (shared `HomeBloc`, see [_currentFindRideState]) — this
  /// tab only shows matches once that form actually has both set, and
  /// re-reads it fresh every time this future is (re)built.
  Future<List<_AvailableRide>> _fetchAvailableRides({
    String? fromAddress,
    String? toAddress,
    double? fromLat,
    double? fromLng,
    double? toLat,
    double? toLng,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];
    final userDoc = await _db.collection('users').doc(uid).get();

final matchRadiusKm =
    (userDoc.data()?['routeMatchingRadius'] as num?)?.toDouble() ?? 5.0;

    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);

    _hasCommuteLocation = (fromAddress?.trim().isNotEmpty ?? false) &&
        (toAddress?.trim().isNotEmpty ?? false);
    if (!_hasCommuteLocation) return [];

    final userHomeAddress = fromAddress!;
    final userOfficeAddress = toAddress!;
    final userHomeLat = fromLat;
    final userHomeLng = fromLng;
    final userOfficeLat = toLat;
    final userOfficeLng = toLng;

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
      final rideFromLat = (d['fromLat'] as num?)?.toDouble() ?? 
          (d['fromLatLng'] as Map<String, dynamic>?)?['latitude'] as double?;
      final rideFromLng = (d['fromLng'] as num?)?.toDouble() ?? 
          (d['fromLatLng'] as Map<String, dynamic>?)?['longitude'] as double?;
      final rideToLat = (d['toLat'] as num?)?.toDouble() ?? 
          (d['toLatLng'] as Map<String, dynamic>?)?['latitude'] as double?;
      final rideToLng = (d['toLng'] as num?)?.toDouble() ?? 
          (d['toLatLng'] as Map<String, dynamic>?)?['longitude'] as double?;
      final rideRouteDistanceKm = (d['routeDistanceKm'] as num?)?.toDouble();
      final fareMap = d['fare'] as Map<String, dynamic>?;
      final farePerSeat = (fareMap?['farePerSeat'] as num?)?.toDouble();

      // Only worth a live Google Directions call when the user's commute
      // points aren't already close to the ride's own endpoints — that case
      // is already a match without needing a real-route detour check.
      double? liveDetourKm;
      final haveUserCoords = userHomeLat != null &&
          userHomeLng != null &&
          userOfficeLat != null &&
          userOfficeLng != null;
      final haveRideCoords = rideFromLat != null &&
          rideFromLng != null &&
          rideToLat != null &&
          rideToLng != null;
      if (haveUserCoords && haveRideCoords && rideRouteDistanceKm != null) {
        final endpointsClose =
            RideMatcher.distanceKm(userHomeLat, userHomeLng, rideFromLat, rideFromLng) <=
                    matchRadiusKm &&
                RideMatcher.distanceKm(userOfficeLat, userOfficeLng, rideToLat, rideToLng) <=
                    matchRadiusKm;
        if (!endpointsClose) {
          final viaDistanceKm = await _directions.fetchRouteDistanceKm(
            originLat: rideFromLat,
            originLng: rideFromLng,
            destLat: rideToLat,
            destLng: rideToLng,
            waypoints: [
              [userHomeLat, userHomeLng],
              [userOfficeLat, userOfficeLng],
            ],
          );
          if (viaDistanceKm != null) {
            liveDetourKm = viaDistanceKm - rideRouteDistanceKm;
          }
        }
      }

      final match = RideMatcher.computeMatch(
        userFromAddress: userHomeAddress,
        userToAddress: userOfficeAddress,
        userFromLat: userHomeLat,
        userFromLng: userHomeLng,
        userToLat: userOfficeLat,
        userToLng: userOfficeLng,
        rideFromAddress: rideFrom,
        rideToAddress: rideTo,
        rideFromLat: rideFromLat,
        rideFromLng: rideFromLng,
        rideToLat: rideToLat,
        rideToLng: rideToLng,
        liveDetourKm: liveDetourKm,
        matchRadiusKm: matchRadiusKm,
      );
      if (!match.isMatch) continue;

      final endpointsClose =
          userHomeLat != null && userHomeLng != null &&
          rideFromLat != null && rideFromLng != null &&
          RideMatcher.distanceKm(userHomeLat, userHomeLng, rideFromLat, rideFromLng) <=
                  RideMatcher.maxMatchDistanceKm;

      rides.add(_AvailableRide(
        id: doc.id,
        driverId: d['uid'] as String,
        driverName: driverName,
        date: date,
        time: TimeOfDay(
            hour: timeMap['hour'] as int, minute: timeMap['minute'] as int),
        fromAddress: rideFrom,
        toAddress: rideTo,
        fromLat: rideFromLat,
        fromLng: rideFromLng,
        toLat: rideToLat,
        toLng: rideToLng,
        seatsFilled: seatsFilled,
        seatsTotal: seatCount,
        vehicleType: d['vehicleType'] as String? ?? 'car',
        alreadyRequested: requestedRideIds.contains(doc.id),
        matchPercent: match.matchPercent,
        distanceKm: match.distanceKm,
        defaultPickupPoint:
            userHomeAddress.isNotEmpty ? userHomeAddress : rideFrom,
        farePerSeat: farePerSeat,
        userFromAddress: userHomeAddress,
        userToAddress: userOfficeAddress,
        userFromLat: userHomeLat,
        userFromLng: userHomeLng,
        userToLat: userOfficeLat,
        userToLng: userOfficeLng,
      ));
    }

    rides.sort((a, b) => b.matchPercent.compareTo(a.matchPercent));
    return rides;
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
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Trips',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: false,
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: AppColors.grey500,
          indicatorColor: AppColors.primaryGreen,
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Find ride tab
          FutureBuilder<List<_AvailableRide>>(
            future: _ridesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final rides = snapshot.data ?? [];
              if (!_hasCommuteLocation) {
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
              if (rides.isEmpty) {
                return Center(
                  child: Text(
                    'No matching rides found for your commute.',
                    style: TextStyle(color: AppColors.grey500, fontSize: 16),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _ridesFuture = _fetchAvailableRidesFromHomeState();
                  });
                },
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: rides.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) => _AvailableRideCard(
                    ride: rides[index],
                    db: _db,
                    onRequested: () {
                      setState(() {
                        _ridesFuture = _fetchAvailableRidesFromHomeState();
                      });
                    },
                  ),
                ),
              );
            },
          ),

          // Offer ride tab
          _buildList(
            _drivesFuture,
            'You haven\'t offered any rides yet.',
            onTap: (trip) => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DrivesDetailPage(trip: trip),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
    this.fromLat,
    this.fromLng,
    this.toLat,
    this.toLng,
    required this.seatsFilled,
    required this.seatsTotal,
    required this.vehicleType,
    required this.alreadyRequested,
    required this.matchPercent,
    required this.defaultPickupPoint,
    required this.distanceKm,
    this.farePerSeat,
    this.userFromAddress = '',
    this.userToAddress = '',
    this.userFromLat,
    this.userFromLng,
    this.userToLat,
    this.userToLng,
  });

  final String id;
  final String driverId;
  final String driverName;
  final DateTime date;
  final TimeOfDay time;
  final String fromAddress;
  final String toAddress;
  final double? fromLat;
  final double? fromLng;
  final double? toLat;
  final double? toLng;
  final int seatsFilled;
  final int seatsTotal;
  final String vehicleType;
  final bool alreadyRequested;
  final int matchPercent;
  final String defaultPickupPoint;
  final double? distanceKm;
  final double? farePerSeat;
  final String userFromAddress;
  final String userToAddress;
  final double? userFromLat;
  final double? userFromLng;
  final double? userToLat;
  final double? userToLng;

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

      // Decide if we should meet at driver's endpoints (Endpoint Match) 
      // or at rider's requested points (Detour Match).
      bool isEndpointMatch = false;
      if (widget.ride.userFromLat != null && widget.ride.userFromLng != null &&
          widget.ride.fromLat != null && widget.ride.fromLng != null &&
          widget.ride.userToLat != null && widget.ride.userToLng != null &&
          widget.ride.toLat != null && widget.ride.toLng != null) {
        final dFrom = RideMatcher.distanceKm(widget.ride.userFromLat!, widget.ride.userFromLng!, widget.ride.fromLat!, widget.ride.fromLng!);
        final dTo = RideMatcher.distanceKm(widget.ride.userToLat!, widget.ride.userToLng!, widget.ride.toLat!, widget.ride.toLng!);
        isEndpointMatch = dFrom <= RideMatcher.maxMatchDistanceKm && dTo <= RideMatcher.maxMatchDistanceKm;
      }

      final pickupPoint = isEndpointMatch ? widget.ride.fromAddress : widget.ride.userFromAddress;
      final pickupLatLng = isEndpointMatch 
          ? {'latitude': widget.ride.fromLat, 'longitude': widget.ride.fromLng}
          : (widget.ride.userFromLat != null && widget.ride.fromLat != null 
              ? RideMatcher.projectPointToSegment(widget.ride.fromLat!, widget.ride.fromLng!, widget.ride.toLat!, widget.ride.toLng!, widget.ride.userFromLat!, widget.ride.userFromLng!)
              : {'latitude': widget.ride.userFromLat, 'longitude': widget.ride.userFromLng});

      final dropOffPoint = isEndpointMatch ? widget.ride.toAddress : widget.ride.userToAddress;
      final dropOffLatLng = isEndpointMatch
          ? {'latitude': widget.ride.toLat, 'longitude': widget.ride.toLng}
          : (widget.ride.userToLat != null && widget.ride.fromLat != null 
              ? RideMatcher.projectPointToSegment(widget.ride.fromLat!, widget.ride.fromLng!, widget.ride.toLat!, widget.ride.toLng!, widget.ride.userToLat!, widget.ride.userToLng!)
              : {'latitude': widget.ride.userToLat, 'longitude': widget.ride.userToLng});

      final requestRef = widget.db.collection('ride_requests').doc();
      final rideRef = widget.db.collection('rides').doc(widget.ride.id);
      final batch = widget.db.batch();

      batch.set(requestRef, {
        'rideId': widget.ride.id,
        'riderId': uid,
        'riderName': riderName,
        'riderPhotoUrl': riderPhotoUrl,
        'riderStartAddress': widget.ride.userFromAddress,
        'riderEndAddress': widget.ride.userToAddress,
        'riderStartLatLng': (widget.ride.userFromLat != null && widget.ride.userFromLng != null) ? {
          'latitude': widget.ride.userFromLat,
          'longitude': widget.ride.userFromLng,
        } : null,
        'riderEndLatLng': (widget.ride.userToLat != null && widget.ride.userToLng != null) ? {
          'latitude': widget.ride.userToLat,
          'longitude': widget.ride.userToLng,
        } : null,
        'pickupPoint': pickupPoint,
        'pickupLatLng': pickupLatLng,
        'dropOffPoint': dropOffPoint,
        'dropOffLatLng': dropOffLatLng,
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

    return GestureDetector(
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
              db: widget.db,
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
      child: Container(
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
                                size: 12, color: AppColors.grey600),
                            const SizedBox(width: 4),
                            Text(
                              r.distanceLabel ??
                                  (r.vehicleType == 'bike' ? 'Bike' : 'Car'),
                              style: TextStyle(
                                fontSize: 11.5,
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
                              size: 14,
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
                      Text(
                        r.farePerSeat != null
                            ? '₹${r.farePerSeat!.toStringAsFixed(2)} / seat'
                            : 'Fare not set',
                        style: TextStyle(
                          color: r.farePerSeat != null
                              ? AppColors.primaryGreen
                              : AppColors.grey500,
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
