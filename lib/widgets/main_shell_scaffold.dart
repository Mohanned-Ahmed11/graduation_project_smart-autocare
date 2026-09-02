import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bottom [NavigationBar] for Home, nearby requests, and My requests (StatefulShell).
class MainShellScaffold extends StatelessWidget {
  const MainShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded),
            label: 'Nearby',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt_rounded),
            label: 'My requests',
          ),
        ],
      ),
    );
  }
}
