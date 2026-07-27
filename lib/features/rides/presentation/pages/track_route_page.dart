import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/core/utils/ride_matcher.dart';
import 'package:acepool/features/rides/domain/entities/ride_match.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class TrackRoutePage extends StatefulWidget {
  const TrackRoutePage({
    super.key,
    required this.ride,
    this.riderFromAddress,
    this.riderFromLat,
    this.riderFromLng,
    this.riderToAddress,
    this.riderToLat,
    this.riderToLng,
  });

  final RideMatch ride;
  final String? riderFromAddress;
  final double? riderFromLat;
  final double? riderFromLng;
  final String? riderToAddress;
  final double? riderToLat;
  final double? riderToLng;

  @override
  State<TrackRoutePage> createState() => _TrackRoutePageState();
}

class _TrackRoutePageState extends State<TrackRoutePage> {
  static final _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'acepool',
  );

  late GoogleMapController _mapController;
  Position? _currentPosition;
  
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  LatLng? _riderPickupLatLng;
  LatLng? _riderDropLatLng;
  String _riderPickupPoint = '';
  String _riderDropPoint = '';
  String _riderStartAddress = '';
  String _riderEndAddress = '';
  LatLng? _riderStartLatLng;
  LatLng? _riderEndLatLng;

  LatLng? _pinnedLatLng;
  String? _pinnedName;

  int _driveDurationMinutes = 20; // Default estimate
  bool _loadingData = true;

  @override
  void initState() {
    super.initState();
    _riderStartAddress = widget.riderFromAddress ?? '';
    _riderEndAddress = widget.riderToAddress ?? '';
    if (widget.riderFromLat != null && widget.riderFromLng != null) {
      _riderStartLatLng = LatLng(widget.riderFromLat!, widget.riderFromLng!);
    }
    if (widget.riderToLat != null && widget.riderToLng != null) {
      _riderEndLatLng = LatLng(widget.riderToLat!, widget.riderToLng!);
    }
    _fetchJourneyData();
  }

  Future<void> _fetchJourneyData() async {
    if (!mounted) return;
    setState(() => _loadingData = true);
    
    // 1. Determine Current Location
    await _determinePosition();

    // 2. Fetch User's Ride Request
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final requestSnap = await _db
          .collection('ride_requests')
          .where('rideId', isEqualTo: widget.ride.id)
          .where('riderId', isEqualTo: uid)
          .where('status', isEqualTo: 'accepted')
          .limit(1)
          .get();

      if (requestSnap.docs.isNotEmpty) {
        final d = requestSnap.docs.first.data();
        _riderPickupPoint = d['pickupPoint'] as String? ?? '';
        _riderDropPoint = d['dropOffPoint'] as String? ?? '';
        
        // Only overwrite if not provided via constructor
        if (_riderStartAddress.isEmpty) {
          _riderStartAddress = d['riderStartAddress'] as String? ?? '';
        }
        if (_riderEndAddress.isEmpty) {
          _riderEndAddress = d['riderEndAddress'] as String? ?? '';
        }
        
        if (d['pickupLatLng'] != null) {
          final latLngMap = d['pickupLatLng'] as Map<String, dynamic>;
          _riderPickupLatLng = LatLng(
            (latLngMap['latitude'] as num).toDouble(),
            (latLngMap['longitude'] as num).toDouble(),
          );
        }
        
        if (d['dropOffLatLng'] != null) {
          final latLngMap = d['dropOffLatLng'] as Map<String, dynamic>;
          _riderDropLatLng = LatLng(
            (latLngMap['latitude'] as num).toDouble(),
            (latLngMap['longitude'] as num).toDouble(),
          );
        }

        if (_riderStartLatLng == null && d['riderStartLatLng'] != null) {
          final latLngMap = d['riderStartLatLng'] as Map<String, dynamic>;
          _riderStartLatLng = LatLng(
            (latLngMap['latitude'] as num).toDouble(),
            (latLngMap['longitude'] as num).toDouble(),
          );
        }

        if (_riderEndLatLng == null && d['riderEndLatLng'] != null) {
          final latLngMap = d['riderEndLatLng'] as Map<String, dynamic>;
          _riderEndLatLng = LatLng(
            (latLngMap['latitude'] as num).toDouble(),
            (latLngMap['longitude'] as num).toDouble(),
          );
        }
      } else {
        // If no accepted request, use driver's start/end as default pickup/drop-off for visualization
        _riderPickupPoint = widget.ride.fromAddress;
        _riderDropPoint = widget.ride.toAddress;
      }
    }

    // 3. Fetch Pinned location and route info from Driver's Ride
    final rideDoc = await _db.collection('rides').doc(widget.ride.id).get();
    if (rideDoc.exists) {
      final d = rideDoc.data();
      if (d?['pinnedLatLng'] != null) {
        final latLngMap = d!['pinnedLatLng'] as Map<String, dynamic>;
        _pinnedLatLng = LatLng(
          (latLngMap['latitude'] as num).toDouble(),
          (latLngMap['longitude'] as num).toDouble(),
        );
        _pinnedName = d['pinnedName'] as String?;
      }
      if (d?['routeDurationMinutes'] != null) {
        _driveDurationMinutes = (d!['routeDurationMinutes'] as num).toInt();
      }
    }

    _calculateRoadsidePoints();
    _initMarkers();
    if (mounted) setState(() => _loadingData = false);
  }

  void _calculateRoadsidePoints() {
    final r = widget.ride;

    String getArea(String address) {
      final parts = address.split(',');
      for (var p in parts) {
        String s = p.trim();
        // Avoid plus codes and short numbers
        if (s.length > 3 && !s.contains('+') && !RegExp(r'^\d').hasMatch(s)) {
          return s;
        }
      }
      return parts[0].trim();
    }

    String getMainRoadName(String address) {
      String area = getArea(address);
      if (area.toLowerCase().contains("main road")) return area;
      return "$area Main Road";
    }

    // 1. Pickup Point calculation
    if (_riderStartLatLng != null && r.fromLat != null && r.toLat != null) {
      final distToDriverStart = RideMatcher.distanceKm(
          _riderStartLatLng!.latitude,
          _riderStartLatLng!.longitude,
          r.fromLat!,
          r.fromLng!);
      
      if (distToDriverStart <= 0.4) {
        _riderPickupLatLng = LatLng(r.fromLat!, r.fromLng!);
        // Use existing point if it's meaningful, otherwise use driver's start area
        if (_riderPickupPoint.isEmpty || _riderPickupPoint.contains("Main Road") || _riderPickupPoint.startsWith("Road near")) {
          String addr = r.fromAddress;
          // If address starts with plus code, skip it
          if (addr.contains(',') && RegExp(r'^[A-Z0-9]{4}\+').hasMatch(addr)) {
            _riderPickupPoint = addr.split(',')[1].trim();
          } else {
            _riderPickupPoint = addr.split(',')[0];
          }
        }
      } else {
        final projected = RideMatcher.projectPointToSegment(
          r.fromLat!, r.fromLng!,
          r.toLat!, r.toLng!,
          _riderStartLatLng!.latitude, _riderStartLatLng!.longitude,
        );
        _riderPickupLatLng = LatLng(projected['latitude']!, projected['longitude']!);
        
        // Only use generic "Main Road" if we don't already have a specific landmark
        if (_riderPickupPoint.isEmpty || _riderPickupPoint.contains("Main Road") || _riderPickupPoint.startsWith("Road near")) {
           _riderPickupPoint = getMainRoadName(r.fromAddress);
        }
      }
    } else {
      _riderPickupLatLng ??= LatLng(r.fromLat ?? 0, r.fromLng ?? 0);
      if (_riderPickupPoint.isEmpty) _riderPickupPoint = r.fromAddress.split(',')[0];
    }

    // 2. Drop Point calculation
    if (_riderEndLatLng != null && r.fromLat != null && r.toLat != null) {
      final distToDriverEnd = RideMatcher.distanceKm(
          _riderEndLatLng!.latitude,
          _riderEndLatLng!.longitude,
          r.toLat!,
          r.toLng!);

      if (distToDriverEnd <= 0.4) {
        _riderDropLatLng = LatLng(r.toLat!, r.toLng!);
        if (_riderDropPoint.isEmpty || _riderDropPoint.contains("Road near")) {
          _riderDropPoint = r.toAddress.split(',')[0];
        }
      } else {
        final projected = RideMatcher.projectPointToSegment(
          r.fromLat!, r.fromLng!,
          r.toLat!, r.toLng!,
          _riderEndLatLng!.latitude, _riderEndLatLng!.longitude,
        );
        _riderDropLatLng = LatLng(projected['latitude']!, projected['longitude']!);
        _riderDropPoint = getMainRoadName(r.toAddress);
      }
    } else {
      _riderDropLatLng ??= LatLng(r.toLat ?? 0, r.toLng ?? 0);
      if (_riderDropPoint.isEmpty) _riderDropPoint = r.toAddress.split(',')[0];
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    if (permission == LocationPermission.deniedForever) return; 

    final pos = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentPosition = pos;
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(pos.latitude, pos.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          ),
        );
      });
    }
  }

  void _initMarkers() {
    if (_riderPickupLatLng != null) {
      _markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: _riderPickupLatLng!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }
    if (_riderDropLatLng != null) {
      _markers.add(Marker(
        markerId: const MarkerId('dropoff'),
        position: _riderDropLatLng!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }
    if (_pinnedLatLng != null) {
      _markers.add(Marker(
        markerId: const MarkerId('pinned'),
        position: _pinnedLatLng!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingData) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final r = widget.ride;

    // Distances calculation
    double walkToPickupKm = 0;
    final startPos = _riderStartLatLng ?? (_currentPosition != null ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude) : null);
    if (startPos != null && _riderPickupLatLng != null) {
      walkToPickupKm = RideMatcher.distanceKm(startPos.latitude, startPos.longitude, _riderPickupLatLng!.latitude, _riderPickupLatLng!.longitude);
    }

    double walkFromDropKm = 0;
    bool sameAsDriverEnd = false;
    final endPos = _riderEndLatLng ?? (r.toLat != null && r.toLng != null ? LatLng(r.toLat!, r.toLng!) : null);
    
    if (_riderDropLatLng != null && endPos != null) {
       final dist = RideMatcher.distanceKm(_riderDropLatLng!.latitude, _riderDropLatLng!.longitude, endPos.latitude, endPos.longitude);
       if (dist < 0.1) {
         sameAsDriverEnd = true;
       } else {
         walkFromDropKm = dist;
       }
    }

    int walkToPickupMin = (walkToPickupKm * 12).round();
    int walkFromDropMin = (walkFromDropKm * 12).round();
    int totalJourneyMin = walkToPickupMin + _driveDurationMinutes + walkFromDropMin;

    DateTime startTime = DateTime(r.date.year, r.date.month, r.date.day, r.time.hour, r.time.minute);
    DateTime arrivalTime = startTime.add(Duration(minutes: _driveDurationMinutes));
    DateTime finalDestinationTime = arrivalTime.add(Duration(minutes: walkFromDropMin));
    DateTime journeyStartTime = startTime.subtract(Duration(minutes: walkToPickupMin));

    String formatTime(DateTime dt) {
      final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final m = dt.minute.toString().padLeft(2, '0');
      final p = dt.hour >= 12 ? 'PM' : 'AM';
      return "$h:$m $p";
    }

    String arrivalTimeLabel = formatTime(arrivalTime);
    String journeyRangeLabel = "${formatTime(journeyStartTime)} - ${formatTime(finalDestinationTime)}";

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _riderPickupLatLng ?? LatLng(r.fromLat ?? 0, r.fromLng ?? 0),
              zoom: 14,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 20,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTopRouteCard(r),
                ],
              ),
            ),
          ),

          DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.15,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return _buildBottomSheet(context, scrollController, walkToPickupKm, walkFromDropKm, sameAsDriverEnd, totalJourneyMin, arrivalTimeLabel, journeyRangeLabel);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopRouteCard(RideMatch r) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRouteItem(r.fromAddress, isStart: true),
          Padding(
            padding: const EdgeInsets.only(left: 7),
            child: Container(height: 16, width: 1, color: AppColors.grey300),
          ),
          _buildRouteItem(r.toAddress, isStart: false),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.black12),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.grey600),
              const SizedBox(width: 8),
              Text(r.dateLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: AppColors.grey600),
              const SizedBox(width: 8),
              Text(r.timeLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const Spacer(),
              _buildSeatsChip(r),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeatsChip(RideMatch r) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_outline, size: 14, color: AppColors.black87),
          const SizedBox(width: 4),
          Text('${r.seatsFilled}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          const Icon(Icons.keyboard_arrow_down, size: 16),
        ],
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context, ScrollController scrollController, double walkToPickup, double walkFromDrop, bool sameAsDriverEnd, int totalJourneyMin, String arrivalTimeLabel, String journeyRangeLabel) {
    final r = widget.ride;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)],
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          _buildTransportDetailsHeader(context),
          const SizedBox(height: 16),
          _buildJourneySummaryIcons(walkToPickup, walkFromDrop, totalJourneyMin),
          const SizedBox(height: 8),
          _buildPriceAndArrival(r, journeyRangeLabel),
          const SizedBox(height: 12),
          Text('*Actual arrival time may vary due to traffic and road conditions', style: TextStyle(fontSize: 11, color: AppColors.grey400)),
          const SizedBox(height: 24),
          _buildPickupPointsHeader(),
          const SizedBox(height: 16),
          
          // Journey Timeline
          _buildTimelineItem(
            title: _riderStartAddress.isNotEmpty ? _riderStartAddress.split(',')[0] : 'Current Location',
            subtitle: 'Your Current Location',
            time: 'Now',
            icon: Icons.location_on_outlined,
            iconColor: AppColors.grey400,
          ),
          
          if (_pinnedLatLng != null)
            _buildTimelineItem(
              title: _pinnedName ?? 'Pinned Location',
              subtitle: 'Pinned',
              time: '',
              icon: Icons.location_on,
              iconColor: AppColors.accentBlue,
            ),

          _buildWalkSegment('Walk ${RideMatcher.formatDistance(walkToPickup)} (${(walkToPickup * 12).round()} min)'),
          
          _buildTimelineItem(
            title: _riderPickupPoint.split(',')[0],
            subtitle: 'Pick Up Point',
            time: r.timeLabel,
            icon: Icons.directions_car,
            iconColor: AppColors.grey400,
            isCarLeg: true,
          ),
          
          _buildTimelineItem(
            title: _riderDropPoint.split(',')[0],
            subtitle: 'Drop Point',
            time: arrivalTimeLabel,
            icon: Icons.location_on_outlined,
            iconColor: AppColors.primaryGreen,
          ),
          
          if (!sameAsDriverEnd && walkFromDrop > 0.05) ...[
            _buildWalkSegment('Walk ${RideMatcher.formatDistance(walkFromDrop)} (${(walkFromDrop * 12).round() + 1} min)'),
            _buildTimelineItem(
              title: _riderEndAddress.isNotEmpty ? _riderEndAddress.split(',')[0] : r.toAddress.split(',')[0],
              subtitle: 'Final Destination',
              description: _riderEndAddress.isNotEmpty && _riderEndAddress.contains(',') 
                  ? _riderEndAddress.substring(_riderEndAddress.indexOf(',') + 1).trim()
                  : (r.toAddress.contains(',') ? r.toAddress.substring(r.toAddress.indexOf(',') + 1).trim() : null),
              time: 'Arrival',
              icon: Icons.location_on,
              iconColor: AppColors.red,
              isLast: true,
            ),
          ] else
            _buildTimelineItem(
              title: _riderEndAddress.isNotEmpty ? _riderEndAddress.split(',')[0] : r.toAddress.split(',')[0],
              subtitle: 'Final Destination',
              description: _riderEndAddress.isNotEmpty && _riderEndAddress.contains(',') 
                  ? _riderEndAddress.substring(_riderEndAddress.indexOf(',') + 1).trim()
                  : (r.toAddress.contains(',') ? r.toAddress.substring(r.toAddress.indexOf(',') + 1).trim() : null),
              time: 'Arrival',
              icon: Icons.location_on,
              iconColor: AppColors.red,
              isLast: true,
            ),

          const SizedBox(height: 24),
          _buildAdjustRadiusButton(),
        ],
      ),
    );
  }

  Widget _buildTransportDetailsHeader(BuildContext context) {
    return Row(
      children: [
        const Text('Transport details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Spacer(),
        GestureDetector(
          onTap: () => _showSOSDialog(context),
          child: const Icon(Icons.warning_amber_rounded, color: AppColors.red, size: 24),
        ),
        const SizedBox(width: 16),
        const Icon(Icons.share_outlined, size: 22),
        const SizedBox(width: 16),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: const Icon(Icons.close, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  void _showSOSDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: AppColors.red, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Emergency SOS',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.red),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: AppColors.black54),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.only(left: 44, right: 8),
                child: Text(
                  'Are you sure you want send an Emergency SOS alert?',
                  style: TextStyle(fontSize: 14, color: AppColors.black87, fontWeight: FontWeight.w500, height: 1.4),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          side: BorderSide(color: AppColors.grey300),
                        ),
                        child: const Text('Cancel', style: TextStyle(color: AppColors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('SOS alert sent successfully')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 0,
                        ),
                        child: const Text('Yes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJourneySummaryIcons(double walkTo, double walkFrom, int totalJourneyMin) {
    return Row(
      children: [
        Icon(Icons.directions_walk, size: 24, color: AppColors.black87),
        const SizedBox(width: 4),
        Text(RideMatcher.formatDistance(walkTo), style: TextStyle(fontSize: 12, color: AppColors.grey600)),
        Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Icon(Icons.chevron_right, size: 16, color: AppColors.grey400)),
        const Icon(Icons.directions_car, size: 24, color: AppColors.black87),
        if (walkFrom > 0.1) ...[
          Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Icon(Icons.chevron_right, size: 16, color: AppColors.grey400)),
          Icon(Icons.directions_walk, size: 24, color: AppColors.black87),
          const SizedBox(width: 4),
          Text(RideMatcher.formatDistance(walkFrom), style: TextStyle(fontSize: 12, color: AppColors.grey600)),
        ],
        const Spacer(),
        Text('$totalJourneyMin min*', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPriceAndArrival(RideMatch r, String timeRangeLabel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('$timeRangeLabel*', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        Text('₹ ${r.farePerSeat?.toInt() ?? 0} / seat', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
      ],
    );
  }

  Widget _buildPickupPointsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('PICKUP POINTS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.black54, letterSpacing: 1)),
        Row(
          children: [
            Text('${_pinnedLatLng != null ? 1 : 0} pinned', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const Icon(Icons.keyboard_arrow_down, size: 20),
          ],
        ),
      ],
    );
  }

  Widget _buildAdjustRadiusButton() {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.location_searching, size: 18),
      label: const Text('Adjust Radius'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.black87,
        side: BorderSide(color: AppColors.grey300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildRouteItem(String address, {required bool isStart}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: isStart ? Border.all(color: AppColors.primaryGreen, width: 2) : null,
            color: isStart ? Colors.transparent : AppColors.primaryGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            address,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Icon(Icons.map_outlined, size: 18, color: AppColors.grey400),
      ],
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String subtitle,
    required String time,
    required IconData icon,
    required Color iconColor,
    String? description,
    bool isCarLeg = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(icon, size: 20, color: iconColor),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isCarLeg ? AppColors.primaryGreen : AppColors.grey200,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(time, style: TextStyle(fontSize: 12, color: AppColors.grey600)),
                  ],
                ),
                Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                if (description != null && description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      description,
                      style: TextStyle(fontSize: 11, color: AppColors.grey500, height: 1.3),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalkSegment(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(Icons.directions_walk, size: 18, color: AppColors.grey400),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(fontSize: 13, color: AppColors.grey600)),
        ],
      ),
    );
  }
}
