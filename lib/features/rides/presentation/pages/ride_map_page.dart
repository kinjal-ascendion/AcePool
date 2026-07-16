import 'dart:convert';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:acepool/features/home/domain/entities/upcoming_trip.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PickupPoint {
  final String location;
  final String sub;
  final String time;
  final LatLng position;
  final LatLng? dropOffPosition;
  bool isPinned;
  final bool isFirst;
  final bool isLast;
  final Color iconColor;

  PickupPoint({
    required this.location,
    required this.sub,
    required this.time,
    required this.position,
    this.dropOffPosition,
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
  int? _selectedPickupIndex;
  List<LatLng> _fullRoutePoints = [];
  List<LatLng> _selectedRoutePoints = [];
  String? _tripNote;
  bool _isDriver = false;
  final TextEditingController _noteController = TextEditingController();
  StreamSubscription<DocumentSnapshot>? _tripSubscription;

  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'acepool',
  );

  BitmapDescriptor? _selectedPickupIcon;

  // Coordinates will be taken from widget data
  LatLng get _source => _pickupPoints.first.position;
  LatLng get _destination => _pickupPoints.last.position;

  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _tripNote = widget.trip.note;
    _noteController.text = _tripNote ?? '';
    _checkIfDriver();
    _listenToTripChanges();
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
    
    _loadCustomIcons().then((_) {
      _updateMapElements();
      _fetchRoute();
    });
  }

  Future<void> _loadCustomIcons() async {
    final Uint8List startBytes = await _getBytesFromAsset('assets/images/map_start_pointer.png', 50);
    final Uint8List destBytes = await _getBytesFromAsset('assets/images/map_destination.png', 50);
    final Uint8List pickupBytes = await _getBytesFromAsset('assets/images/maps_pointer.png', 50);
    final Uint8List selectedPickupBytes = await _createCircularMarker(Colors.blue, 35);

    _startIcon = BitmapDescriptor.fromBytes(startBytes);
    _destinationIcon = BitmapDescriptor.fromBytes(destBytes);
    _pickupIcon = BitmapDescriptor.fromBytes(pickupBytes);
    _selectedPickupIcon = BitmapDescriptor.fromBytes(selectedPickupBytes);
  }

  Future<Uint8List> _createCircularMarker(Color color, int radius) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final double size = radius * 2.0;

    // Draw shadow
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(radius.toDouble(), radius.toDouble() + 1), radius.toDouble() - 2, shadowPaint);

    // Draw outer white circle
    final Paint whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(radius.toDouble(), radius.toDouble()), radius.toDouble() - 2, whitePaint);

    // Draw inner colored circle
    final Paint paint = Paint()..color = color;
    canvas.drawCircle(Offset(radius.toDouble(), radius.toDouble()), radius.toDouble() - 5, paint);

    final ui.Image image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _tripSubscription?.cancel();
    super.dispose();
  }

  void _listenToTripChanges() {
    _tripSubscription = _db
        .collection('rides')
        .doc(widget.trip.id)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _tripNote = data['note'] as String?;
            if (_noteController.text != (_tripNote ?? '')) {
              _noteController.text = _tripNote ?? '';
            }
          });
        }
      }
    });
  }

  void _checkIfDriver() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    // In a real app, you might check if widget.trip.driverId == uid
    // For now, let's check if the trip's UID field matches current UID
    // We need to fetch the trip document to see who the driver is.
    try {
      final doc = await _db.collection('rides').doc(widget.trip.id).get();
      if (doc.exists) {
        setState(() {
          _isDriver = doc.data()?['uid'] == uid;
        });
      }
    } catch (e) {
      debugPrint('Error checking driver status: $e');
    }
  }

  Future<void> _showNoteDialog() async {
    if (!_isDriver) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add a Note'),
        content: TextField(
          controller: _noteController,
          decoration: const InputDecoration(
            hintText: 'Enter a message for your riders...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newNote = _noteController.text.trim();
              try {
                await _db.collection('rides').doc(widget.trip.id).update({
                  'note': newNote,
                });
                setState(() {
                  _tripNote = newNote;
                });
                if (mounted) Navigator.pop(context);
              } catch (e) {
                debugPrint('Error saving note: $e');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchRoute() async {
    final validPoints = _pickupPoints
        .where((p) => p.position.latitude != 0 || p.position.longitude != 0)
        .toList();
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
        if (data['code'] == 'Ok' &&
            data['routes'] != null &&
            data['routes'].isNotEmpty) {
          final geometry = data['routes'][0]['geometry']['coordinates'] as List;
          final routePoints = geometry
              .map((coord) => LatLng(
                  (coord[1] as num).toDouble(), (coord[0] as num).toDouble()))
              .toList();

          // Add start and end points manually to close the gap to markers
          // caused by OSRM snapping to the nearest road
          if (routePoints.isNotEmpty) {
            routePoints.insert(0, displayedPoints.first.position);
            routePoints.add(displayedPoints.last.position);
          }

          _fullRoutePoints = routePoints;
          _updateMapElements();
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

    // Base Route (Green)
    if (_fullRoutePoints.isNotEmpty) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: _fullRoutePoints,
          color: const Color(0xFF00A19A),
          width: 6,
        ),
      );
    }

    // Highlighted Segment (Black)
    if (_selectedRoutePoints.isNotEmpty) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('selected_route'),
          points: _selectedRoutePoints,
          color: Colors.black,
          width: 6,
          zIndex: 1,
        ),
      );
    } else if (_fullRoutePoints.isEmpty) {
      // Fallback straight line polyline while route is fetching
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: displayedPoints.map((p) => p.position).toList(),
          color: const Color(0xFF00A19A),
          width: 5,
        ),
      );
    }

    for (int i = 0; i < displayedPoints.length; i++) {
      final p = displayedPoints[i];
      if (p.position.latitude == 0 && p.position.longitude == 0) continue;

      BitmapDescriptor icon = BitmapDescriptor.defaultMarker;

      if (p.isFirst) {
        icon = _startIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
      } else if (p.isLast) {
        // Use default red marker to ensure it's a "filled marker" as shown in the image
        icon = BitmapDescriptor.defaultMarker;
      } else {
        icon = _pickupIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      }

      // Highlight selected pickup with rounded blue icon
      // But only if it's NOT the first or last marker (start/destination)
      if (_selectedPickupIndex == i && !p.isFirst && !p.isLast) {
        icon = _selectedPickupIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      }

      _markers.add(
        Marker(
          markerId: MarkerId('point_$i'),
          position: p.position,
          icon: icon,
          anchor: (_selectedPickupIndex == i && !p.isFirst && !p.isLast)
              ? const Offset(0.5, 0.5)
              : (p.isFirst || p.isLast)
                  ? const Offset(0.5, 0.8)
                  : const Offset(0.5, 0.5),
          infoWindow: InfoWindow(title: p.location, snippet: p.sub),
        ),
      );
    }

    // Add a blue marker for dropoff if it's specific and not already in the list
    if (_selectedPickupIndex != null && 
        !_pickupPoints[_selectedPickupIndex!].isFirst && 
        !_pickupPoints[_selectedPickupIndex!].isLast) {
      final p = _pickupPoints[_selectedPickupIndex!];
      if (p.dropOffPosition != null) {
        // Check if a marker already exists at this position to avoid overlap
        bool exists = displayedPoints.any((dp) =>
            dp.position.latitude == p.dropOffPosition!.latitude &&
            dp.position.longitude == p.dropOffPosition!.longitude);

        if (!exists) {
          _markers.add(
            Marker(
              markerId: const MarkerId('selected_dropoff'),
              position: p.dropOffPosition!,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue),
              anchor: const Offset(0.5, 0.8),
              infoWindow: const InfoWindow(title: 'Drop-off'),
            ),
          );
        }
      }
    }
    setState(() {});
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

  Future<void> _fetchSegmentRoute(LatLng start, LatLng end) async {
    try {
      final url = Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok' &&
            data['routes'] != null &&
            data['routes'].isNotEmpty) {
          final geometry = data['routes'][0]['geometry']['coordinates'] as List;
          final routePoints = geometry
              .map((coord) => LatLng(
                  (coord[1] as num).toDouble(), (coord[0] as num).toDouble()))
              .toList();
          
          // Add start and end points manually to close the gap to markers
          if (routePoints.isNotEmpty) {
            routePoints.insert(0, start);
            routePoints.add(end);
          }
          
          setState(() {
            _selectedRoutePoints = routePoints;
            _updateMapElements();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching segment route: $e');
    }
  }

  void _onPickupTapped(int index) {
    if (_selectedPickupIndex == index) {
      // Toggle off: if clicking the same one again, clear the black line
      setState(() {
        _selectedPickupIndex = null;
        _selectedRoutePoints = [];
        _updateMapElements();
      });
      return;
    }

    setState(() {
      _selectedPickupIndex = index;
      _selectedRoutePoints = []; // Clear previous segment
    });

    final pickup = _pickupPoints[index];

    // If it's the start or the destination, we just show the full green route (no black line)
    if (pickup.isFirst || pickup.isLast) {
      _updateMapElements();
      return;
    }

    final dropOff = pickup.dropOffPosition;

    if (dropOff != null) {
      _fetchSegmentRoute(pickup.position, dropOff);
    } else {
      // Fallback: highlight from pickup to trip destination using existing full route
      final selectedPoint = pickup.position;
      int startIndex = 0;
      double minStartDist = double.infinity;

      for (int i = 0; i < _fullRoutePoints.length; i++) {
        final dist = _calculateDistance(selectedPoint, _fullRoutePoints[i]);
        if (dist < minStartDist) {
          minStartDist = dist;
          startIndex = i;
        }
      }
      
      setState(() {
        final subPoints = _fullRoutePoints.sublist(startIndex);
        if (subPoints.isNotEmpty) {
          _selectedRoutePoints = [selectedPoint, ...subPoints];
        } else {
          _selectedRoutePoints = subPoints;
        }
        _updateMapElements();
      });
    }
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    return (p1.latitude - p2.latitude) * (p1.latitude - p2.latitude) +
        (p1.longitude - p2.longitude) * (p1.longitude - p2.longitude);
  }

  String _formatDuration(int? minutes) {
    if (minutes == null || minutes <= 0) return '45 min';
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  String _getArrivalTime(TimeOfDay startTime, int? durationMinutes) {
    if (durationMinutes == null || durationMinutes <= 0) {
      // Fallback if no duration: assume 15 mins for the screenshot style "10.15 AM"
      durationMinutes = 15; 
    }
    
    final now = DateTime.now();
    final startDateTime = DateTime(now.year, now.month, now.day, startTime.hour, startTime.minute);
    final endDateTime = startDateTime.add(Duration(minutes: durationMinutes));
    
    final hour = endDateTime.hour > 12 ? endDateTime.hour - 12 : (endDateTime.hour == 0 ? 12 : endDateTime.hour);
    final minute = endDateTime.minute.toString().padLeft(2, '0');
    final period = endDateTime.hour >= 12 ? 'PM' : 'AM';
    
    return '$hour.$minute $period';
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
                          Text(
                            '${_formatDuration(widget.trip.durationMinutes)}*',
                            style: const TextStyle(
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
                            '${widget.trip.timeLabel} - ${_getArrivalTime(widget.trip.time, widget.trip.durationMinutes)}*',
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
                      if (_isDriver || (_tripNote != null && _tripNote!.isNotEmpty)) ...[
                        const Divider(height: 32, color: Color(0xFFEEEEEE)),
                        GestureDetector(
                          onTap: _isDriver ? _showNoteDialog : null,
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _tripNote == null || _tripNote!.isEmpty
                                          ? 'Add a Note'
                                          : 'Driver\'s Note',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                          fontWeight: _tripNote != null &&
                                                  _tripNote!.isNotEmpty
                                              ? FontWeight.bold
                                              : FontWeight.normal),
                                    ),
                                    if (_tripNote != null &&
                                        _tripNote!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          _tripNote!,
                                          style: const TextStyle(
                                              fontSize: 14, color: Colors.black),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (_isDriver)
                                const Icon(Icons.edit_outlined, size: 18),
                            ],
                          ),
                        ),
                      ],
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
                          isSelected: _selectedPickupIndex == idx,
                          onTap: () => _onPickupTapped(idx),
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
    VoidCallback? onTap,
    bool isSelected = false,
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
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
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
        ),
      ],
    ),
  );
}
}
