import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class _CardColors {
  _CardColors._();

  static const Color ink = Color(0xFF1A1A1A);
  static const Color bodyGray = Color(0xFF8A8A8A);
  static const Color labelGray = Color(0xFF4A4A4A);
  static const Color divider = Color(0xFFEDEDED);
  static const Color fieldBorder = Color(0xFFC4C4C4);
  static const Color placeholder = Color(0xFF9A9A9A);
  static const Color brandGreen = Color(0xFF1E8E5A);
  static const Color emojiBg = Color(0xFFF0F0F0);
  static const Color chipBorder = Color(0xFFC4C4C4);
  static const Color shadow = Color(0x0A000000);
  static const List<Color> avatarPalette = [
    Color(0xFF4A7DDB),
    Color(0xFF34A853),
    Color(0xFF9C6ADE),
    Color(0xFF00A8A8),
    Color(0xFFE0609B),
    Color(0xFF7B8A2F),
  ];
}

const List<String> _defaultReviewTags = [
  'On time',
  'Polite',
  'Easy to find',
  'Good company',
];

const List<String> _driverReviewTags = [
  'On time',
  'Safe driver',
  'Clean car',
  'Friendly',
];

const List<String> _sentimentEmojis = ['😠', '😞', '😐', '🙂', '😍'];

class PassengerReviewCard extends StatefulWidget {
  final String riderName;
  final String employeeId;
  final String? riderPhotoUrl;
  final String pickupPoint;
  final String dropOffPoint;
  final int? selectedEmoji;
  final Set<String> selectedTags;
  final String comment;
  final String? vehicleInfo;
  final bool isRated;
  final bool isSubmitting;
  final bool isDriverReview;
  final ValueChanged<int> onEmojiSelected;
  final ValueChanged<String> onTagToggled;
  final ValueChanged<String> onCommentChanged;
  final VoidCallback onSubmit;

  const PassengerReviewCard({
    super.key,
    required this.riderName,
    required this.employeeId,
    required this.riderPhotoUrl,
    required this.pickupPoint,
    required this.dropOffPoint,
    required this.selectedEmoji,
    required this.selectedTags,
    required this.comment,
    this.vehicleInfo,
    required this.isRated,
    required this.isSubmitting,
    this.isDriverReview = false,
    required this.onEmojiSelected,
    required this.onTagToggled,
    required this.onCommentChanged,
    required this.onSubmit,
  });

  @override
  State<PassengerReviewCard> createState() => _PassengerReviewCardState();
}

