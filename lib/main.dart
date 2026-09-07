import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/routes/app_routes.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'features/location/models/location_model.dart';
import 'features/location/providers/location_provider.dart';

const brand = Color(0xFF1B1D36),
    green = Color(0xFF6757D9),
    canvas = Color(0xFFF8F7FC),
    coral = Color(0xFFFF6B6B),
    softMint = Color(0xFFEFECFF);

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Aidy',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      routerConfig: router,
    );
  }
}

class MainNavigationView extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavigationView({super.key, required this.navigationShell});

  void _onTabSelected(int index) {
    navigationShell.goBranch(
      index,

      // If the user taps the currently selected tab,
      // go back to that tab's root page.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTabSelected,
        destinations: [
          NavigationDestination(icon: Icon(Icons.home), label: 'Start'),
          NavigationDestination(
            icon: Icon(Icons.request_page),
            label: 'Requests',
          ),
          NavigationDestination(
            icon: Icon(Icons.question_mark),
            label: 'WhatsNew',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
