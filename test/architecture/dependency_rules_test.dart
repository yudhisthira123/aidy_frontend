import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Iterable<File> dartFiles(String directory) sync* {
  final root = Directory(directory);
  if (!root.existsSync()) return;
  yield* root
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));
}

void expectNoDependencies(String directory, List<RegExp> forbidden) {
  for (final file in dartFiles(directory)) {
    final source = file.readAsStringSync();
    for (final dependency in forbidden) {
      expect(
        dependency.hasMatch(source),
        isFalse,
        reason:
            '${file.path} crosses a Clean Architecture boundary: '
            '${dependency.pattern}',
      );
    }
  }
}

void main() {
  test('source modules use explicit imports instead of library parts', () {
    for (final file in dartFiles('lib')) {
      final source = file.readAsStringSync();
      expect(
        RegExp(r'^part(?: of)?\s', multiLine: true).hasMatch(source),
        isFalse,
        reason: '${file.path} still uses implicit library coupling.',
      );
    }
  });

  test('presentation contains no raw API endpoint orchestration', () {
    for (final file in dartFiles('lib/presentation/features')) {
      final source = file.readAsStringSync();
      expect(
        RegExp(r'''\.request\(\s*['"](?:GET|POST|PUT|PATCH|DELETE)''')
            .hasMatch(source),
        isFalse,
        reason: '${file.path} owns an HTTP method or API path.',
      );
    }
  });

  test('domain is framework-independent and depends on no outer layer', () {
    expectNoDependencies('lib/domain', [
      RegExp(r"package:flutter"),
      RegExp(r"(?:^|/)data/"),
      RegExp(r"(?:^|/)infrastructure/"),
      RegExp(r"(?:^|/)presentation/"),
    ]);
  });

  test('data depends only on domain and transport packages', () {
    expectNoDependencies('lib/data', [
      RegExp(r"(?:^|/)infrastructure/"),
      RegExp(r"(?:^|/)presentation/"),
    ]);
  });

  test('application depends on domain contracts, not outer layers', () {
    expectNoDependencies('lib/application', [
      RegExp(r"package:flutter"),
      RegExp(r"(?:^|/)data/"),
      RegExp(r"(?:^|/)infrastructure/"),
      RegExp(r"(?:^|/)presentation/"),
    ]);
  });

  test('infrastructure does not depend on presentation or data', () {
    expectNoDependencies('lib/infrastructure', [
      RegExp(r"(?:^|/)data/"),
      RegExp(r"(?:^|/)presentation/"),
    ]);
  });

  test('presentation depends on domain contracts, not implementations', () {
    expectNoDependencies('lib/presentation', [
      RegExp(r"(?:^|/)data/"),
      RegExp(r"(?:^|/)infrastructure/"),
      RegExp(r'\bApiClient\b'),
    ]);
  });
}
