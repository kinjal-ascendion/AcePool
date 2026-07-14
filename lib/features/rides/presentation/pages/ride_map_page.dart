import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:acepool/features/home/domain/entities/upcoming_trip.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class PickupPoint {
  final String location;
  final String sub;
  final String time;
  final LatLng position;
  bool isPinned;
  final bool isFirst;
  final bool isLast;
  final Color iconColor;

  PickupPoint({
    required this.location,
    required this.sub,
    required this.time,
    required this.position,
    this.isPinned = false,
    this.isFirst = false,
    this.isLast = false,
    required this.iconColor,
  });
}

class RideMapPage extends StatefulWidget {
  final UpcomingTrip trip;
  final List<PickupPoint>? pickupPoints;

  const RideMapPage({super.key, required this.trip, this.pickupPoints});

  @override
  State<RideMapPage> createState() => _RideMapPageState();
}

class _RideMapPageState extends State<RideMapPage> {
  late GoogleMapController _controller;
  late List<PickupPoint> _pickupPoints;
  BitmapDescriptor? _startIcon;
  BitmapDescriptor? _destinationIcon;
  BitmapDescriptor? _pickupIcon;

  // Coordinates will be taken from widget data
  LatLng get _source => _pickupPoints.first.position;
  LatLng get _destination => _pickupPoints.last.position;

  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    if (widget.pickupPoints != null) {
      _pickupPoints = widget.pickupPoints!;
    } else {
      _pickupPoints = [
        PickupPoint(
          location: widget.trip.fromAddress.split(',').first,
          sub: 'Pick Up Location 1',
          time: widget.trip.timeLabel,
          position: LatLng(widget.trip.fromLat ?? 0, widget.trip.fromLng ?? 0),
          isPinned: false,
          isFirst: true,
          iconColor: const Color(0xFF00A19A),
        ),
        if (widget.trip.toLat != null && widget.trip.toLng != null)
          PickupPoint(
            location: widget.trip.toAddress.split(',').first,
            sub: 'Destination',
            time: '10:30',
            position: LatLng(widget.trip.toLat!, widget.trip.toLng!),
            isLast: true,
            iconColor: Colors.red.shade400,
          ),
      ];
      
      // If we only have one point (e.g. toLat is null), add a default destination
      if (_pickupPoints.length < 2) {
         _pickupPoints.add(
          PickupPoint(
            location: widget.trip.toAddress.split(',').first,
            sub: 'Destination',
            time: '10:30',
            position: const LatLng(0, 0),
            isLast: true,
            iconColor: Colors.red.shade400,
          ),
        );
      }
    }
    
