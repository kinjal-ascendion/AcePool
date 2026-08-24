import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

/// Avatar circle diameter (40px design token, bumped slightly per feedback).
const double _avatarDiameter = 44;

/// Local design tokens for the ride review summary card. Kept here (not in
/// AppColors) until these values are confirmed against the design system.
class _ReviewCardColors {
  _ReviewCardColors._();

  static const Color ink = Color(0xFF1A1A1A);
  static const Color bodyGray = Color(0xFF8A8A8A);
  static const Color borderGray = Color(0xFFEDEDED);
  static const Color badgeOrange = Color(0xFFF5A623);

  /// rgba(0, 0, 0, 0.03) — subtle card shadow.
  static const Color cardShadow = Color(0x08000000);

  /// Fallback avatar palette (no photo) — warm accent reserved for +N badge.
  static const List<Color> avatarPalette = [
    Color(0xFF4A7DDB),
    Color(0xFF34A853),
    Color(0xFF9C6ADE),
    Color(0xFF00A8A8),
    Color(0xFFE0609B),
    Color(0xFF7B8A2F),
  ];
}

/// Compact summary card for a completed offered ride: overlapping passenger
/// avatar stack (photo or colored-initial circle, "+N" badge when there are
/// more passengers than slots), passenger names + count + combined date/time
/// line, and a trailing chevron. The whole card is tappable.
class RideReviewCard extends StatelessWidget {
  /// Passenger full names, in request order (same order as [riderPhotoUrls]).
  final List<String> riderNames;

  /// Passenger avatar URLs (null/empty = no photo → colored initial circle).
  final List<String?> riderPhotoUrls;

  /// Total passenger count shown as "{N} passengers".
  final int passengerCount;

  /// Pre-formatted "{date} . {time}" subtitle line (e.g. "Today . 9.30 am").
  final String dateTimeText;

  /// Optional vehicle info (e.g. "Honda City . KA 01 AB 2026").
  final String? vehicleInfo;

  final VoidCallback onTap;

  const RideReviewCard({
    super.key,
    required this.riderNames,
    required this.riderPhotoUrls,
    required this.passengerCount,
    required this.dateTimeText,
    this.vehicleInfo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x7ABBBEC5)), // Mixed solid #BBBEC57A
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                _AvatarStack(
                  riderNames: riderNames,
                  riderPhotoUrls: riderPhotoUrls,
                  passengerCount: passengerCount,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _namesText(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.mulish(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF000000),
                          height: 18 / 16,
                        ),
                      ),
                      if (vehicleInfo != null && vehicleInfo!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          vehicleInfo!,
                          style: GoogleFonts.mulish(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF757474),
                            height: 18 / 16,
                          ),
                        ),
                      ],
                      if (passengerCount > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          "$passengerCount passenger${passengerCount == 1 ? '' : 's'}",
                          style: GoogleFonts.mulish(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF757474),
                            height: 18 / 16,
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        dateTimeText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.mulish(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF757474),
                          height: 18 / 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Image.asset(
                  'assets/images/next.png',
                  width: 9,
                  height: 18,
                  color: const Color(0xFF000000),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Comma-separated first names (first word of each full name).
  String _namesText() {
    final firstNames = riderNames
        .map((n) => n.trim().split(' ').first.trim())
        .where((n) => n.isNotEmpty)
        .toList();
    return firstNames.isEmpty ? 'Riders' : firstNames.join(', ');
  }
}

/// Horizontally overlapping 40px circles: up to 2 passenger photos (or
/// colored-initial fallbacks); when there are more passengers than slots the
/// last circle is an orange "+N" badge.
class _AvatarStack extends StatelessWidget {
  final List<String> riderNames;
  final List<String?> riderPhotoUrls;
  final int passengerCount;

  const _AvatarStack({
    required this.riderNames,
    required this.riderPhotoUrls,
    required this.passengerCount,
  });

  static const double _overlap = 14;

  @override
  Widget build(BuildContext context) {
    // First circle is always a passenger; second is a photo only when there
    // are exactly 2 passengers (3+ → "+N" badge instead).
    final showSecondPhoto = passengerCount == 2;
    final children = <Widget>[
      Positioned(
        left: 0,
        child: _avatarCircle(index: 0),
      ),
    ];
    if (showSecondPhoto) {
      children.add(
        Positioned(
          left: _avatarDiameter - _overlap,
          child: _avatarCircle(index: 1),
        ),
      );
    } else if (passengerCount >= 3) {
      children.add(
        Positioned(
          left: _avatarDiameter - _overlap,
          child: _moreBadge(count: passengerCount - 1),
        ),
      );
    }

    final isStack = showSecondPhoto || passengerCount >= 3;
    final double stackWidth = isStack ? 76 : _avatarDiameter;

    return SizedBox(
      width: stackWidth,
      height: _avatarDiameter,
      child: Stack(
        clipBehavior: Clip.none,
        children: children,
      ),
    );
  }

  Widget _avatarCircle({required int index}) {
    final name = index < riderNames.length ? riderNames[index] : '';
    final photo =
        index < riderPhotoUrls.length ? riderPhotoUrls[index] : null;
    return _Circle(
      child: (photo != null && photo.isNotEmpty)
          ? ClipOval(
              child: Image.network(
                photo,
                width: _avatarDiameter,
                height: _avatarDiameter,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _InitialCircle(name: name),
              ),
            )
          : _InitialCircle(name: name),
    );
  }

  Widget _moreBadge({required int count}) {
    return _Circle(
      color: _ReviewCardColors.badgeOrange,
      child: Text(
        "+$count",
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// 40px circle with a 2px white ring (keeps overlapping edges crisp).
class _Circle extends StatelessWidget {
  final Color? color;
  final Widget child;

  const _Circle({this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _avatarDiameter,
      height: _avatarDiameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color ?? Colors.white,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipOval(child: child),
    );
  }
}

/// Colored circle with the passenger's initial (first letter of first name),
/// like the avatars used elsewhere in the app.
class _InitialCircle extends StatelessWidget {
  final String name;

  const _InitialCircle({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty
        ? name.trim().split(' ').first[0].toUpperCase()
        : 'R';
    final color = _ReviewCardColors.avatarPalette[
        name.codeUnits.fold<int>(0, (a, b) => a + b) %
            _ReviewCardColors.avatarPalette.length];
    return Container(
      color: color,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
