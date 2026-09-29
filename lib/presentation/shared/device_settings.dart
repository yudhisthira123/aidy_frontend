import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

final class DeviceSettings {
  static const channel = MethodChannel('lokale/device_settings');

  static Future<void> open(String section) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await channel.invokeMethod(section);
    } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await launchUrl(Uri.parse('app-settings:'));
    }
  }
}
