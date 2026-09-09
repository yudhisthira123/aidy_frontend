

import 'dart:async';
import 'dart:io';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../models/location_model.dart';

final locationAsyncNotifierProvider = AsyncNotifierProvider<LocationNotifier, List<AidyLocation>>(LocationNotifier.new);

class LocationNotifier extends AsyncNotifier<List<AidyLocation>> {
  StreamSubscription<Position>? locationSubscription;
  Future<void> ensureLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if(!serviceEnabled) {
      return Future.error('Location services are disabled');
    }

    permission = await Geolocator.checkPermission();
    if(permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if(permission == LocationPermission.denied) {
        return Future.error('Location services are denied');
      }
    }

    if(permission == LocationPermission.deniedForever) {
      return Future.error('Location services are permanently denied');
    }
  }

  Future<Stream<Position>> watchPosition() async {
    final locationSetting = AndroidSettings(
        accuracy: LocationAccuracy.high,
        // distanceFilter: 50,
        intervalDuration: Duration(seconds: 5),
        foregroundNotificationConfig: ForegroundNotificationConfig(
            notificationText: "Tracking your location in the background",
            notificationTitle: "Live location active",
            enableWakeLock: true,
            setOngoing: true
        )
    );

    return Geolocator.getPositionStream(
        locationSettings: defaultTargetPlatformSettings(locationSetting)
    );
  }

  LocationSettings defaultTargetPlatformSettings(
      AndroidSettings androidSettings,
      ) {
    // On non-Android platforms, geolocator falls back to generic LocationSettings.
    return androidSettings;
  }

  Future<void> openSettings() => Geolocator.openAppSettings();
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  Future<void> startLocationTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if(!serviceEnabled) {
      return Future.error('Location services are disabled');
    }

    permission = await Geolocator.checkPermission();
    if(permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if(permission == LocationPermission.denied) {
        return Future.error('Location services are denied');
      }
    }

    if(permission == LocationPermission.deniedForever) {
      return Future.error('Location services are permanently denied');
    }

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'my_foreground', // id
      'MY FOREGROUND SERVICE', // title
      description:
      'This channel is used for important notifications.', // description
      importance: Importance.low, // importance must be at low or higher level
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

    if (Platform.isIOS || Platform.isAndroid) {
      await flutterLocalNotificationsPlugin.initialize(
          settings: InitializationSettings(
            iOS: DarwinInitializationSettings(),
            android: AndroidInitializationSettings('ic_bg_service_small')
          )
      );
    }

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    final service = FlutterBackgroundService();

    await service.configure(
        iosConfiguration: IosConfiguration(),
        androidConfiguration: AndroidConfiguration(
            onStart: onStart,
            autoStart: true,
            isForegroundMode: true,
            notificationChannelId: 'my_foreground',
            initialNotificationTitle: 'Location tracking',
            initialNotificationContent: 'Your movement is being tracked',
          foregroundServiceTypes: [AndroidForegroundType.location]
        )
    );
  }

  @override
  FutureOr<List<AidyLocation>> build() {
    return List.empty();
  }

  Future<void> startMonitoring() async {
    ensureLocationPermission();
    locationSubscription = (await watchPosition()).listen((Position pos) async {

      print("startMonitoring: longitude = ${pos.longitude} and latitude = ${pos.latitude}");

      return add(AidyLocation(latitude: pos.latitude, longitude: pos.longitude));
    });
  }

  void stopMonitoring() {
    locationSubscription?.cancel();
    locationSubscription = null;
  }

  Future<void> add(AidyLocation newLocation) async {
    final curList = [...state.requireValue];

    if (curList.length > 10) {
      // Remove the oldest
      curList.removeAt(0);
    }

    state = await AsyncValue.guard(() async {
      curList.add(newLocation);
      return curList;
    });
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  print("Background service started");

  Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        // distanceFilter: 20
      )
  ).listen((Position position) {
    print("Lat: ${position.latitude}, Lng: ${position.longitude}");
  }
  );
}