class _PassengerReviewCardState extends State<PassengerReviewCard> {
  late final TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController(text: widget.comment);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = widget.selectedEmoji != null &&
        !widget.isRated &&
        !widget.isSubmitting;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x7ABBBEC5)),
        boxShadow: const [
          BoxShadow(
            color: _CardColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(name: widget.riderName, photoUrl: widget.riderPhotoUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.riderName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.mulish(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E1E1E),
                        height: 18 / 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (widget.vehicleInfo != null && widget.vehicleInfo!.isNotEmpty) ...[
                      Text(
                        widget.vehicleInfo!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.mulish(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF757474),
                          height: 18 / 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      widget.employeeId,
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
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _RouteMarkers(
            pickupPoint: widget.pickupPoint,
            dropOffPoint: widget.dropOffPoint,
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: Color(0xFFDDDDDD)),
          const SizedBox(height: 16),
          _SentimentPicker(
            selectedEmoji: widget.selectedEmoji,
            enabled: !widget.isRated,
            onSelected: widget.onEmojiSelected,
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, thickness: 1, color: Color(0xFFDDDDDD)),
          const SizedBox(height: 16),
          Text(
            'What went well?',
            style: GoogleFonts.mulish(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF1E1E1E),
              height: 19.5 / 16,
            ),
          ),
          const SizedBox(height: 12),
          _TagChips(
            tags: widget.isDriverReview ? _driverReviewTags : _defaultReviewTags,
            selectedTags: widget.selectedTags,
            onToggled: widget.onTagToggled,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            onChanged: widget.onCommentChanged,
            minLines: 3,
            maxLines: 6,
            style: GoogleFonts.mulish(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF1D1D1D),
              height: 21 / 16,
            ),
            decoration: InputDecoration(
              hintText: 'Add a comment (optional)...',
              hintStyle: GoogleFonts.mulish(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: const Color(0x801D1D1D),
                height: 21 / 16,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 1),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: canSubmit ? widget.onSubmit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1E1E),
                foregroundColor: const Color(0xFFFDFDFD),
                disabledBackgroundColor: const Color(0xFF1E1E1E).withOpacity(0.12),
                disabledForegroundColor: const Color(0xFFFDFDFD).withOpacity(0.38),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: GoogleFonts.mulish(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 20 / 16,
                ),
              ),
              child: const Text('Submit Feedback'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? photoUrl;

  const _Avatar({required this.name, required this.photoUrl});

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

class _RouteMarkers extends StatelessWidget {
  final String pickupPoint;
  final String dropOffPoint;

  const _RouteMarkers({required this.pickupPoint, required this.dropOffPoint});

  String _shortPickup() {
    final parts = pickupPoint
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return pickupPoint;
    return parts.first;
  }

  String _shortDrop() {
    final parts = dropOffPoint
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return dropOffPoint;
    return parts.take(2).join(', ');
  }

  static const double _textHeight = 16.8;
  static const double _circleSize = 8;
  static const double _circleOffset = (_textHeight - _circleSize) / 2;
  static const double _lineHeight = _textHeight;
  static const double _textGap = 8;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: _circleOffset),
              child: _outlineCircle(),
            ),
            const SizedBox(
              height: _lineHeight,
              width: _circleSize,
              child: CustomPaint(painter: _DottedLinePainter()),
            ),
            Padding(
              padding: EdgeInsets.only(top: _circleOffset),
              child: _filledCircle(),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _placeText(_shortPickup()),
              const SizedBox(height: _textGap),
              _placeText(_shortDrop()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _placeText(String label) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.mulish(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF757474),
        height: 18 / 16,
      ),
    );
  }

  Widget _outlineCircle() {
    return Container(
      width: _circleSize,
      height: _circleSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _CardColors.brandGreen, width: 1.5),
      ),
    );
  }

  Widget _filledCircle() {
    return Container(
      width: _circleSize,
      height: _circleSize,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: _CardColors.brandGreen,
      ),
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

class _SentimentPicker extends StatelessWidget {
  final int? selectedEmoji;
  final bool enabled;
  final ValueChanged<int> onSelected;

  const _SentimentPicker({
    required this.selectedEmoji,
    required this.enabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'How was your experience?',
              textAlign: TextAlign.center,
              style: GoogleFonts.mulish(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF757474),
                height: 19.5 / 16,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_sentimentEmojis.length, (index) {
                final rating = index + 1;
                final isSelected = selectedEmoji == rating;
                return GestureDetector(
                  onTap: enabled ? () => onSelected(rating) : null,
                  child: AnimatedScale(
                    scale: isSelected ? 1.4 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: isSelected
                          ? const BoxDecoration(
                              shape: BoxShape.circle,
                              color: _CardColors.emojiBg,
                            )
                          : null,
                      child: Text(
                        _sentimentEmojis[index],
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChips extends StatelessWidget {
  final List<String> tags;
  final Set<String> selectedTags;
  final ValueChanged<String> onToggled;

  const _TagChips({required this.tags, required this.selectedTags, required this.onToggled});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tag in tags)
          GestureDetector(
            onTap: () => onToggled(tag),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selectedTags.contains(tag)
                    ? const Color(0xFF1E1E1E)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFDDDDDD),
                  width: 0.73,
                ),
              ),
              child: Text(
                tag,
                style: GoogleFonts.mulish(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: selectedTags.contains(tag)
                      ? Colors.white
                      : const Color(0xFF1E1E1E),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
