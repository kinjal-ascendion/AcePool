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
import 'package:google_fonts/google_fonts.dart';

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
          // ── Top banner + match% overlay ──
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
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.person_outline,
                            color: Colors.white,
                            size: 15,
                          ),
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
                        style: GoogleFonts.mulish(
                          color: AppColors.primaryGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 18 / 14,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.more_vert,
                        size: 18,
                        color: Color(0xFF757474),
                      ),
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
                      style: GoogleFonts.mulish(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        height: 18 / 16,
                        color: const Color(0xFF1E1E1E),
                      ),
                    ),
                    const Spacer(),
                    Transform.translate(
                      offset: const Offset(0, -2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.directions_walk,
                            size: 12,
                            color: Color(0xFF757474),
                          ),
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
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.chevron_right,
                            size: 14,
                            color: Color(0xFFDDDDDD),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.directions_car,
                            size: 14,
                            color: Color(0xFF757474),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Row: time + vehicle pill ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      r.timeLabel,
                      style: GoogleFonts.mulish(
                        color: const Color(0xFF1E1E1E),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 18 / 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
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
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                const Divider(height: 1, color: Color(0xFFDDDDDD)),
                const SizedBox(height: 8),

                // Driver info
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
                      child: const Icon(
                        Icons.phone_outlined,
                        size: 18,
                        color: Color(0xFF757474),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '|',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 16,
                      ),
                    ),
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

                const SizedBox(height: 12),

                Row(
                  children: [
                    _routeDot(filled: false),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        r.fromAddress,
                        style: GoogleFonts.mulish(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 18 / 16,
                          color: const Color(0xFF4C515B),
                        ),
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
                        color: const Color(0xFFDDDDDD),
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
                        style: GoogleFonts.mulish(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 18 / 16,
                          color: const Color(0xFF4C515B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(color: Color(0xFFDDDDDD), height: 1),
                const SizedBox(height: 12),

                // ── Price + Negotiate ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      r.effectiveFare != null
                          ? '₹${r.effectiveFare!.toStringAsFixed(2)} / seat'
                          : 'Fare not set',
                      style: GoogleFonts.mulish(
                        color: const Color(0xFF1B8A3F),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 18 / 16,
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
                          style: GoogleFonts.mulish(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 16.5 / 12,
                            color: const Color(0xFFC82323),
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
                          style: GoogleFonts.mulish(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 16.5 / 12,
                            color: const Color(0xFF046B4B),
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
                            style: GoogleFonts.mulish(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 16.5 / 12,
                              color: const Color(0xFF1E1E1E),
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
                          style: GoogleFonts.mulish(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 20 / 14,
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
                            backgroundColor: const Color(0xFF1E1E1E),
                          ),
                          child: Text(
                            'Find Driver',
                            style: GoogleFonts.mulish(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 1.0,
                            ),
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
                            backgroundColor: const Color(0xFFFEFEFE),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFFDDDDDD)),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Revise Offer',
                            style: GoogleFonts.mulish(
                              color: const Color(0xFF1E1E1E),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (_offerSent && widget.result.negotiationStatus != 'accepted') ...[
                  const SizedBox(height: 12),
                  Text(
                    'Offer Sent - waiting for driver to respond',
                    style: GoogleFonts.mulish(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 18 / 16,
                      color: const Color(0xFF1E1E1E),
                    ),
                  ),
                ] else if (_negotiating) ...[
                  const SizedBox(height: 16),
                  Text(
                    'What would you like to offer ?',
                    style: GoogleFonts.mulish(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 18 / 16,
                      color: const Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDDDDD).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDDDDDD)),
                    ),
                    child: TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.mulish(fontSize: 16, color: const Color(0xFF1E1E1E)),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Enter your price',
                        hintStyle: TextStyle(fontSize: 16, color: Color(0xFF616874), fontWeight: FontWeight.normal),
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.currency_rupee, size: 16, color: Color(0xFF1E1E1E)),
                        prefixIconConstraints: BoxConstraints(minWidth: 24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final price = double.tryParse(_priceController.text);
                      if (price == null) return;

                      if (widget.result.requestId != null) {
                        setState(() => _submitting = true);
                        try {
                          await sl<RidesRepository>().updateNegotiatedPrice(
                            requestId: widget.result.requestId!,
                            price: price,
                          );
                          if (mounted) {
                            setState(() {
                              _offerSent = true;
                              _offeredPrice = _priceController.text;
                              _negotiating = false;
                              _submitting = false;
                            });
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() => _submitting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to update offer: $e')),
                            );
                          }
                        }
                      } else {
                        setState(() {
                          _offerSent = true;
                          _offeredPrice = _priceController.text;
                          _negotiating = false;
                        });
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _submitting ? const Color(0xFF757474) : const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _submitting
                          ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              'Send Offer - ₹ ${_priceController.text.isEmpty ? '0' : _priceController.text}/seat',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.mulish(
                                color: const Color(0xFFFEFEFE),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                height: 1.0,
                              ),
                            ),
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFDDDDDD)),
                const SizedBox(height: 12),

                Text(
                  'Payment Method',
                  style: GoogleFonts.mulish(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 18 / 16,
                    color: const Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined, size: 20, color: Color(0xFF1E1E1E)),
                        const SizedBox(width: 6),
                        Text(
                          'UPI',
                          style: GoogleFonts.mulish(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                            color: const Color(0xFF1E1E1E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.payments_outlined, size: 20, color: Color(0xFF1E1E1E)),
                        const SizedBox(width: 4),
                        Text(
                          'Cash',
                          style: GoogleFonts.mulish(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                            color: const Color(0xFF1E1E1E),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Message + send button ──
                Container(
                  padding: const EdgeInsets.only(
                      left: 16, right: 4, top: 4, bottom: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F1F2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          enabled: !_submitting,
                          style: GoogleFonts.mulish(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            height: 18 / 16,
                            color: const Color(0xFF616874),
                          ),
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'Share message with driver',
                            hintStyle: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF616874),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 6),
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
                                ? const Color(0xFFDDDDDD)
                                : const Color(0xFF1B8A3F),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  (requested && _messageController.text.trim().isNotEmpty) ? 'Send' : (requested ? 'Requested' : 'Request ride'),
                                  style: GoogleFonts.mulish(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    height: 18 / 14,
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
                      style: GoogleFonts.mulish(
                        fontSize: 14,
                        color: const Color(0xFF616874),
                        fontWeight: FontWeight.w400,
                        height: 18 / 14,
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
