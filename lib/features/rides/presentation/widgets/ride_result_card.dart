import 'package:acepool/core/theme/app_colors.dart';
import 'package:acepool/features/rides/domain/entities/ride_match.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RideResultCard extends StatefulWidget {
  const RideResultCard({
    super.key,
    required this.result,
    required this.riderFromAddress,
    required this.riderTime,
    required this.db,
    required this.onRequested,
  });

  final RideMatch result;
  final String riderFromAddress;
  final TimeOfDay riderTime;
  final FirebaseFirestore db;
  final VoidCallback onRequested;

  @override
  State<RideResultCard> createState() => _RideResultCardState();
}

class _RideResultCardState extends State<RideResultCard> {

  final _messageController = TextEditingController();
  bool _submitting = false;
  bool _justRequested = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _requestRide() async {
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

      final pickupPoint = widget.riderFromAddress;

      final requestRef = widget.db.collection('ride_requests').doc();
      final rideRef = widget.db.collection('rides').doc(widget.result.id);
      final batch = widget.db.batch();
      batch.set(requestRef, {
        'rideId': widget.result.id,
        'riderId': uid,
        'riderName': riderName,
        'riderPhotoUrl': riderPhotoUrl,
        'pickupPoint': pickupPoint,
        'pickupTime': {
          'hour': widget.riderTime.hour,
          'minute': widget.riderTime.minute,
        },
        'message': _messageController.text.trim(),
        'status': 'accepted',
        'createdAt': FieldValue.serverTimestamp(),
        'rideFrom': widget.result.fromAddress,
        'rideTo': widget.result.toAddress,
        'rideDate': Timestamp.fromDate(widget.result.date),
        'rideTime': {
          'hour': widget.result.time.hour,
          'minute': widget.result.time.minute,
        },
        'driverId': widget.result.driverId,
        'driverName': widget.result.driverName,
      });
      batch.update(rideRef, {'seatsFilled': FieldValue.increment(1)});
      await batch.commit();

      if (mounted) {
        setState(() {
          _justRequested = true;
          _submitting = false;
        });
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
          // ── Top banner + match% overlay (pinned to extreme corners) ──
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
                Positioned(
                  top: 8,
                  right: 8,
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
                              size: 14, color: AppColors.grey600),
                          const SizedBox(width: 4),
                          Text(
                            r.distanceLabel ??
                                (r.vehicleType == 'bike' ? 'Bike' : 'Car'),
                            style: TextStyle(
                              fontSize: 12.5,
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
                            size: 16,
                            color: AppColors.grey700,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

            const SizedBox(height: 2),

            // ── Row 4: time ─────────────────────────────────────────
            Text(
              r.timeLabel,
              style: const TextStyle(color: AppColors.black45, fontSize: 12),
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
                    style: const TextStyle(fontSize: 13, color: AppColors.black54),
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
                    style: const TextStyle(fontSize: 13, color: AppColors.black54),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Divider(color: AppColors.grey200, height: 1),
            const SizedBox(height: 8),

            // ── Price + View Details ──────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '₹ 600 / seat',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'View Details',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.black54,
                    decoration: TextDecoration.underline,
                  ),
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
                      enabled: !requested && !_submitting,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: requested
                            ? 'Request sent'
                            : 'Share message with driver',
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
                    onTap: requested || _submitting ? null : _requestRide,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: requested ? AppColors.grey400 : AppColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.white),
                            )
                          : Icon(
                              requested ? Icons.check : Icons.send_rounded,
                              color: AppColors.white,
                              size: 16,
                            ),
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
