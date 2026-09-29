import 'package:flutter/material.dart' hide Text;

import '../../localization/app_localizations.dart';
import '../../localization/localized_text.dart';

const adminContentLanguages = {
  'en': 'English',
  'de': 'Deutsch',
  'es': 'Español',
  'fr': 'Français',
  'tr': 'Türkçe',
};

Map<String, Map<String, TextEditingController>> translationControllers(
  Map? existing,
) {
  final source = existing?['translations'] as Map? ?? {};
  final result = <String, Map<String, TextEditingController>>{};
  for (final entry in adminContentLanguages.entries) {
    final translated = source[entry.key] as Map?;
    result[entry.key] = {
      'name': TextEditingController(
        text:
            translated?['name'] ??
            (entry.key == 'en' ? (existing?['name'] ?? '') : ''),
      ),
      'description': TextEditingController(
        text:
            translated?['description'] ??
            (entry.key == 'en' ? (existing?['description'] ?? '') : ''),
      ),
    };
  }
  return result;
}

Map<String, dynamic> translationPayload(
  Map<String, Map<String, TextEditingController>> fields,
) => {
  for (final entry in fields.entries)
    entry.key: {
      'name': entry.value['name']!.text.trim(),
      'description': entry.value['description']!.text.trim(),
    },
};

class AdminTranslationEditor extends StatelessWidget {
  const AdminTranslationEditor({
    super.key,
    required this.fields,
    required this.language,
    required this.select,
    required this.nameLabel,
  });

  final Map<String, Map<String, TextEditingController>> fields;
  final String language;
  final ValueChanged<String> select;
  final String nameLabel;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      border: Border.all(color: Theme.of(context).dividerColor),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Localized content',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        const Text(
          'English is required. Empty translations use English.',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: adminContentLanguages.entries
              .map(
                (entry) => ChoiceChip(
                  label: Text('${entry.key.toUpperCase()} · ${entry.value}'),
                  selected: language == entry.key,
                  avatar: Icon(
                    fields[entry.key]!['name']!.text.trim().isEmpty
                        ? Icons.circle_outlined
                        : Icons.check_circle,
                    size: 15,
                  ),
                  onSelected: (_) => select(entry.key),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: fields[language]!['name'],
          decoration: InputDecoration(
            labelText:
                '${context.tr(nameLabel)}${language == 'en' ? ' *' : ''}',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: fields[language]!['description'],
          maxLines: 2,
          decoration: localizedInput(
            context,
            const InputDecoration(labelText: 'Description'),
          ),
        ),
      ],
    ),
  );
}
