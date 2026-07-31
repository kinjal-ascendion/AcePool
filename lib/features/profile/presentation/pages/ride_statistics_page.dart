import 'package:acepool/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'ratings_by_riders_page.dart';
import 'ratings_by_you_page.dart';
import 'package:acepool/core/enums/ride_mode.dart';
import 'review_your_riders_page.dart';
import 'ratings_by_drivers_page.dart';

class RideStatisticsPage extends StatefulWidget {
  final RideMode mode;

  const RideStatisticsPage({
    super.key,
    required this.mode,
  });
  @override
  State<RideStatisticsPage> createState() => _RideStatisticsPageState();
}

class _RideStatisticsPageState extends State<RideStatisticsPage> {
  int selectedSegment = 1;

  @override
  Widget build(BuildContext context) {
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

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
if (widget.mode == RideMode.takeRide) ...[
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

if (widget.mode == RideMode.offerRide) ...[
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
