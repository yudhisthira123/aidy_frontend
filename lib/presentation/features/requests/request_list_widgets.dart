import 'package:flutter/material.dart' hide Text;

import '../../localization/app_localizations.dart';
import '../../localization/localized_text.dart';
import '../../shared/app_colors.dart';
import '../../shared/location_widgets.dart';
import '../../shared/ui_components.dart';
import '../../shared/value_formatters.dart';

class SearchAreaCard extends StatelessWidget {
  final String label;
  final double? latitude, longitude;
  final double radiusKm;
  final bool locating;
  final VoidCallback onCurrentLocation;
  final VoidCallback onChooseMap;
  final ValueChanged<double> onRadius;

  const SearchAreaCard({
    super.key,
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
    required this.locating,
    required this.onCurrentLocation,
    required this.onChooseMap,
    required this.onRadius,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, scheme.tertiary, .58)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: .18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.radar_rounded, color: Colors.white),
              SizedBox(width: 9),
              Text(
                'Search this area',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: TextStyle(color: Colors.white.withValues(alpha: .82)),
          ),
          if (latitude != null && longitude != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 180,
              child: SearchAreaMap(
                key: ValueKey('$latitude:$longitude:$radiusKm'),
                lat: latitude!,
                lon: longitude!,
                radiusKm: radiusKm,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: locating ? null : onCurrentLocation,
                icon: locating
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded),
                label: const Text('Current'),
              ),
              FilledButton.tonalIcon(
                onPressed: onChooseMap,
                icon: const Icon(Icons.map_outlined),
                label: const Text('Pick on map'),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .92),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<double>(
                    value: radiusKm,
                    icon: const Icon(Icons.expand_more_rounded),
                    items: const [1.0, 5.0, 10.0, 25.0, 50.0]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text('${value.toInt()} km'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) onRadius(value);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DiscoveryRequestCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final VoidCallback? onRespond;
  const DiscoveryRequestCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onRespond,
  });

  @override
  Widget build(BuildContext context) {
    final requestKind = item['kind']?.toString() ?? 'help';
    final found = requestKind == 'found';
    final lost = requestKind == 'lost';
    final scheme = Theme.of(context).colorScheme;
    final color = found
        ? const Color(0xFF167C67)
        : lost
        ? const Color(0xFFB66A13)
        : item['urgency'] == 'immediately'
        ? coral
        : scheme.primary;
    final icon = found
        ? Icons.inventory_2_outlined
        : lost
        ? Icons.search_rounded
        : Icons.volunteer_activism_outlined;
    final distance = (item['distanceKm'] as num?)?.toDouble();
    final description = item['description']?.toString().trim() ?? '';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          readable(item['subcategory'] ?? requestKind),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${readable(requestKind)} · ${context.enumLabel(item['status'] ?? 'created')}',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (item['isOwn'] == true)
                    const StatusPill(label: 'Yours', color: green)
                  else if (distance != null)
                    StatusPill(
                      label: distance < 1
                          ? '${(distance * 1000).round()} m'
                          : '${distance.toStringAsFixed(1)} km',
                      color: color,
                    ),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 19,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      item['location']?['label'] ?? 'Pinned location',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ),
                  if (onRespond != null) ...[
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: onRespond,
                      child: const Text('Respond'),
                    ),
                  ] else
                    const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RequestEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback action;
  final String actionLabel;
  const RequestEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
    required this.actionLabel,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 24),
    child: Column(
      children: [
        Icon(icon, size: 52, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 14),
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 7),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: action,
          icon: const Icon(Icons.arrow_forward_rounded),
          label: Text(actionLabel),
        ),
      ],
    ),
  );
}
