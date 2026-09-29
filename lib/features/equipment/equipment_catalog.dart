part of "../../main.dart";

class EquipmentCatalog extends StatefulWidget {
  final LokaleApi api;
  const EquipmentCatalog({super.key, required this.api});
  @override
  State<EquipmentCatalog> createState() => _EquipmentCatalogState();
}

class _EquipmentCatalogState extends State<EquipmentCatalog> {
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
      final result = await widget.api.request(
        'GET',
        '/api/equipment?available=true',
      );
      if (mounted) setState(() => items = result['equipment'] ?? []);
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
                      color: brand,
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
                                  : softMint,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.handyman_outlined,
                              color: green,
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
