import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'application/auth/authentication_service.dart';
import 'application/requests/request_service.dart';
import 'data/network/api_client.dart';
import 'domain/gateways/lokale_api.dart';
import 'infrastructure/notifications/notification_service.dart';
import 'presentation/features/admin/admin_management.dart';
import 'presentation/features/messages/messaging.dart';
import 'presentation/features/profile/profile_editor.dart';
import 'presentation/localization/app_localizations.dart';
import 'presentation/localization/localized_text.dart';

part "app/application.dart";
part "presentation/features/auth/auth_screen.dart";
part "presentation/features/capabilities/capabilities_screen.dart";
part "presentation/features/home/home.dart";
part "presentation/features/requests/create_request.dart";
part "presentation/features/requests/request_list.dart";
part "presentation/features/requests/helper_inbox.dart";
part "presentation/features/requests/request_detail.dart";
part "presentation/features/news/news.dart";
part "presentation/features/equipment/equipment_catalog.dart";
part "presentation/features/profile/profile_screen.dart";
part "presentation/features/profile/notification_preferences.dart";
part "presentation/features/admin/admin_center.dart";
part "presentation/shared/location_widgets.dart";
part "presentation/shared/ui_components.dart";

const brand = Color(0xFF1B1D36),
    green = Color(0xFF6757D9),
    canvas = Color(0xFFF8F7FC),
    coral = Color(0xFFFF6B6B),
    softMint = Color(0xFFEFECFF);
void main() => runApp(const AidyApp());
