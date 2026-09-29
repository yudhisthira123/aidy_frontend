import 'package:flutter/material.dart' hide Text;

import '../localization/localized_text.dart';

class Section extends StatelessWidget {
  const Section({super.key, required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Text('None added')
          else
            ...items.map(
              (item) => ListTile(
                dense: true,
                leading: const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF6757D9),
                ),
                title: Text(item),
              ),
            ),
        ],
      ),
    ),
  );
}
