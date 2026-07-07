import 'package:acepool/features/home/domain/entities/upcoming_trip.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RideMapPage extends StatefulWidget {
  final UpcomingTrip trip;

  const RideMapPage({super.key, required this.trip});

  @override
  State<RideMapPage> createState() => _RideMapPageState();
}

class _RideMapPageState extends State<RideMapPage> {
  late GoogleMapController _controller;

  // Mock coordinates for Singasandra and Koramangala
  static const LatLng _kSource = LatLng(12.8797, 77.6534); // Singasandra area
  static const LatLng _kDestination = LatLng(12.9352, 77.6245); // Koramangala area

  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _polylines.add(
      const Polyline(
        polylineId: PolylineId('route'),
        points: [_kSource, _kDestination],
        color: Colors.blue,
        width: 5,
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
              initialCameraPosition: const CameraPosition(
                target: _kSource,
                zoom: 13,
              ),
              onMapCreated: (controller) {
                _controller = controller;
                print('Map Created successfully');
                // Adjust camera to show both points
                _controller.animateCamera(
                  CameraUpdate.newLatLngBounds(
                    LatLngBounds(
                      southwest: const LatLng(12.8797, 77.6245),
                      northeast: const LatLng(12.9352, 77.6534),
                    ),
                    100,
                  ),
                );
              },
              polylines: _polylines,
              markers: {
                const Marker(
                  markerId: MarkerId('source'),
                  position: _kSource,
                ),
                const Marker(
                  markerId: MarkerId('destination'),
                  position: _kDestination,
                ),
              },
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              myLocationButtonEnabled: false,
            ),
          ),

          // Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Top Details Card
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.radio_button_unchecked,
                          color: Colors.teal, size: 18),
                      const SizedBox(width: 12),
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
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 1,
                        height: 20,
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.teal, size: 18),
                      const SizedBox(width: 12),
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
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 16, color: Colors.black54),
                      const SizedBox(width: 8),
                      Text(
                        widget.trip.dateLabel,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 16, color: Colors.black54),
                      const SizedBox(width: 8),
                      Text(
                        widget.trip.timeLabel,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const Spacer(),
                      const Icon(Icons.person_outline,
                          size: 16, color: Colors.black54),
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Transport details',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.share_outlined, size: 20),
                          const SizedBox(width: 16),
                          const Icon(Icons.close, size: 20),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18),
                      const Text(' ₁', style: TextStyle(fontSize: 10)),
                      const Icon(Icons.chevron_right, size: 16),
                      const Icon(Icons.location_on_outlined, size: 18),
                      const Text(' ₂', style: TextStyle(fontSize: 10)),
                      const Icon(Icons.chevron_right, size: 16),
                      const Icon(Icons.location_on_outlined, size: 18),
                      const Text(' ₃', style: TextStyle(fontSize: 10)),
                      const Spacer(),
                      const Text(
                        '45 min*',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${widget.trip.timeLabel} - 10.15 AM*',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const Text(
                        '₹ 600 / seat',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '*Actual arrival time may vary due to traffic and road conditions',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const Divider(height: 32),
                  Row(
                    children: [
                      const Text('Add a Note'),
                      const Spacer(),
                      const Icon(Icons.edit_outlined, size: 18),
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    children: [
                      const Text(
                        'PICKUP POINTS',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54),
                      ),
                      const Spacer(),
                      const Text(
                        '1 pinned',
                        style: TextStyle(fontSize: 12),
                      ),
                      const Icon(Icons.keyboard_arrow_down),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
