import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'core/api_client.dart';
import 'core/app_localizations.dart';
import 'core/localized_text.dart';
import 'core/lokale_api.dart';
import 'core/notification_service.dart';
import 'features/admin/admin_management.dart';
import 'features/messages/messaging.dart';
import 'features/profile/profile_editor.dart';
import 'models/aidy_request.dart';

part "app/application.dart";
part "features/auth/auth_screen.dart";
part "features/capabilities/capabilities_screen.dart";
part "features/home/home.dart";
part "features/requests/create_request.dart";
part "features/requests/request_list.dart";
part "features/requests/helper_inbox.dart";
part "features/requests/request_detail.dart";
part "features/news/news.dart";
part "features/equipment/equipment_catalog.dart";
part "features/profile/profile_screen.dart";
part "features/profile/notification_preferences.dart";
part "features/admin/admin_center.dart";
part "shared/location_widgets.dart";
part "shared/ui_components.dart";

const brand = Color(0xFF1B1D36),
    green = Color(0xFF6757D9),
    canvas = Color(0xFFF8F7FC),
    coral = Color(0xFFFF6B6B),
    softMint = Color(0xFFEFECFF);
void main() => runApp(const AidyApp());
