import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/core/utils/location_share_helper.dart';
import 'package:acepool/core/utils/ride_matcher.dart';
import 'package:acepool/di/injection.dart';
import 'package:acepool/features/home/presentation/widgets/home_bottom_nav_bar.dart';
import 'package:acepool/features/rides/domain/entities/ride_match.dart';
import 'package:acepool/features/rides/domain/entities/ride_rider.dart';
import 'package:acepool/features/rides/presentation/bloc/ride_details_bloc.dart';
import 'package:acepool/features/rides/presentation/pages/track_route_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RideDetailsPage extends StatefulWidget {
  const RideDetailsPage({
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
  State<RideDetailsPage> createState() => _RideDetailsPageState();
}

class _RideDetailsPageState extends State<RideDetailsPage> {
  final _messageController = TextEditingController();
  late final RideDetailsBloc _bloc;
  int _lastClearTick = 0;

  @override
  void initState() {
    super.initState();
    _bloc = sl<RideDetailsBloc>()
      ..add(RideDetailsStarted(
        ride: widget.ride,
        riderFromAddress: widget.riderFromAddress,
        riderFromLat: widget.riderFromLat,
        riderFromLng: widget.riderFromLng,
        riderToAddress: widget.riderToAddress,
        riderToLat: widget.riderToLat,
        riderToLng: widget.riderToLng,
      ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _bloc.close();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<RideDetailsBloc, RideDetailsState>(
        listener: (context, state) {
          if (state.clearMessageTextTick != _lastClearTick) {
            _lastClearTick = state.clearMessageTextTick;
            _messageController.clear();
          }
          if (state.snackbarMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.snackbarMessage!)),
            );
          }
        },
        builder: (context, state) {
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
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRideMainCard(r, state),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'OTHER RIDERS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF666666),
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
                              fontSize: 12,
                              color: AppColors.black54,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (state.ridersStatus == RideDetailsRidersStatus.initial ||
                      state.ridersStatus == RideDetailsRidersStatus.loading)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(),
                    ))
                  else if (state.ridersStatus == RideDetailsRidersStatus.error)
                    Center(child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text('Error loading riders: ${state.ridersError}', style: const TextStyle(color: AppColors.red)),
                    ))
                  else if (state.riders.isEmpty)
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
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.riders.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.black12),
                        itemBuilder: (context, index) => _RiderItem(rider: state.riders[index]),
                      ),
                    ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            extendBody: true,
            bottomNavigationBar: HomeBottomNavBar(
              currentIndex: 1,
              onTap: (index) {
                // Typically handles jumping back to shell and changing tabs.
                // For now just pops if Home or Profile is clicked to keep user flow.
                if (index != 1) Navigator.of(context).pop();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildRideMainCard(RideMatch r, RideDetailsState state) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: Row(
                  children: [
                    Text(
                      '${r.matchPercent}% Match',
                      style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.more_vert, size: 20, color: Color(0xFF666666)),
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
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Row(
                      children: [
                        Icon(Icons.directions_walk, size: 14, color: AppColors.grey600),
                        const SizedBox(width: 4),
                        Text(
                          r.distanceLabel ?? '500 m',
                          style: TextStyle(fontSize: 11, color: AppColors.grey600, fontWeight: FontWeight.w500),
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
                      style: const TextStyle(color: Color(0xFF1E1E1E), fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.grey300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            r.vehicleType == 'bike'
                                ? Icons.two_wheeler
                                : Icons.directions_car,
                            size: 14,
                            color: AppColors.black87,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            r.vehicleType == 'bike' ? 'Bike' : 'Car',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
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
                            r.driverName.isNotEmpty ? r.driverName : 'Driver',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          Text(
                            'Verified ID',
                            style: TextStyle(color: AppColors.grey500, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: (r.driverPhone?.isNotEmpty ?? false)
                          ? () => LocationShareHelper.launchDialer(r.driverPhone!)
                          : null,
                      child: Icon(Icons.phone_outlined, size: 19, color: AppColors.grey700),
                    ),
                    const SizedBox(width: 2),
                    Text('|', style: TextStyle(color: AppColors.grey400, fontSize: 20)),
                    const SizedBox(width: 2),
                    GestureDetector(
                      onTap: () {},
                      child: Icon(Icons.chat_bubble_outline, size: 19, color: AppColors.grey700),
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
                        fontSize: 14,
                      ),
                    ),
                    // View Details is hidden for now as per request
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
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
                            hintStyle: TextStyle(color: AppColors.grey400, fontSize: 13),
                            isDense: true,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _bloc.add(RideDetailsSubmitted(_messageController.text)),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                          child: state.submitting
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
                style: const TextStyle(fontSize: 13, color: Color(0xFF4C515B), fontWeight: FontWeight.w500),
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
                style: const TextStyle(fontSize: 13, color: Color(0xFF4C515B), fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RiderItem extends StatelessWidget {
  const _RiderItem({required this.rider});
  final RideRider rider;

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
                  Text('${RideMatcher.formatDuration(25)} >', style: TextStyle(fontSize: 11, color: AppColors.grey600, fontWeight: FontWeight.w500)),
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
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.black),
              ),
              Expanded(
                child: Text(
                  rider.pickupPoint,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF444444)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.map_outlined, size: 14, color: AppColors.black26),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Text(
                'Time: ',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.black),
              ),
              Text(
                rider.pickupTimeLabel,
                style: const TextStyle(fontSize: 12, color: Color(0xFF444444)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
