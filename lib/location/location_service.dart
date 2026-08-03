import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {

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

  Future<void> watchPosition() async {

    final locationSetting = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50,
      intervalDuration: Duration(seconds: 20),
      foregroundNotificationConfig: ForegroundNotificationConfig(
        notificationText: "Tracking your location in the background",
        notificationTitle: "Live location active",
        enableWakeLock: true,
        setOngoing: true
      )
    );

    Geolocator.getPositionStream(
      locationSettings: defaultTargetPlatformSettings(locationSetting)
    ).listen((Position position) {
      print("Lat: ${position.latitude}, Lng: ${position.longitude}");
    });
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

    final service = FlutterBackgroundService();

    await service.configure(
        iosConfiguration: IosConfiguration(),
        androidConfiguration: AndroidConfiguration(
          onStart: onStart,
          autoStart: true,
          isForegroundMode: true,
          notificationChannelId: 'location_channel',
          initialNotificationTitle: 'Location tracking',
          initialNotificationContent: 'Your movement is being tracked'
        )
    );
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  Geolocator.getPositionStream(
      locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 20
      )
  ).listen((Position position) {
    print("Lat: ${position.latitude}, Lng: ${position.longitude}");
  }
  );
}