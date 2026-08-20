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
import 'package:google_fonts/google_fonts.dart';

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
              backgroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF1D1D1D)),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Ride Details',
                style: GoogleFonts.mulish(
                  color: const Color(0xFF1D1D1D),
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  height: 1.0,
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Stack(
                    children: [
                      const Icon(Icons.notifications_none_outlined, color: Color(0xFF1D1D1D), size: 28),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEA0000),
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
                        Text(
                          'OTHER RIDERS',
                          style: GoogleFonts.mulish(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF4C515B),
                            letterSpacing: 0.8,
                            height: 15 / 14,
                          ),
                        ),
                        TextButton(
                          onPressed: _openMap,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'View On Map',
                            style: GoogleFonts.mulish(
                              fontSize: 14,
                              color: const Color(0xFF757474),
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w400,
                              height: 18 / 14,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDDDDD)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
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
                  color: Color(0xFF1B8A3F),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_outline, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${r.seatsFilled}/${r.seatsTotal} seats filled',
                      style: GoogleFonts.mulish(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 18 / 14,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 0, right: 8),
                child: Row(
                  children: [
                    Text(
                      '${r.matchPercent}% Match',
                      style: GoogleFonts.mulish(
                        color: const Color(0xFF1B8A3F),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 18 / 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.more_vert, size: 18, color: Color(0xFF757474)),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      r.dateLabel,
                      style: GoogleFonts.mulish(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        height: 18 / 16,
                        color: const Color(0xFF1E1E1E),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.directions_walk, size: 12, color: Color(0xFF757474)),
                        const SizedBox(width: 4),
                        Text(
                          r.distanceLabel ?? '500 m',
                          style: GoogleFonts.mulish(
                            fontSize: 12,
                            color: const Color(0xFF757474),
                            fontWeight: FontWeight.w600,
                            height: 18 / 12,
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 14, color: Color(0xFFDDDDDD)),
                        const SizedBox(width: 4),
                        Image.asset(
                          'assets/images/location_pin.png',
                          width: 14,
                          height: 14,
                          color: const Color(0xFF757474),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      r.timeLabel,
                      style: GoogleFonts.mulish(
                        color: const Color(0xFF1E1E1E),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        height: 18 / 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFDDDDDD)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            r.vehicleType == 'bike'
                                ? Icons.two_wheeler
                                : Icons.directions_car,
                            size: 14,
                            color: const Color(0xFF1D1D1D),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            r.vehicleType == 'bike' ? 'Bike' : 'Car',
                            style: GoogleFonts.mulish(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF1D1D1D),
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, color: Color(0xFFDDDDDD)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFF0F1F2),
                      backgroundImage: (r.driverPhotoUrl?.isNotEmpty ?? false)
                          ? NetworkImage(r.driverPhotoUrl!)
                          : null,
                      child: (r.driverPhotoUrl?.isNotEmpty ?? false)
                          ? null
                          : const Icon(Icons.person, color: Color(0xFFB6B6B6)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.driverName.isNotEmpty ? r.driverName : 'Driver',
                            style: GoogleFonts.mulish(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              height: 18 / 16,
                              color: const Color(0xFF1D1D1D),
                            ),
                          ),
                          Text(
                            'Verified ID',
                            style: GoogleFonts.mulish(
                              color: const Color(0xFF757474),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 18 / 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: (r.driverPhone?.isNotEmpty ?? false)
                          ? () => LocationShareHelper.launchDialer(r.driverPhone!)
                          : null,
                      child: const Icon(Icons.phone_outlined, size: 18, color: Color(0xFF757474)),
                    ),
                    const SizedBox(width: 8),
                    Text('|', style: TextStyle(color: Colors.grey[300], fontSize: 16)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {},
                      child: Image.asset(
                        'assets/images/chat_square.png',
                        width: 18,
                        height: 18,
                        color: const Color(0xFF757474),
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.chat_bubble_outline,
                          size: 18,
                          color: Color(0xFF757474),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildRouteLine(r.fromAddress, r.toAddress),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFDDDDDD)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      r.effectiveFare != null
                          ? '₹${r.effectiveFare!.toStringAsFixed(2)} / seat'
                          : 'Fare not set',
                      style: GoogleFonts.mulish(
                        color: const Color(0xFF1B8A3F),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        height: 18 / 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F1F2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: GoogleFonts.mulish(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            height: 18 / 16,
                            color: const Color(0xFF616874),
                          ),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: r.alreadyRequested
                                ? 'Request Sent. Share a message'
                                : 'Share message with driver',
                            border: InputBorder.none,
                            hintStyle: GoogleFonts.mulish(
                              color: const Color(0xFF616874),
                              fontSize: 16,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 6),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _bloc.add(RideDetailsSubmitted(_messageController.text)),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (r.alreadyRequested && _messageController.text.trim().isEmpty)
                                ? Colors.transparent
                                : const Color(0xFF1B8A3F),
                            shape: BoxShape.circle,
                            border: (r.alreadyRequested && _messageController.text.trim().isEmpty)
                                ? Border.all(color: const Color(0xFF1B8A3F), width: 1.5)
                                : null,
                          ),
                          child: state.submitting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : (r.alreadyRequested && _messageController.text.trim().isEmpty)
                                ? const Icon(Icons.check, color: Color(0xFF1B8A3F), size: 18)
                                : const Icon(Icons.send, color: Colors.white, size: 18),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: rider.riderPhotoUrl != null
                    ? NetworkImage(rider.riderPhotoUrl!)
                    : null,
                backgroundColor: const Color(0xFFF0F1F2),
                child: rider.riderPhotoUrl == null ? const Icon(Icons.person, size: 18, color: Color(0xFFB6B6B6)) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rider.riderName,
                      style: GoogleFonts.mulish(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        height: 18 / 16,
                        color: const Color(0xFF1D1D1D),
                      ),
                    ),
                    Text(
                      rider.employeeId,
                      style: GoogleFonts.mulish(
                        color: const Color(0xFF757474),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 18 / 14,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.directions_walk, size: 12, color: Color(0xFF757474)),
                  const SizedBox(width: 4),
                  Text(
                    '500 m',
                    style: GoogleFonts.mulish(
                      fontSize: 12,
                      color: const Color(0xFF757474),
                      fontWeight: FontWeight.w600,
                      height: 18 / 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 14, color: Color(0xFFDDDDDD)),
                  const SizedBox(width: 4),
                  Image.asset(
                    'assets/images/location_pin.png',
                    width: 14,
                    height: 14,
                    color: const Color(0xFF757474),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              style: GoogleFonts.mulish(
                fontSize: 14,
                height: 18 / 14,
                color: const Color(0xFF1D1D1D),
              ),
              children: [
                TextSpan(
                  text: 'Pick up point: ',
                  style: GoogleFonts.mulish(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: rider.pickupPoint,
                  style: GoogleFonts.mulish(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              style: GoogleFonts.mulish(
                fontSize: 14,
                height: 18 / 14,
                color: const Color(0xFF1D1D1D),
              ),
              children: [
                TextSpan(
                  text: 'Time: ',
                  style: GoogleFonts.mulish(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: rider.pickupTimeLabel,
                  style: GoogleFonts.mulish(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
