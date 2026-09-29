import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

abstract final class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Firebase messaging is configured for Android and iOS only.',
        );
    }
  }

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyCM9YI0WoHfULcs-XKu8_NDRmfwZkqswkA',
    appId: '1:57394565294:android:276135cc1f1259b0951d3f',
    messagingSenderId: '57394565294',
    projectId: 'aidy-43233',
    storageBucket: 'aidy-43233.firebasestorage.app',
  );

  static const ios = FirebaseOptions(
    apiKey: 'AIzaSyD2DTIoXEn-ZBGm-J88iNpafZB5kHdJJcU',
    appId: '1:57394565294:ios:94884959dae77b23951d3f',
    messagingSenderId: '57394565294',
    projectId: 'aidy-43233',
    storageBucket: 'aidy-43233.firebasestorage.app',
    iosBundleId: 'com.aidy.aidyMobile',
  );
}
