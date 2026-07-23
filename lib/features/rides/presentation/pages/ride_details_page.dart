import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/features/rides/domain/entities/ride_match.dart';
import 'package:acepool/features/rides/presentation/pages/track_route_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RideDetailsPage extends StatefulWidget {
  const RideDetailsPage({
    super.key,
    required this.ride,
    required this.db,
    this.riderFromAddress,
    this.riderFromLat,
    this.riderFromLng,
    this.riderToAddress,
    this.riderToLat,
    this.riderToLng,
  });

  final RideMatch ride;
  final FirebaseFirestore db;
  final String? riderFromAddress;
  final double? riderFromLat;
  final double? riderFromLng;
  final String? riderToAddress;
  final double? riderToLat;
  final double? riderToLng;

  @override
  State<RideDetailsPage> createState() => _RideDetailsPageState();
}

class _RideDetailsPageState extends State<RideDetailsPage> {
  late Future<List<_RiderInfo>> _ridersFuture;
  final _messageController = TextEditingController();
  bool _submitting = false;
  bool _justRequested = false;

  @override
  void initState() {
    super.initState();
    _ridersFuture = _fetchRiders();
    _justRequested = widget.ride.alreadyRequested;
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<List<_RiderInfo>> _fetchRiders() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final snap = await widget.db
        .collection('ride_requests')
        .where('rideId', isEqualTo: widget.ride.id)
        .where('status', isEqualTo: 'accepted')
        .get();

    final riders = <_RiderInfo>[];
    for (final doc in snap.docs) {
      final d = doc.data();
      final riderId = d['riderId'] as String? ?? '';
      
      if (riderId == uid) continue;
      
      String employeeId = 'AE2610002'; // Default placeholder
      try {
        final userDoc = await widget.db
            .collection('users')
            .doc(riderId)
            .get();
        employeeId = userDoc.data()?['employeeId'] as String? ?? 'AE2610002';
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
      }

      riders.add(_RiderInfo(
        riderId: riderId,
        riderName: d['riderName'] as String? ?? '',
        riderPhotoUrl: d['riderPhotoUrl'] as String?,
        employeeId: employeeId,
        pickupPoint: d['pickupPoint'] as String? ?? '',
        position: position,
        pickupTime: TimeOfDay(
          hour: (pickupTimeMap['hour'] as num).toInt(),
          minute: (pickupTimeMap['minute'] as num).toInt(),
        ),
      ));
    }
    return riders;
  }

  void _openMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrackRoutePage(
          ride: widget.ride,
          riderFromAddress: widget.riderFromAddress,
          riderFromLat: widget.riderFromLat,
          riderFromLng: widget.riderFromLng,
          riderToAddress: widget.riderToAddress,
          riderToLat: widget.riderToLat,
          riderToLng: widget.riderToLng,
        ),
      ),
    );
  }

  Future<void> _requestRide() async {
    if (_justRequested || _submitting) return;
    setState(() => _submitting = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      String riderName = '';
      String? riderPhotoUrl;
      try {
        final userDoc = await widget.db.collection('users').doc(uid).get();
        riderName = userDoc.data()?['fullName'] as String? ?? '';
        riderPhotoUrl = userDoc.data()?['profileImageUrl'] as String?;
      } catch (_) {}

      final requestRef = widget.db.collection('ride_requests').doc();
      final rideRef = widget.db.collection('rides').doc(widget.ride.id);
      
      final batch = widget.db.batch();
      batch.set(requestRef, {
        'rideId': widget.ride.id,
        'riderId': uid,
        'riderName': riderName,
        'riderPhotoUrl': riderPhotoUrl,
        'riderStartAddress': widget.riderFromAddress ?? widget.ride.fromAddress,
        'riderEndAddress': widget.riderToAddress ?? widget.ride.toAddress,
        'riderStartLatLng': (widget.riderFromLat != null && widget.riderFromLng != null)
            ? {'latitude': widget.riderFromLat, 'longitude': widget.riderFromLng}
            : null,
        'riderEndLatLng': (widget.riderToLat != null && widget.riderToLng != null)
            ? {'latitude': widget.riderToLat, 'longitude': widget.riderToLng}
            : null,
        'pickupPoint': widget.ride.fromAddress,
        'pickupLatLng': (widget.ride.fromLat != null && widget.ride.fromLng != null)
            ? {'latitude': widget.ride.fromLat, 'longitude': widget.ride.fromLng}
            : null,
        'dropOffPoint': widget.ride.toAddress,
        'dropOffLatLng': (widget.ride.toLat != null && widget.ride.toLng != null)
            ? {'latitude': widget.ride.toLat, 'longitude': widget.ride.toLng}
            : null,
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
        _ridersFuture = _fetchRiders();
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
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ride Details',
          style: TextStyle(
            color: AppColors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_none_outlined, color: AppColors.black, size: 28),
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              ],
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<_RiderInfo>>(
        future: _ridersFuture,
        builder: (context, snapshot) {
          final riders = snapshot.data ?? [];
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRideMainCard(r),
                if (widget.riderFromAddress != null && widget.riderToAddress != null)
                  _buildYourTripCard(),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'OTHER RIDERS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.grey700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      TextButton(
                        onPressed: _openMap,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'View On Map',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.black54,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ))
                else if (snapshot.hasError)
                  Center(child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text('Error loading riders: ${snapshot.error}', style: const TextStyle(color: AppColors.red)),
                  ))
                else if (riders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text('No other riders yet'),
                  )
                else
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.grey200),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: riders.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.black12),
                      itemBuilder: (context, index) => _RiderItem(rider: riders[index]),
                    ),
                  ),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildYourTripCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR TRIP',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryGreen,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryGreen, width: 2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.riderFromAddress!,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(left: 4.5),
            height: 12,
            width: 1,
            color: AppColors.primaryGreen.withOpacity(0.3),
          ),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.riderToAddress!,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRideMainCard(RideMatch r) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
