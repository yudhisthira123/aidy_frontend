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
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      routerConfig: router,
      // home: HomeView(),
      // home: authState.when(
      //     data: (AuthResponse? authResponse ) {
      //       if(authResponse != null ) {
      //         return HomeView();
      //       } else {
      //         return HomeView();
      //       }
      //       },
      //     error: (err, stack) => HomeView(),
      //     loading: () => Scaffold(
      //       body: Center(child: CircularProgressIndicator(),),
      //     )
      // ),
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

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  bool isMonitoring = true;

  @override
  void initState() {
    super.initState();
    ref.read(locationAsyncNotifierProvider.notifier).startMonitoring();
  }

  @override
  void dispose() {
    super.dispose();
    if (isMonitoring) {
      ref.read(locationAsyncNotifierProvider.notifier).stopMonitoring();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ref
        .watch(locationAsyncNotifierProvider)
        .when(
          data: (listAidyLocations) {
            return Scaffold(
              appBar: AppBar(title: const Text('AIDY - Live Location')),
              body: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        if (isMonitoring) {
                          ref
                              .read(locationAsyncNotifierProvider.notifier)
                              .stopMonitoring();
                          isMonitoring = false;
                        } else {
                          ref
                              .read(locationAsyncNotifierProvider.notifier)
                              .startMonitoring();
                          isMonitoring = true;
                        }
                      },
                      child: Text('Start/Stop Location Monitor'),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _distanceMessage(listAidyLocations),
                        style: TextStyle(fontSize: 20, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          error: (err, stack) {
            return Center(child: Text('Could not fetch your location.'));
          },
          loading: () => Center(child: CircularProgressIndicator()),
        );
  }

  String _distanceMessage(List<AidyLocation> listAidyLocations) {
    if (listAidyLocations.length > 1) {
      int secondLastIndex = listAidyLocations.length - 2;
      double distanceMoved = Geolocator.distanceBetween(
        listAidyLocations[secondLastIndex].latitude,
        listAidyLocations[secondLastIndex].longitude,
        listAidyLocations.last.latitude,
        listAidyLocations.last.longitude,
      );
      return 'Current Latitude: ${listAidyLocations.last.latitude},\n'
          'Current Longitude: ${listAidyLocations.last.longitude} \n'
          'Distance moved: ${distanceMoved.toStringAsFixed(2)} mts';
    } else if (listAidyLocations.isNotEmpty) {
      return 'Initial Latitude: ${listAidyLocations[0].latitude},\n'
          'Initial Longitude: ${listAidyLocations[0].longitude}';
    } else {
      return 'No location info available';
    }
  }
}
