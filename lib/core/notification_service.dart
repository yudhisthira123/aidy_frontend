import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

import '../firebase_options.dart';
import 'app_localizations.dart';
import 'lokale_api.dart';

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class NotificationService {
  NotificationService(this.api);
  final LokaleApi api;
  final local = FlutterLocalNotificationsPlugin();
  final ValueNotifier<String?> openedRequest = ValueNotifier(null);
  final ValueNotifier<String?> openedConversation = ValueNotifier(null);
  bool _refreshListenerAttached = false;
  Stream<RemoteMessage> get messages => FirebaseMessaging.onMessage;

  Future<AuthorizationStatus> permissionStatus() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return AuthorizationStatus.denied;
    }
    return (await FirebaseMessaging.instance.getNotificationSettings())
        .authorizationStatus;
  }

  bool permissionGranted(AuthorizationStatus status) =>
      status == AuthorizationStatus.authorized ||
      status == AuthorizationStatus.provisional;

  Future<void> initialize() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
    await local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload?.isNotEmpty == true) {
          final payload = response.payload!;
          if (payload.startsWith('conversation:')) {
            openedConversation.value = payload.substring(
              'conversation:'.length,
            );
          } else if (payload.startsWith('report:')) {
            openedRequest.value = payload;
          } else {
            openedRequest.value = payload.replaceFirst('request:', '');
          }
        }
      },
    );
    final strings = AppLocalizations(Locale(api.language));
    final channel = AndroidNotificationChannel(
      'aidy_help_requests',
      strings.t('Nearby help requests'),
      description: strings.t('Urgent nearby Lokale matching alerts'),
      importance: Importance.max,
    );
    await local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
    final reportsChannel = AndroidNotificationChannel(
      'aidy_nearby_reports',
      strings.t('Nearby lost and found'),
      description: strings.t(
        'Nearby lost pet, lost item, and found item alerts',
      ),
      importance: Importance.high,
    );
    await local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(reportsChannel);
    final updatesChannel = AndroidNotificationChannel(
      'aidy_request_updates',
      strings.t('Request updates'),
      description: strings.t('Helper acceptance and arrival updates'),
      importance: Importance.max,
    );
    await local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(updatesChannel);
    final messagesChannel = AndroidNotificationChannel(
      'aidy_messages',
      strings.t('Messages'),
      description: strings.t('Channel and direct message notifications'),
      importance: Importance.high,
    );
    await local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(messagesChannel);
    FirebaseMessaging.onMessage.listen(showForeground);
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      handleOpenedMessage(message);
    });
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) handleOpenedMessage(initial);
  }

  void handleOpenedMessage(RemoteMessage message) {
    if (message.data['type'] == 'conversation_message') {
      openedConversation.value = message.data['conversationId'];
    } else if (message.data['type'] == 'lost_report' ||
        message.data['type'] == 'found_report') {
      openedRequest.value = 'report:${message.data['requestId']}';
    } else {
      openedRequest.value = message.data['requestId'];
    }
  }

  Future<String> register({bool requestPermission = false}) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return 'Notifications unavailable on this platform';
    }
    final messaging = FirebaseMessaging.instance;
    var status = await permissionStatus();
    if (!permissionGranted(status) && requestPermission) {
      status = (await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      )).authorizationStatus;
    }
    if (!permissionGranted(status)) {
      throw Exception(
        'Notification permission is disabled in device settings.',
      );
    }
    final token = await messaging.getToken();
    if (token == null) {
      throw Exception('Firebase did not return a device token.');
    }
    var deviceId = await api.readLocal('aidy_device_id');
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await api.writeLocal('aidy_device_id', deviceId);
    }
    await api.request(
      'PUT',
      '/api/users/me/push-token',
      body: {
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'deviceId': deviceId,
      },
    );
    if (!_refreshListenerAttached) {
      _refreshListenerAttached = true;
      messaging.onTokenRefresh.listen((next) async {
        try {
          await api.request(
            'PUT',
            '/api/users/me/push-token',
            body: {
              'token': next,
              'platform': Platform.isIOS ? 'ios' : 'android',
              'deviceId': deviceId,
            },
          );
        } catch (_) {}
      });
    }
    return 'Push notifications active';
  }

  Future<void> unregisterCurrentDevice() async {
    final deviceId = await api.readLocal('aidy_device_id');
    if (deviceId == null || api.token == null) return;
    try {
      await api.request('DELETE', '/api/users/me/push-token/$deviceId');
    } catch (_) {}
  }

  Future<void> showForeground(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    final conversation = message.data['type'] == 'conversation_message';
    final nearbyReport =
        message.data['type'] == 'lost_report' ||
        message.data['type'] == 'found_report';
    final strings = AppLocalizations(Locale(api.language));
    await local.show(
      id: message.hashCode,
      title: notification.title ?? strings.t('Lokale notification'),
      body: notification.body ?? strings.t('A nearby request has changed.'),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          conversation
              ? 'aidy_messages'
              : nearbyReport
              ? 'aidy_nearby_reports'
              : 'aidy_help_requests',
          conversation
              ? strings.t('Messages')
              : nearbyReport
              ? strings.t('Nearby lost and found')
              : strings.t('Nearby help requests'),
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: conversation
          ? 'conversation:${message.data['conversationId']}'
          : nearbyReport
          ? 'report:${message.data['requestId']}'
          : 'request:${message.data['requestId']}',
    );
  }
}
