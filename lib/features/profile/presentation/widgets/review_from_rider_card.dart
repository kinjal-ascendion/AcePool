import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

const List<String> _sentimentEmojis = ['😠', '😞', '😐', '🙂', '😍'];

class _CardColors {
  _CardColors._();

  static const Color ink = Color(0xFF1A1A1A);
  static const Color bodyGray = Color(0xFF8A8A8A);
  static const Color dateGray = Color(0xFF6A6A6A);
  static const Color borderGray = Color(0xFFEDEDED);
  static const Color chipBorder = Color(0xFFD8D8D8);
  static const Color brandGreen = Color(0xFF1E8E5A);
  static const Color shadow = Color(0x08000000);
  static const List<Color> avatarPalette = [
    Color(0xFF4A7DDB),
    Color(0xFF34A853),
    Color(0xFF9C6ADE),
    Color(0xFF00A8A8),
    Color(0xFFE0609B),
    Color(0xFF7B8A2F),
  ];
}

class ReviewFromRiderCard extends StatelessWidget {
  final String riderName;
  final String? riderPhotoUrl;
  final String? riderEmployeeId;
  final int? sentiment;
  final String pickup;
  final String drop;
  final DateTime date;
  final TimeOfDay time;
  final List<String> tags;
  final String? comment;
  final String? vehicleInfo;

  const ReviewFromRiderCard({
    super.key,
    required this.riderName,
    this.riderPhotoUrl,
    this.riderEmployeeId,
    this.sentiment,
    required this.pickup,
    required this.drop,
    required this.date,
    required this.time,
    this.tags = const [],
    this.comment,
    this.vehicleInfo,
  });

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'am' : 'pm';
    return '$hour.$minute $period';
  }

  String _emojiForSentiment(int? s) {
    if (s == null || s < 1 || s > 5) return '';
    return _sentimentEmojis[s - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x7ABBBEC5)), // Mixed solid #BBBEC57A
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopRow(
            riderName: riderName,
            riderPhotoUrl: riderPhotoUrl,
            riderEmployeeId: riderEmployeeId,
            emoji: _emojiForSentiment(sentiment),
            vehicleInfo: vehicleInfo,
          ),
          const SizedBox(height: 14),
          _RouteSection(pickup: pickup, drop: drop),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: Color(0xFFDDDDDD)),
          const SizedBox(height: 12),
          Text(
            '${_formatDate(date)} . ${_formatTime(time)}',
            style: GoogleFonts.mulish(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF757474),
              height: 18 / 16,
            ),
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1, color: Color(0xFFDDDDDD)),
            const SizedBox(height: 12),
            _TagsRow(tags: tags),
          ],
          if (comment != null && comment!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              comment!,
              style: GoogleFonts.mulish(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF757474),
                height: 19.5 / 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  final String riderName;
  final String? riderPhotoUrl;
  final String? riderEmployeeId;
  final String emoji;
  final String? vehicleInfo;

  const _TopRow({
    required this.riderName,
    this.riderPhotoUrl,
    this.riderEmployeeId,
    required this.emoji,
    this.vehicleInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Avatar(name: riderName, photoUrl: riderPhotoUrl),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                riderName.isNotEmpty ? riderName : 'Rider',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.mulish(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1D1D1D),
                  height: 18 / 14,
                ),
              ),
              if (vehicleInfo != null && vehicleInfo!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  vehicleInfo!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.mulish(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF757474),
                    height: 18 / 12,
                  ),
                ),
              ],
              if (riderEmployeeId != null && riderEmployeeId!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  riderEmployeeId!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.mulish(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF757474),
                    height: 18 / 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (emoji.isNotEmpty)
          Text(
            emoji,
            style: const TextStyle(fontSize: 26),
          ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? photoUrl;

  const _Avatar({required this.name, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final photo = photoUrl;
    if (photo == null || photo.isEmpty) {
      return _InitialAvatar(name: name);
    }
    return ClipOval(
      child: Image.network(
        photo,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _InitialAvatar(name: name),
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  final String name;

  const _InitialAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    final color = _CardColors.avatarPalette[
        name.codeUnits.fold<int>(0, (a, b) => a + b) %
            _CardColors.avatarPalette.length];
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _RouteSection extends StatelessWidget {
  final String pickup;
  final String drop;

  const _RouteSection({required this.pickup, required this.drop});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF1E8E5A), width: 1.5),
              ),
            ),
            SizedBox(
              height: 20,
              width: 8,
              child: CustomPaint(painter: _DottedLinePainter()),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF1E8E5A),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pickup,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.mulish(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF757474),
                  height: 18 / 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                drop,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.mulish(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF757474),
                  height: 18 / 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  const _DottedLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _CardColors.brandGreen
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    const dashLength = 3.0;
    const gapLength = 2.5;
    final centerX = size.width / 2;
    var y = 0.0;
    while (y < size.height) {
      final endY = y + dashLength > size.height ? size.height : y + dashLength;
      canvas.drawLine(Offset(centerX, y), Offset(centerX, endY), paint);
      y += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TagsRow extends StatelessWidget {
  final List<String> tags;

  const _TagsRow({required this.tags});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD8D8D8), width: 1),
          ),
          child: Text(
            tag,
            style: GoogleFonts.mulish(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1E1E1E),
              height: 1.3,
            ),
          ),
        );
      }).toList(),
    );
  }
}
