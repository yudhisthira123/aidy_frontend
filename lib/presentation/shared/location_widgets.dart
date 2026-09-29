import 'package:flutter/material.dart' hide Text;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/localized_text.dart';
import 'app_colors.dart';

class LocationPicker extends StatefulWidget {
  final LatLng initial;
  const LocationPicker({super.key, required this.initial});
  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  late LatLng selected = widget.initial;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Choose location')),
    body: Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: selected,
            initialZoom: 14,
            onTap: (_, point) => setState(() => selected = point),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.aidy.aidy_mobile',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: selected,
                  width: 54,
                  height: 54,
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 48,
                  ),
                ),
              ],
            ),
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
        Positioned(
          left: 18,
          right: 18,
          bottom: 24,
          child: FilledButton.icon(
            onPressed: () => Navigator.pop(context, selected),
            icon: const Icon(Icons.check),
            label: const Text('Use this location'),
          ),
        ),
      ],
    ),
  );
}

class MapView extends StatelessWidget {
  final double lat, lon;
  const MapView({super.key, required this.lat, required this.lon});
  @override
  Widget build(BuildContext c) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: FlutterMap(
      options: MapOptions(initialCenter: LatLng(lat, lon), initialZoom: 14),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.aidy.aidy_mobile',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: LatLng(lat, lon),
              width: 48,
              height: 48,
              child: const Icon(
                Icons.location_pin,
                color: Colors.red,
                size: 44,
              ),
            ),
          ],
        ),
        const RichAttributionWidget(
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
        ),
      ],
    ),
  );
}

class SearchAreaMap extends StatelessWidget {
  final double lat, lon, radiusKm;
  const SearchAreaMap({
    super.key,
    required this.lat,
    required this.lon,
    required this.radiusKm,
  });
  @override
  Widget build(BuildContext context) {
    final point = LatLng(lat, lon);
    final zoom = radiusKm <= 1
        ? 14.0
        : radiusKm <= 5
        ? 12.0
        : radiusKm <= 10
        ? 11.0
        : radiusKm <= 25
        ? 9.5
        : 8.5;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: FlutterMap(
        options: MapOptions(initialCenter: point, initialZoom: zoom),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.aidy.aidy_mobile',
          ),
          CircleLayer(
            circles: [
              CircleMarker(
                point: point,
                radius: radiusKm * 1000,
                useRadiusInMeter: true,
                color: green.withValues(alpha: .13),
                borderColor: green.withValues(alpha: .8),
                borderStrokeWidth: 2,
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: point,
                width: 44,
                height: 44,
                child: const Icon(
                  Icons.my_location_rounded,
                  color: brand,
                  size: 34,
                ),
              ),
            ],
          ),
          const RichAttributionWidget(
            attributions: [TextSourceAttribution('OpenStreetMap contributors')],
          ),
        ],
      ),
    );
  }
}

Future<void> openNavigation(double lat, double lon) => launchUrl(
  Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lon'),
  mode: LaunchMode.externalApplication,
);

Color statusColor(dynamic status) {
  switch (status?.toString()) {
    case 'completed':
      return green;
    case 'helper_on_site':
      return const Color(0xFF7B4BB7);
    case 'helper_on_way':
      return const Color(0xFF3977D4);
    case 'searching':
      return const Color(0xFFE08B2D);
    case 'auto_closed':
      return const Color(0xFF7A858A);
    default:
      return brand;
  }
}
