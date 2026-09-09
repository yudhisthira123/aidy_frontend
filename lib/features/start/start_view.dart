import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../main.dart';
import '../brand_log.dart';

class StartView extends ConsumerStatefulWidget {
  const StartView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _StartViewState();
  }
}

class _StartViewState extends ConsumerState<StartView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AIDY')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          Row(
            children: [
              const BrandLogo(size: 44),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Lokale',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: brand,
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_rounded),
                tooltip: 'Requests and notifications',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [brand, Color(0xFF4B3FA5), Color(0xFF7461DC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x332F275F),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, User name',
                  style: const TextStyle(
                    color: Color(0xFFD9D1FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Help is closer\nthan you think.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Ask for support or lend a hand nearby.',
                  style: TextStyle(color: Color(0xFFE3DFFF), fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const Text(
            'How can we help?',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              color: brand,
            ),
          ),
          const Text(
            'Choose a starting point and we’ll guide you.',
            style: TextStyle(color: Color(0xFF718087)),
          ),
          const SizedBox(height: 14),
          CategoryCard(categoryId: 'quick_help', categoryName: 'Quick call for help', categoryDescription: 'Time-critical situations requiring immediate assistance'),
          CategoryCard(categoryId: 'local_support', categoryName: 'Local support & community', categoryDescription: 'Non-time-critical neighbourhood support & tool sharing'),
          CategoryCard(categoryId: 'lost_found', categoryName: 'Lost & found', categoryDescription: 'Independent lost pet and item recovery process'),
          // ...categories.map(
          //       (x) => CategoryCard(
          //     data: Map<String, dynamic>.from(x),
          //   ),
          // ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                  : softMint,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: green),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart nearby matching',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: brand,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Distance, skills, equipment and availability decide who is alerted.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF60766E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.newspaper_outlined),
              ),
              title: const Text(
                'Community news',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text('Stories, safety notes and local updates'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {},
            ),
          ),
        ],
      ),
      // body: Column(
      //   children: [
      //     Container(
      //       padding: EdgeInsets.all(20),
      //       decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
      //       child: ElevatedButton(
      //         onPressed: () {
      //           context.go('/start/quickhelp');
      //         },
      //         child: Text('Quick Help'),
      //       ),
      //     ),
      //     ElevatedButton(
      //       onPressed: () {
      //         context.go('/start/localsupport');
      //       },
      //       child: Text('Local support'),
      //     ),
      //     ElevatedButton(
      //       onPressed: () {
      //         context.go('/start/lostandfound');
      //       },
      //       child: Text('Lost & Found'),
      //     ),
      //   ],
      // ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final String categoryId;
  final String categoryName;
  final String categoryDescription;

  // final Map<String, dynamic> data;
  const CategoryCard({super.key, required this.categoryId, required this.categoryName, required this.categoryDescription});
  @override
  Widget build(BuildContext context) {
    final id = categoryId;
    final color = id == 'quick_help'
        ? Colors.red
        : id == 'local_support'
        ? Colors.blue
        : green;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: Theme.of(context).colorScheme.surface,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            switch(categoryId) {
              case 'quick_help':
                return context.go('/start/quickhelp');

              case 'local_support':
                return context.go('/start/localsupport');

              case 'lost_found':
                return context.go('/start/lostandfound');

            }
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .11),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    id == 'quick_help'
                        ? Icons.favorite
                        : id == 'local_support'
                        ? Icons.handshake
                        : Icons.search,
                    color: color,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(categoryDescription ?? 'Create a request'),
                    ],
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .09),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
