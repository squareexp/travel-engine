import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../design/colors.dart';
import '../bookings/bookings_screen.dart';
import '../explore/explore_screen.dart';
import '../favorites/favorites_screen.dart';
import '../profile/profile_screen.dart';
import '../transport/transport_screen.dart';
import 'home_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _tabs = <Widget>[
    HomeScreen(),
    ExploreScreen(),
    BookingsScreen(),
    TransportScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TwendeColors.background,
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: TwendeColors.surface,
        elevation: 0,
        height: 64,
        indicatorColor: TwendeColors.accent.withValues(alpha: .12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(IconsaxPlusLinear.home_2),
            selectedIcon: Icon(
              IconsaxPlusBold.home_2,
              color: TwendeColors.accent,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(IconsaxPlusLinear.discover),
            selectedIcon: Icon(
              IconsaxPlusBold.discover,
              color: TwendeColors.accent,
            ),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(IconsaxPlusLinear.calendar_2),
            selectedIcon: Icon(
              IconsaxPlusBold.calendar_2,
              color: TwendeColors.accent,
            ),
            label: 'My trip',
          ),
          NavigationDestination(
            icon: Icon(IconsaxPlusLinear.car),
            selectedIcon: Icon(IconsaxPlusBold.car, color: TwendeColors.accent),
            label: 'Transport',
          ),
          NavigationDestination(
            icon: Icon(IconsaxPlusLinear.user),
            selectedIcon: Icon(
              IconsaxPlusBold.user,
              color: TwendeColors.accent,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// Re-exported here for routes that link out from Profile.
class FavoritesShell extends StatelessWidget {
  const FavoritesShell({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TwendeColors.background,
      appBar: AppBar(),
      body: const FavoritesScreen(),
    );
  }
}
