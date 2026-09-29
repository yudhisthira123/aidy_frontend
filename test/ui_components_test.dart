import 'package:aidy_mobile/presentation/localization/app_localizations.dart';
import 'package:aidy_mobile/presentation/shared/section.dart';
import 'package:aidy_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget localizedApp(Widget child) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [AppLocalizations.delegate],
  home: Scaffold(body: child),
);

void main() {
  testWidgets('status and information components render their content', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedApp(
        const Column(
          children: [
            StatusPill(label: 'Available', color: Colors.green),
            InfoStep(
              icon: Icons.people,
              title: 'Community',
              text: 'Neighbours helping neighbours',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Available'), findsOneWidget);
    expect(find.text('Community'), findsOneWidget);
    expect(find.byIcon(Icons.people), findsOneWidget);
  });

  testWidgets('choices toggle presets and add a custom competency', (
    tester,
  ) async {
    final selected = <String>{};
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      localizedApp(
        Choices(
          title: 'Competencies',
          values: const ['First aid', 'Bicycle repair'],
          selected: selected,
          controller: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('First aid'));
    await tester.pump();
    expect(selected, contains('First aid'));

    await tester.enterText(find.byType(TextField), 'Neighbour support');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(selected, contains('Neighbour support'));
    expect(controller.text, isEmpty);
  });

  testWidgets('section shows an empty state and populated items', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedApp(
        const Column(
          children: [
            Section(title: 'Empty equipment', items: []),
            Section(
              title: 'Equipment',
              items: ['Bike repair kit', 'Fire extinguisher'],
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('None added'), findsOneWidget);
    expect(find.text('Bike repair kit'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsNWidgets(2));
  });
}
