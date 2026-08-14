import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/core/utils/location_share_helper.dart';
import 'package:acepool/di/injection.dart';
import 'package:acepool/features/chat/domain/entities/chat_message.dart';
import 'package:acepool/features/chat/domain/repositories/chat_repository.dart';
import 'package:acepool/features/rides/domain/entities/ride_match.dart';
import 'package:acepool/features/rides/domain/repositories/rides_repository.dart';
import 'package:acepool/features/rides/presentation/pages/ride_details_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RideResultCard extends StatefulWidget {
  const RideResultCard({
    super.key,
    required this.result,
    required this.riderFromAddress,
    this.riderFromLat,
    this.riderFromLng,
    required this.riderToAddress,
    this.riderToLat,
    this.riderToLng,
    required this.riderTime,
    required this.onRequested,
    this.onFindDriver,
  });

  final RideMatch result;
  final String riderFromAddress;
  final double? riderFromLat;
  final double? riderFromLng;
  final String riderToAddress;
  final double? riderToLat;
  final double? riderToLng;
  final TimeOfDay riderTime;
  final VoidCallback onRequested;
  final VoidCallback? onFindDriver;

  @override
  State<RideResultCard> createState() => _RideResultCardState();
}

class _RideResultCardState extends State<RideResultCard> {

  final _messageController = TextEditingController();
  final _priceController = TextEditingController();
  bool _submitting = false;
  bool _justRequested = false;
  bool _negotiating = false;
  bool _offerSent = false;
  bool _offerDeclined = false;
  String _offeredPrice = '';