// ... (rest of the code)
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFF6B6B6B),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_outline, color: AppColors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${r.seatsFilled} /${r.seatsTotal} seats filled',
                      style: const TextStyle(
                        color: AppColors.white, 
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10, right: 12),
                child: Row(
                  children: [
                    Text(
                      '${r.matchPercent}% Match',
                      style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.more_vert, size: 20, color: AppColors.grey600),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      r.dateLabel,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    Row(
                      children: [
                        Icon(Icons.directions_walk, size: 14, color: AppColors.grey600),
                        const SizedBox(width: 4),
                        Text(
                          r.distanceLabel ?? '500 m',
                          style: TextStyle(fontSize: 12, color: AppColors.grey600, fontWeight: FontWeight.w500),
                        ),
                        Icon(Icons.chevron_right, size: 16, color: AppColors.grey400),
                        const SizedBox(width: 4),
                        const Icon(Icons.directions_car, size: 18, color: AppColors.black),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      r.timeLabel,
                      style: const TextStyle(color: AppColors.black, fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.grey200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.directions_car, size: 14, color: AppColors.black87),
                          const SizedBox(width: 6),
                          const Text(
                            'Car',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.black12),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundImage: r.driverPhotoUrl != null
                          ? NetworkImage(r.driverPhotoUrl!)
                          : null,
                      backgroundColor: AppColors.grey300,
                      child: r.driverPhotoUrl == null ? const Icon(Icons.person) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.driverName,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          Text(
                            'Verified ID',
                            style: TextStyle(color: AppColors.grey500, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.phone_outlined, size: 22, color: AppColors.grey700),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 16),
                    Text('|', style: TextStyle(color: AppColors.grey300, fontSize: 20)),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(Icons.chat_bubble_outline, size: 22, color: AppColors.grey700),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildRouteLine(r.fromAddress, r.toAddress),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.black12),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      r.farePerSeat != null
                          ? '₹ ${r.farePerSeat!.toInt()} / seat'
                          : '₹ 600 / seat',
                      style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'View Details',
                        style: TextStyle(
                          color: AppColors.black54,
                          decoration: TextDecoration.underline,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Share message with driver',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: AppColors.grey400, fontSize: 14),
                            isDense: true,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _requestRide,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                          child: _submitting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                            : const Icon(Icons.send, color: AppColors.white, size: 18),
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

  Widget _buildRouteLine(String from, String to) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryGreen, width: 2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                from,
                style: const TextStyle(fontSize: 14, color: AppColors.black87, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(left: 7),
            height: 20,
            width: 1.5,
            child: Column(
              children: List.generate(3, (index) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  color: AppColors.grey300,
                ),
              )),
            ),
          ),
        ),
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                to,
                style: const TextStyle(fontSize: 14, color: Color(0xFF333333), fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColors.grey500,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Icon(Icons.home_outlined, size: 28),
          ), label: 'Home'),
          BottomNavigationBarItem(icon: Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Icon(Icons.directions_car_outlined, size: 28),
          ), label: 'Trips'),
          BottomNavigationBarItem(icon: Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Icon(Icons.chat_bubble_outline, size: 26),
          ), label: 'Chats'),
          BottomNavigationBarItem(icon: Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Icon(Icons.person_outline, size: 28),
          ), label: 'Profile'),
        ],
      ),
    );
  }
}

class _RiderInfo {
  const _RiderInfo({
    required this.riderId,
    required this.riderName,
    this.riderPhotoUrl,
    required this.employeeId,
    required this.pickupPoint,
    this.position,
    required this.pickupTime,
  });

  final String riderId;
  final String riderName;
  final String? riderPhotoUrl;
  final String employeeId;
  final String pickupPoint;
  final LatLng? position;
  final TimeOfDay pickupTime;

  String get pickupTimeLabel {
    final h = pickupTime.hourOfPeriod == 0 ? 12 : pickupTime.hourOfPeriod;
    final m = pickupTime.minute.toString().padLeft(2, '0');
    final period = pickupTime.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }
}

class _RiderItem extends StatelessWidget {
  const _RiderItem({required this.rider});
  final _RiderInfo rider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: rider.riderPhotoUrl != null
                    ? NetworkImage(rider.riderPhotoUrl!)
                    : null,
                backgroundColor: AppColors.grey300,
                child: rider.riderPhotoUrl == null ? const Icon(Icons.person, size: 18) : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rider.riderName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    Text(
                      rider.employeeId,
                      style: TextStyle(color: AppColors.grey500, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(Icons.directions_car_outlined, size: 14, color: AppColors.grey600),
                  const SizedBox(width: 4),
                  Text('25mins >', style: TextStyle(fontSize: 11, color: AppColors.grey600, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  Icon(Icons.location_on_outlined, size: 16, color: AppColors.grey600),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pick up point: ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black),
              ),
              Expanded(
                child: Text(
                  rider.pickupPoint,
                  style: const TextStyle(fontSize: 12, color: AppColors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.map_outlined, size: 14, color: AppColors.grey400),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Text(
                'Time: ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black),
              ),
              Text(
                rider.pickupTimeLabel,
                style: const TextStyle(fontSize: 12, color: AppColors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