    _loadCustomIcons().then((_) => _updateMapElements());
  }

  Future<void> _loadCustomIcons() async {
    final Uint8List startBytes = await _getBytesFromAsset('assets/images/map_start_pointer.png', 50);
    final Uint8List destBytes = await _getBytesFromAsset('assets/images/map_destination.png', 50);
    final Uint8List pickupBytes = await _getBytesFromAsset('assets/images/maps_pointer.png', 50);

    _startIcon = BitmapDescriptor.fromBytes(startBytes);
    _destinationIcon = BitmapDescriptor.fromBytes(destBytes);
    _pickupIcon = BitmapDescriptor.fromBytes(pickupBytes);
  }

  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  Future<void> _fetchRoute() async {
    final validPoints = _pickupPoints.where((p) => p.position.latitude != 0 || p.position.longitude != 0).toList();
    if (validPoints.length < 2) return;

    final displayedPoints = validPoints;
    final coordinates = displayedPoints
        .map((p) => '${p.position.longitude},${p.position.latitude}')
        .join(';');

    try {
      final url = Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/$coordinates?overview=full&geometries=geojson');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {
          final geometry = data['routes'][0]['geometry']['coordinates'] as List;
          final routePoints = geometry
              .map((coord) => LatLng((coord[1] as num).toDouble(), (coord[0] as num).toDouble()))
              .toList();

          // Add start and end points manually to close the gap to markers
          // caused by OSRM snapping to the nearest road
          if (routePoints.isNotEmpty) {
            routePoints.insert(0, displayedPoints.first.position);
            routePoints.add(displayedPoints.last.position);
          }

          setState(() {
            _polylines.clear();
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('route'),
                points: routePoints,
                color: const Color(0xFF00A19A),
                width: 6,
              ),
            );
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching route: $e');
    }
  }

  void _updateMapElements() {
    _polylines.clear();
    _markers.clear();

    final displayedPoints = _pickupPoints;

    // Initial straight line polyline while route is fetching
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: displayedPoints.map((p) => p.position).toList(),
        color: const Color(0xFF00A19A),
        width: 5,
      ),
    );

    for (int i = 0; i < displayedPoints.length; i++) {
      final p = displayedPoints[i];
      if (p.position.latitude == 0 && p.position.longitude == 0) continue;

      BitmapDescriptor icon = BitmapDescriptor.defaultMarker;
      
      if (p.isFirst) {
        icon = _startIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
      } else if (p.isLast) {
        icon = BitmapDescriptor.defaultMarker;
      } else {
        icon = _pickupIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      }

      _markers.add(
        Marker(
          markerId: MarkerId('point_$i'),
          position: p.position,
          icon: icon,
          anchor: p.isFirst || p.isLast ? const Offset(0.5, 0.8) : const Offset(0.5, 0.5),
          infoWindow: InfoWindow(title: p.location, snippet: p.sub),
        ),
      );
    }
    setState(() {});
    _fetchRoute();
  }

  void _fitBounds() {
    if (_pickupPoints.isEmpty) return;

    double? minLat, maxLat, minLng, maxLng;
    int pointsUsed = 0;
    for (final p in _pickupPoints) {
      // Ignore invalid coordinates (0,0) to prevent zooming out to the whole world
      if (p.position.latitude == 0 && p.position.longitude == 0) continue;
      
      pointsUsed++;
      if (minLat == null || p.position.latitude < minLat) minLat = p.position.latitude;
      if (maxLat == null || p.position.latitude > maxLat) maxLat = p.position.latitude;
      if (minLng == null || p.position.longitude < minLng) minLng = p.position.longitude;
      if (maxLng == null || p.position.longitude > maxLng) maxLng = p.position.longitude;
    }

    if (pointsUsed == 0) return;

    _controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat!, minLng!),
          northeast: LatLng(maxLat!, maxLng!),
        ),
        100,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: (widget.trip.fromLat != null && widget.trip.fromLng != null && widget.trip.fromLat != 0)
                    ? LatLng(widget.trip.fromLat!, widget.trip.fromLng!)
                    : (_pickupPoints.isNotEmpty && _pickupPoints.first.position.latitude != 0 ? _pickupPoints.first.position : const LatLng(17.3850, 78.4867)),
                zoom: 13,
              ),
              onMapCreated: (controller) {
                _controller = controller;
                _fitBounds();
              },
              polylines: _polylines,
              markers: _markers,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              myLocationButtonEnabled: false,
            ),
          ),

          // Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Image.asset(
                'assets/images/back.png',
                width: 30,
                height: 30,
                errorBuilder: (context, error, stackTrace) => const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.arrow_back, color: Colors.black),
                ),
              ),
            ),
          ),

          // Top Details Card
          Positioned(
            top: MediaQuery.of(context).padding.top + 45,
            left: 25,
            right: 25,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/mapsstartdest.png',
                        height: 60,
                        errorBuilder: (context, error, stackTrace) => Column(
                          children: [
                            const Icon(Icons.radio_button_unchecked,
                                color: Color(0xFF00A19A), size: 18),
                            Container(
                                width: 1.5,
                                height: 22,
                                color: const Color(0xFFDDDDDD)),
                            const Icon(Icons.location_on,
                                color: Color(0xFF00A19A), size: 18),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.trip.fromAddress,
                                    style: const TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.map_outlined,
                                    color: Colors.grey, size: 18),
                              ],
                            ),
                            const Divider(height: 20, color: Color(0xFFEEEEEE)),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.trip.toAddress,
                                    style: const TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.map_outlined,
                                    color: Colors.grey, size: 18),
                              ],
                            ),
                            const SizedBox(height: 4),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  const Divider(height: 24, color: Color(0xFFEEEEEE)),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 16, color: Colors.black87),
                      const SizedBox(width: 12),
                      Text(
                        widget.trip.dateLabel,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: Color(0xFFEEEEEE)),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 16, color: Colors.black87),
                      const SizedBox(width: 12),
                      Text(
                        widget.trip.timeLabel,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const Spacer(),
                      SizedBox(
                        height: 20,
                        child: VerticalDivider(
                            width: 16,
                            thickness: 1,
                            color: const Color(0xFFEEEEEE)),
                      ),
                      const Icon(Icons.person_outline,
                          size: 18, color: Colors.black87),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.trip.seatsFilled}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: DraggableScrollableSheet(
              initialChildSize: 0.35,
              minChildSize: 0.08,
              maxChildSize: 0.65,
              snap: true,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    children: [
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade600,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.arrow_back, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Transport details',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          const Icon(Icons.share_outlined, size: 20),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.close, size: 20),
                          ),
                        ],
                      ),
                      const Divider(height: 32, color: Color(0xFFEEEEEE)),
                      Row(
                        children: [
                          ...List.generate(widget.trip.seatsFilled,
                              (index) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    size: 22),
                                Text(
                                  index == 0
                                      ? ' ₁'
                                      : index == 1
                                          ? ' ₂'
                                          : index == 2
                                              ? ' ₃'
                                              : ' ${index + 1}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                                if (index < widget.trip.seatsFilled - 1)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 4.0),
                                    child: Icon(Icons.chevron_right,
                                        size: 18),
                                  ),
                              ],
                            );
                          }),
                          const Spacer(),
                          const Text(
                            '45 min*',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${widget.trip.timeLabel} - 10.15 AM*',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500),
                          ),
                          Text(
                            widget.trip.farePerSeat != null
                                ? '₹${widget.trip.farePerSeat!.toStringAsFixed(2)} / seat'
                                : 'Fare not set',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '*Actual arrival time may vary due to traffic and road conditions',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const Divider(height: 32, color: Color(0xFFEEEEEE)),
                      Row(
                        children: [
                          Text(
                            'Add a Note',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey.shade600),
                          ),
                          const Spacer(),
                          const Icon(Icons.edit_outlined, size: 18),
                        ],
                      ),
                      const Divider(height: 32, color: Color(0xFFEEEEEE)),
                      Row(
                        children: [
                          const Text(
                            'PICKUP POINTS',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                          const Spacer(),
                          Text(
                            '${_pickupPoints.where((p) => p.isPinned).length} pinned',
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                          const Icon(Icons.keyboard_arrow_down,
                              color: Colors.black),
                        ],
                      ),
                      const Divider(height: 32, color: Color(0xFFEEEEEE)),
                      // Starting point card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.near_me_outlined,
                                size: 20, color: Colors.black87),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Starting point auto-detected',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    'Using your current location: ${widget.trip.fromAddress.split(',')[0]}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Orange tip card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lightbulb_outline,
                                size: 18, color: Color(0xFFF97316)),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Pin stops along the route so riders can choose to board at these locations.',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFF97316)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Pickup Points List
                      ..._pickupPoints.asMap().entries.map((entry) {
                        int idx = entry.key;
                        PickupPoint p = entry.value;
                        return _buildPickupStep(
                          location: p.location,
                          sub: p.sub,
                          time: p.time,
                          isPinned: p.isPinned,
                          isFirst: p.isFirst,
                          isLast: p.isLast,
                          iconColor: p.iconColor,
                          onPinToggle: () {
                            setState(() {
                              p.isPinned = !p.isPinned;
                              _updateMapElements();
                            });
                          },
                        );
                      }),
                      const SizedBox(height: 32),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupStep({
    required String location,
    required String sub,
    required String time,
    bool isPinned = false,
    bool isFirst = false,
    bool isLast = false,
    required Color iconColor,
    VoidCallback? onPinToggle,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                if (isFirst)
                  const Icon(Icons.location_on,
                      color: Color(0xFF00A19A), size: 20)
                else if (isLast)
                  Image.asset('assets/images/map_destination.png',
                      width: 20, height: 20, errorBuilder: (c, e, s) => Icon(Icons.location_on, color: Colors.red.shade400, size: 20))
                else
                  Image.asset('assets/images/maps_pointer.png',
                      width: 14, height: 14, errorBuilder: (c, e, s) => Icon(Icons.circle, color: Colors.grey, size: 12)),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: const Color(0xFFEEEEEE),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(time,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black87)),
                    const SizedBox(width: 12),
                    if (!isLast)
                      GestureDetector(
                        onTap: onPinToggle,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPinned
                                ? const Color(0xFFE3F2FD)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isPinned
                                  ? const Color(0xFF2196F3)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: isPinned
                                    ? const Color(0xFF2196F3)
                                    : Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isPinned ? 'Pinned' : 'Pin',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isPinned
                                      ? const Color(0xFF2196F3)
                                      : Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  sub,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                if (!isLast) const Divider(height: 1, color: Color(0xFFEEEEEE)),
                if (!isLast) const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
