import 'package:flutter/material.dart' hide Text;

import '../../../application/equipment/equipment_service.dart';
import '../../../domain/gateways/lokale_api.dart';
import '../../localization/app_localizations.dart';
import '../../localization/localized_text.dart';

const _brand = Color(0xFF1B1D36);
const _green = Color(0xFF6757D9);
const _softMint = Color(0xFFE5F4EF);

class EquipmentCatalog extends StatefulWidget {
  final LokaleApi api;
  const EquipmentCatalog({super.key, required this.api});
  @override
  State<EquipmentCatalog> createState() => _EquipmentCatalogState();
}

class _EquipmentCatalogState extends State<EquipmentCatalog> {
  late final EquipmentService equipment = EquipmentService(widget.api);
  List items = [];
  bool loading = true;
  String query = '';
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final result = await equipment.availableEquipment();
      if (mounted) setState(() => items = result);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = items
        .where(
          (item) => ('${item['name']} ${item['description']}')
              .toLowerCase()
              .contains(query.toLowerCase()),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Shared equipment')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                children: [
                  TextField(
                    onChanged: (value) => setState(() => query = value),
                    decoration: localizedInput(
                      context,
                      const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search tools and equipment',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${visible.length} items available',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: _brand,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...visible.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),
                          leading: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest
                                  : _softMint,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.handyman_outlined,
                              color: _green,
                            ),
                          ),
                          title: Text(
                            item['name'] ?? 'Equipment',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            "${item['description'] ?? ''}\n${item['location'] ?? context.tr('Community pool')} · ${item['quantity'] ?? 1} ${context.tr('available')}",
                          ),
                          isThreeLine: true,
                          trailing: Chip(
                            label: Text(
                              context.enumLabel(item['condition'] ?? 'good'),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
