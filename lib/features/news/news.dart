part of "../../main.dart";

class NewsScreen extends StatelessWidget {
  final LokaleApi api;
  const NewsScreen({super.key, required this.api});
  static const stories = [
    (
      Icons.volunteer_activism_outlined,
      'Community pulse',
      'Neighbours responded to urgent calls, shared useful equipment, and helped reunite lost pets this week.',
      green,
    ),
    (
      Icons.construction_outlined,
      'A drill shared two streets away',
      'One small home project was completed without a new purchase because the right tool was already nearby.',
      Color(0xFF3977D4),
    ),
    (
      Icons.health_and_safety_outlined,
      'Help safely',
      'Check request details before accepting and bring only equipment you know how to use safely.',
      coral,
    ),
  ];
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Scaffold(
      appBar: AppBar(title: const Text('Community news')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: brand,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AROUND YOU',
                  style: TextStyle(
                    color: Color(0xFF8ED8BE),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Good things happen\nclose to home.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Stories, safety notes and practical community updates.',
                  style: TextStyle(color: Color(0xFFC8DADB)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ...stories.map(
            (story) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: story.$4.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(story.$1, color: story.$4),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              story.$2,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: brand,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              story.$3,
                              style: const TextStyle(
                                height: 1.45,
                                color: Color(0xFF627178),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EquipmentCatalog(api: api)),
            ),
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('Browse shared equipment'),
          ),
        ],
      ),
    ),
  );
}