  @override
  void initState() {
    super.initState();
    if (widget.result.negotiatedPrice != null) {
      _offeredPrice = widget.result.negotiatedPrice!.toInt().toString();
      if (widget.result.negotiationStatus == 'declined') {
        _offerDeclined = true;
      } else {
        _offerSent = true;
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _requestRide() async {
    setState(() => _submitting = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final riderName = await sl<RidesRepository>().requestRide(
        ride: widget.result,
        riderFromAddress: widget.riderFromAddress,
        riderFromLat: widget.riderFromLat,
        riderFromLng: widget.riderFromLng,
        riderToAddress: widget.riderToAddress,
        riderToLat: widget.riderToLat,
        riderToLng: widget.riderToLng,
        riderTime: widget.riderTime,
        message: _messageController.text.trim(),
        negotiatedPrice: _offerSent ? double.tryParse(_offeredPrice) : null,
      );

      // Also send a chat message if there's a message entered
      final messageText = _messageController.text.trim();
      if (messageText.isNotEmpty) {
        final ids = [uid, widget.result.driverId]..sort();
        final chatId = ids.join('_');
        
        await sl<ChatRepository>().sendMessage(
          chatId,
          ChatMessage(
            id: '',
            senderId: uid,
            receiverId: widget.result.driverId,
            text: messageText,
            timestamp: DateTime.now(),
          ),
          riderName,
          widget.result.driverName,
        );
      }

      if (mounted) {
        setState(() {
          _justRequested = true;
          _submitting = false;
        });
        _messageController.clear();
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
    final r = widget.result;
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
            // ── Top row: seats-filled chip pinned to corner + match% ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: 8),
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

                  // ── Row 4: time + vehicle pill ───────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        r.timeLabel,
                        style: const TextStyle(
                            color: AppColors.black45, fontSize: 12),
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
                  const SizedBox(height: 8),

                  // ── Driver info ─────────────────────────────────────────
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.grey200,
                        backgroundImage: (r.driverPhotoUrl?.isNotEmpty ?? false)
                            ? NetworkImage(r.driverPhotoUrl!)
                            : null,
                        child: (r.driverPhotoUrl?.isNotEmpty ?? false)
                            ? null
                            : Icon(Icons.person, color: AppColors.grey400),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.driverName.isNotEmpty ? r.driverName : 'Driver',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
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
                        child: Icon(Icons.phone_outlined, size: 18, color: AppColors.grey600),
                      ),
                      const SizedBox(width: 2),
                      Text('|', style: TextStyle(color: AppColors.grey400, fontSize: 16)),
                      const SizedBox(width: 2),
                      GestureDetector(
                        onTap: () {},
                        child: Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.grey600),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // ── Route ───────────────────────────────────────────────
                  Row(
                    children: [
                      _routeDot(filled: false),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          r.fromAddress,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.black54),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                      _routeDot(filled: true),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          r.toAddress,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.black54),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  Divider(color: AppColors.grey200, height: 1),
                  const SizedBox(height: 8),

                  // ── Price + Negotiate ──────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        r.farePerSeat != null
                            ? '₹${r.farePerSeat!.toStringAsFixed(2)} / seat'
                            : 'Fare not set',
                        style: TextStyle(
                          color: const Color(0xFF308666),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: _offerSent ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (_offerDeclined)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC82323).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFC82323).withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            '₹ $_offeredPrice - Declined',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFC82323),
                            ),
                          ),
                        )
                      else if (_offerSent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF046B4B).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF046B4B).withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            'Offer : ₹ $_offeredPrice',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF046B4B),
                            ),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _negotiating = !_negotiating;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDDDDDD).withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFDDDDDD)),
                            ),
                            child: Text(
                              _negotiating ? 'Cancel' : 'Negotiate',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E1E1E),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  if (_offerDeclined) ...[
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFFC82323), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Driver declined your offer. Try a higher offer or find another driver.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: const Color(0xFFC82323),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onFindDriver,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFDDDDDD)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Find Driver',
                              style: TextStyle(color: Color(0xFF1E1E1E), fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _offerDeclined = false;
                                _negotiating = true;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Revise Offer',
                              style: TextStyle(color: Color(0xFFFEFEFE), fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else if (_offerSent) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Offer Sent - waiting for driver to respond',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                  ] else if (_negotiating) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'What would you like to offer ?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.grey200),
                      ),
                      child: TextField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 16, color: Color(0xFF1E1E1E)),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Enter your price',
                          hintStyle: const TextStyle(fontSize: 16, color: Color(0xFF616874), fontWeight: FontWeight.normal),
                          border: InputBorder.none,
                          prefixIcon: const Icon(Icons.currency_rupee, size: 16, color: Color(0xFF1E1E1E)),
                          prefixIconConstraints: const BoxConstraints(minWidth: 24),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _offerSent = true;
                          _offeredPrice = _priceController.text;
                          _negotiating = false;
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.scheduleButtonColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Send Offer - ₹ ${_priceController.text.isEmpty ? '0' : _priceController.text}/seat',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFFEFEFE),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.black12),
                  const SizedBox(height: 12),

                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.currency_rupee, size: 16, color: Color(0xFF1E1E1E)),
                          const SizedBox(width: 4),
                          const Text('UPI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E1E1E))),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.payments_outlined, size: 16, color: Color(0xFF1E1E1E)),
                          const SizedBox(width: 4),
                          const Text('Cash', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E1E1E))),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── Message + send button ─────────────────────────────────
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
                            enabled: !_submitting,
                            style: const TextStyle(fontSize: 13),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Share message with driver',
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
                          onTap: _submitting ? null : _requestRide,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: (requested && _messageController.text.trim().isEmpty)
                                  ? AppColors.grey400
                                  : AppColors.primaryGreen,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: AppColors.white),
                                  )
                                : Text(
                                    (requested && _messageController.text.trim().isNotEmpty) ? 'Send' : (requested ? 'Requested' : 'Request ride'),
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RideDetailsPage(
                              ride: r,
                              riderFromAddress: widget.riderFromAddress,
                              riderFromLat: widget.riderFromLat,
                              riderFromLng: widget.riderFromLng,
                              riderToAddress: widget.riderToAddress,
                              riderToLat: widget.riderToLat,
                              riderToLng: widget.riderToLng,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'View Ride Details',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF616874),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }

  Widget _routeDot({required bool filled}) {
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
