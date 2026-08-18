import 'dart:ui';
import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/core/utils/location_share_helper.dart';
import 'package:acepool/core/utils/ride_matcher.dart';
import 'package:acepool/di/injection.dart';
import 'package:acepool/features/rides/domain/entities/ride_match.dart';
import 'package:acepool/features/rides/presentation/bloc/track_route_bloc.dart';
import 'package:acepool/features/rides/presentation/pages/security_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:acepool/features/profile/presentation/pages/route_matching_page.dart';
import 'package:acepool/features/rides/presentation/pages/payment_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final _bloc = sl<TrackRouteBloc>();

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

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  Future<void> _fetchJourneyData() async {
    if (!mounted) return;
    setState(() => _loadingData = true);

    // 1. Determine Current Location
    await _determinePosition();

    // 2+3. Fetch rider's pickup/drop-off (or driver's endpoints as fallback)
    // plus the driver's pinned location/route duration.
    _bloc.add(TrackRouteStarted(
      ride: widget.ride,
      riderFromAddress: widget.riderFromAddress,
      riderFromLat: widget.riderFromLat,
      riderFromLng: widget.riderFromLng,
      riderToAddress: widget.riderToAddress,
      riderToLat: widget.riderToLat,
      riderToLng: widget.riderToLng,
    ));
    final trackState =
        await _bloc.stream.firstWhere((s) => s.status != TrackRouteStatus.loading);
    final journey = trackState.journey;
    if (journey != null) {
      _riderPickupPoint = journey.pickupPoint;
      _riderDropPoint = journey.dropOffPoint;
      _riderStartAddress = journey.riderStartAddress;
      _riderEndAddress = journey.riderEndAddress;

      if (journey.pickupLat != null && journey.pickupLng != null) {
        _riderPickupLatLng = LatLng(journey.pickupLat!, journey.pickupLng!);
      }
      if (journey.dropOffLat != null && journey.dropOffLng != null) {
        _riderDropLatLng = LatLng(journey.dropOffLat!, journey.dropOffLng!);
      }
      if (journey.riderStartLat != null && journey.riderStartLng != null) {
        _riderStartLatLng = LatLng(journey.riderStartLat!, journey.riderStartLng!);
      }
      if (journey.riderEndLat != null && journey.riderEndLng != null) {
        _riderEndLatLng = LatLng(journey.riderEndLat!, journey.riderEndLng!);
      }
      if (journey.pinnedLat != null && journey.pinnedLng != null) {
        _pinnedLatLng = LatLng(journey.pinnedLat!, journey.pinnedLng!);
        _pinnedName = journey.pinnedName;
      }
      _driveDurationMinutes = journey.driveDurationMinutes;
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
        if (_riderPickupPoint.isEmpty || _riderPickupPoint.contains("Main Road") || _riderPickupPoint.startsWith("Road near") || _riderPickupPoint == "Pick Up Point") {
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
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Color(0xFF1D1D1D), size: 24),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTopRouteCard(r),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: DraggableScrollableSheet(
                  initialChildSize: 0.4,
                  minChildSize: 0.2,
                  maxChildSize: 1.0,
                  builder: (context, scrollController) {
                    return _buildBottomSheet(context, scrollController, walkToPickupKm, walkFromDropKm, sameAsDriverEnd, totalJourneyMin, arrivalTimeLabel, journeyRangeLabel);
                  },
                ),
              ),
            ],
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
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Source
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
                  r.fromAddress,
                  style: GoogleFonts.mulish(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    height: 18 / 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.map_outlined, size: 16, color: Color(0xFF757474)),
            ],
          ),
          
          // Divider Row with Vertical line connection
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 20,
                child: Center(
                  child: VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: AppColors.grey300,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.black12,
                ),
              ),
            ],
          ),

          // Destination
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
                  r.toAddress,
                  style: GoogleFonts.mulish(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    height: 18 / 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.map_outlined, size: 16, color: Color(0xFF757474)),
            ],
          ),
          
          const Divider(height: 24, thickness: 1, color: AppColors.black12),
          
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 20, color: Color(0xFF757474)),
              const SizedBox(width: 8),
              Text(
                r.dateLabel,
                style: GoogleFonts.mulish(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 20 / 14,
                  letterSpacing: 0.01,
                ),
              ),
            ],
          ),
          
          const Divider(height: 24, thickness: 1, color: AppColors.black12),

          Row(
            children: [
              const Icon(Icons.access_time, size: 20, color: Color(0xFF757474)),
              const SizedBox(width: 8),
              Text(
                r.timeLabel,
                style: GoogleFonts.mulish(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                width: 1,
                height: 20,
                color: AppColors.black12,
              ),
              const SizedBox(width: 12),
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
        padding: EdgeInsets.zero,
        children: [
          // End Ride Section with Drag Handle
          Container(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
            decoration: const BoxDecoration(
              color: Color(0xFFEBF5FB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Stop',
                            style: GoogleFonts.mulish(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E1E1E),
                              height: 24 / 16,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            _riderDropPoint.isNotEmpty
                                ? _riderDropPoint.split(',')[0]
                                : 'Calculating...',
                            style: GoogleFonts.mulish(
                              fontSize: 13,
                              color: const Color(0xFF4C515B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _navigateToPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDFDFD),
                        foregroundColor: const Color(0xFF1E1E1E),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        side: const BorderSide(color: Color(0xFFDDDDDD)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'End Ride',
                        style: GoogleFonts.mulish(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          height: 20 / 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Remaining content in white area
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTransportDetailsHeader(context),
                const SizedBox(height: 16),
                _buildJourneySummaryIcons(walkToPickup, walkFromDrop, totalJourneyMin),
                const SizedBox(height: 8),
                _buildPriceAndArrival(r, journeyRangeLabel),
                const SizedBox(height: 12),
                Text(
                  '*Actual arrival time may vary due to traffic and road conditions',
                  style: GoogleFonts.mulish(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF1D1D1D),
                    height: 20 / 14,
                    letterSpacing: 0.01,
                  ),
                ),
                const SizedBox(height: 24),
                _buildPickupPointsHeader(),
                const SizedBox(height: 16),
                // Journey Timeline
                _buildTimelineItem(
                  title: _riderStartAddress.isNotEmpty
                      ? _riderStartAddress.split(',')[0]
                      : 'Current Location',
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
                _buildWalkSegment(
                  'Walk ${RideMatcher.formatDistance(walkToPickup)} (${RideMatcher.formatDuration((walkToPickup * 12).round())})',
                ),
                _buildTimelineItem(
                  title: _riderPickupPoint.isNotEmpty
                      ? _riderPickupPoint.split(',')[0]
                      : 'Pick Up Point',
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
                  _buildWalkSegment(
                    'Walk ${RideMatcher.formatDistance(walkFromDrop)} (${RideMatcher.formatDuration((walkFromDrop * 12).round() + 1)})',
                  ),
                  _buildTimelineItem(
                    title: _riderEndAddress.isNotEmpty
                        ? _riderEndAddress.split(',')[0]
                        : r.toAddress.split(',')[0],
                    subtitle: 'Final Destination',
                    description: _riderEndAddress.isNotEmpty && _riderEndAddress.contains(',')
                        ? _riderEndAddress.substring(_riderEndAddress.indexOf(',') + 1).trim()
                        : (r.toAddress.contains(',')
                            ? r.toAddress.substring(r.toAddress.indexOf(',') + 1).trim()
                            : null),
                    time: 'Arrival',
                    icon: Icons.location_on,
                    iconColor: AppColors.red,
                    isLast: true,
                  ),
                ] else
                  _buildTimelineItem(
                    title: _riderEndAddress.isNotEmpty
                        ? _riderEndAddress.split(',')[0]
                        : r.toAddress.split(',')[0],
                    subtitle: 'Final Destination',
                    description: _riderEndAddress.isNotEmpty && _riderEndAddress.contains(',')
                        ? _riderEndAddress.substring(_riderEndAddress.indexOf(',') + 1).trim()
                        : (r.toAddress.contains(',')
                            ? r.toAddress.substring(r.toAddress.indexOf(',') + 1).trim()
                            : null),
                    time: 'Arrival',
                    icon: Icons.location_on,
                    iconColor: AppColors.red,
                    isLast: true,
                  ),
                const SizedBox(height: 24),
                _buildAdjustRadiusButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPayment() {
    final r = widget.ride;
    final rideData = {
      'fromAddress': r.fromAddress,
      'toAddress': r.toAddress,
      'date': Timestamp.fromDate(r.date),
      'time': {'hour': r.time.hour, 'minute': r.time.minute},
      'fare': {
        'farePerSeat': r.farePerSeat ?? 0.0,
      },
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          rideData: rideData,
          rideId: r.id,
        ),
      ),
    );
  }

  Widget _buildTransportDetailsHeader(BuildContext context) {
    return Row(
      children: [
        Text(
          'Transport details',
          style: GoogleFonts.mulish(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
            height: 1.0,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => _showSOSDialog(context),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFC82323).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFC82323),
              size: 16,
            ),
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () => LocationShareHelper.shareCurrentLocation(context),
          child: const Icon(Icons.share_outlined, size: 22, color: Color(0xFF1D1D1D)),
        ),
        const SizedBox(width: 16),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: const Icon(Icons.close, size: 22, color: Color(0xFF1D1D1D)),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  void _showSOSDialog(BuildContext pageContext) {
    showDialog(
      context: pageContext,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
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
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.red),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: AppColors.black54),
                    onPressed: () => Navigator.pop(dialogContext),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(left: 42, right: 12),
                child: Text(
                  'Are you sure you want send an Emergency SOS alert?',
                  style: TextStyle(fontSize: 13.5, color: AppColors.black54, fontWeight: FontWeight.w500, height: 1.1),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          side: BorderSide(color: AppColors.grey200),
                        ),
                        child: const Text('Cancel', style: TextStyle(color: AppColors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          if (!pageContext.mounted) return;
                          Navigator.push(
                            pageContext,
                            MaterialPageRoute(builder: (_) => const SecurityPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.black,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 0,
                        ),
                        child: const Text('Yes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
        const Icon(Icons.directions_walk, size: 24, color: Color(0xFF1D1D1D)),
        const SizedBox(width: 4),
        Text(
          '${(walkTo * 1000).round()} m',
          style: GoogleFonts.mulish(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1D1D1D),
            height: 1.0,
            letterSpacing: 0.01,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Icon(Icons.chevron_right, size: 16, color: Color(0xFFDDDDDD)),
        ),
        const Icon(Icons.directions_car, size: 24, color: Color(0xFF1D1D1D)),
        if (walkFrom > 0.001) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(Icons.chevron_right, size: 16, color: Color(0xFFDDDDDD)),
          ),
          const Icon(Icons.directions_walk, size: 24, color: Color(0xFF1D1D1D)),
          const SizedBox(width: 4),
          Text(
            walkFrom >= 1.0
                ? '${walkFrom.toStringAsFixed(1)} km'
                : '${(walkFrom * 1000).round()} m',
            style: GoogleFonts.mulish(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1D1D1D),
              height: 1.0,
              letterSpacing: 0.01,
            ),
          ),
        ],
        const Spacer(),
        Text(
          '${totalJourneyMin} min*',
          style: GoogleFonts.mulish(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
            height: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceAndArrival(RideMatch r, String timeRangeLabel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${timeRangeLabel.toUpperCase()}*',
          style: GoogleFonts.mulish(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1D1D1D),
            height: 20 / 16,
            letterSpacing: 0.01,
          ),
        ),
        Text(
          '₹ ${r.farePerSeat?.toInt() ?? 0} / seat',
          style: GoogleFonts.mulish(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1D1D1D),
            height: 20 / 16,
            letterSpacing: 0.01,
          ),
        ),
      ],
    );
  }

  Widget _buildPickupPointsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'PICKUP POINTS',
          style: GoogleFonts.mulish(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1D1D1D),
            height: 19.5 / 14,
            letterSpacing: 0.5,
          ),
        ),
        Row(
          children: [
            Text(
              '${_pinnedLatLng != null ? 1 : 0} pinned',
              style: GoogleFonts.mulish(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1D1D1D),
                height: 16.5 / 14,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF1F1F1F)),
          ],
        ),
      ],
    );
  }

  Widget _buildAdjustRadiusButton() {
    return SizedBox(
      width: double.infinity,
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: AppColors.grey400,
          dashWidth: 5,
          dashSpace: 3,
          borderRadius: 30,
        ),
        child: TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RouteMatchingPage()),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/maps_pointer.png', width: 18, height: 18),
              const SizedBox(width: 8),
              Text(
                'Adjust Radius',
                style: GoogleFonts.mulish(
                  color: const Color(0xFF1D1D1D),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  height: 24 / 14,
                ),
              ),
            ],
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
        ),
      ),
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
                    Text(
                      title,
                      style: GoogleFonts.mulish(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 18 / 16,
                      ),
                    ),
                    Text(
                      time,
                      style: GoogleFonts.mulish(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.mulish(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                    height: 18 / 14,
                  ),
                ),
                if (description != null && description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      description,
                      style: GoogleFonts.mulish(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                        height: 18 / 14,
                      ),
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
          const Icon(Icons.directions_walk, size: 18, color: Color(0xFF4C515B)),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.mulish(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.black,
              height: 18 / 14,
            ),
          ),
        ],
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1,
    this.dashWidth = 3,
    this.dashSpace = 3,
    this.borderRadius = 30,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final double halfStroke = strokeWidth / 2;
    final RRect rrect = RRect.fromLTRBR(
      halfStroke,
      halfStroke,
      size.width - halfStroke,
      size.height - halfStroke,
      Radius.circular(borderRadius),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashedPath = Path();

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        dashedPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
