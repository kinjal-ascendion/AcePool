import 'package:acepool/features/home/presentation/pages/home_page.dart';
import 'package:acepool/features/home/presentation/widgets/home_bottom_nav_bar.dart';
import 'package:acepool/features/profile/presentation/pages/profile_page.dart';
import 'package:acepool/features/trips/presentation/pages/trips_page.dart';
import 'package:flutter/material.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _currentIndex = 0;
  int _tripsRefreshKey = 0;

  void _goToTrips() {
    setState(() {
      _tripsRefreshKey++;
      _currentIndex = 1;
    });
  }

  void _onTap(int index) {
    if (index == 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coming soon')),
      );
      return;
    }
    if (index == 1) {
      _goToTrips();
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomePage(onViewAllTrips: _goToTrips),
          TripsPage(key: ValueKey(_tripsRefreshKey)),
          const SizedBox.shrink(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: HomeBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
      ),
    );
  }
}
