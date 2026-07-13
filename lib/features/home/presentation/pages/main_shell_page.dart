import 'package:acepool/di/injection.dart';
import 'package:acepool/features/chat/presentation/pages/chat_list_page.dart';
import 'package:acepool/features/home/presentation/bloc/home_bloc.dart';
import 'package:acepool/features/home/presentation/pages/home_page.dart';
import 'package:acepool/features/home/presentation/widgets/home_bottom_nav_bar.dart';
import 'package:acepool/features/profile/presentation/pages/profile_page.dart';
import 'package:acepool/features/trips/presentation/pages/trips_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  void _goToProfile() {
    setState(() => _currentIndex = 3);
  }

  void _onTap(int index) {
    if (index == 1) {
      _goToTrips();
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeBloc>(
      // Shared with TripsPage's "Find ride" tab so it reflects whatever is
      // currently entered on Home's Find-ride form — no data of its own.
      create: (_) => sl<HomeBloc>()..add(const HomeStarted()),
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _currentIndex,
          children: [
            HomePage(onViewAllTrips: _goToTrips, onOpenProfile: _goToProfile),
            TripsPage(key: ValueKey(_tripsRefreshKey)),
            ChatListPage(onBack: () => setState(() => _currentIndex = 0)),
            const ProfilePage(),
          ],
        ),
        bottomNavigationBar: HomeBottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onTap,
        ),
      ),
    );
  }
}
