import 'package:acepool/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'ratings_by_riders_page.dart';
import 'ratings_by_you_page.dart';
import 'package:acepool/core/enums/ride_mode.dart';
import 'review_your_riders_page.dart';
import 'ratings_by_drivers_page.dart';

class RideStatisticsPage extends StatefulWidget {
  final RideMode mode;
  final String? travelPreference;

  const RideStatisticsPage({
    super.key,
    required this.mode,
    this.travelPreference,
  });
  @override
  State<RideStatisticsPage> createState() => _RideStatisticsPageState();
}

class _RideStatisticsPageState extends State<RideStatisticsPage> {
  late RideMode _currentMode;

  @override
  void initState() {
    super.initState();
    if (widget.travelPreference == 'ride') {
      _currentMode = RideMode.takeRide;
    } else if (widget.travelPreference == 'drive') {
      _currentMode = RideMode.offerRide;
    } else {
      _currentMode = widget.mode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String pref = widget.travelPreference?.toString().toLowerCase().trim() ?? '';
    // Show toggle ONLY if preference is 'both'
    final bool showToggle = pref == 'both';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Ride statistics",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          if (showToggle) ...[
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 240,
                height: 40,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _ToggleItem(
                        label: 'Find ride',
                        isSelected: _currentMode == RideMode.takeRide,
                        onTap: () => setState(() => _currentMode = RideMode.takeRide),
                      ),
                    ),
                    Expanded(
                      child: _ToggleItem(
                        label: 'Offer ride',
                        isSelected: _currentMode == RideMode.offerRide,
                        onTap: () => setState(() => _currentMode = RideMode.offerRide),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  if (_currentMode == RideMode.takeRide) ...[
                    _menuTile(
                      title: "Ratings by You",
                      subtitle: "Ratings given by you to your drivers",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RatingsByYouPage(),
                          ),
                        );
                      },
                    ),
                    Divider(color: AppColors.grey200),
                    _menuTile(
                      title: "Ratings by Drivers",
                      subtitle: "Ratings given by drivers to you",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RatingsByDriversPage(),
                          ),
                        );
                      },
                    ),
                  ],
                  if (_currentMode == RideMode.offerRide) ...[
                    _menuTile(
                      title: "Ratings by You",
                      subtitle: "Ratings given by you to your riders",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReviewYourRidersPage(),
                          ),
                        );
                      },
                    ),
                    Divider(color: AppColors.grey200),
                    _menuTile(
                      title: "Ratings by Riders",
                      subtitle: "Ratings given by riders to you",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RatingsByRidersPage(),
                          ),
                        );
                      },
                    ),
                  ],
                  Divider(color: AppColors.grey200),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuTile({
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: AppColors.grey600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.toggleActiveBlack : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.black87,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
