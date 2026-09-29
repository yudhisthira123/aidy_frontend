import 'dart:io';

const excluded = {
  'lib/firebase_options.dart',
  'lib/core/static_content_translations.dart',
};

Future<String> git(List<String> arguments) async {
  final result = await Process.run('git', arguments);
  if (result.exitCode != 0) {
    stderr.write(result.stderr);
    throw StateError('git ${arguments.join(' ')} failed');
  }
  return result.stdout as String;
}

Map<String, Map<int, int>> readCoverage() {
  final report = File('coverage/lcov.info');
  if (!report.existsSync()) {
    throw StateError(
      'coverage/lcov.info is missing; run flutter test --coverage first.',
    );
  }
  final coverage = <String, Map<int, int>>{};
  String? current;
  for (final line in report.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      current = line.substring(3).replaceAll('\\', '/');
      coverage[current] = <int, int>{};
    } else if (current != null && line.startsWith('DA:')) {
      final values = line.substring(3).split(',');
      coverage[current]![int.parse(values[0])] = int.parse(values[1]);
    }
  }
  return coverage;
}

void addLine(Map<String, Set<int>> changes, String file, int line) {
  changes.putIfAbsent(file, () => <int>{}).add(line);
}

Future<Map<String, Set<int>>> changedLines(String baseRef) async {
  final changes = <String, Set<int>>{};
  final diff = await git([
    'diff',
    '--unified=0',
    '--no-ext-diff',
    baseRef,
    '--',
    'lib',
  ]);
  String? file;
  for (final line in diff.split(RegExp(r'\r?\n'))) {
    if (line.startsWith('+++ b/')) {
      file = line.substring(6);
      continue;
    }
    if (file == null || !line.startsWith('@@')) continue;
    final range = RegExp(r'\+(\d+)(?:,(\d+))?').firstMatch(line);
    if (range == null) continue;
    final start = int.parse(range.group(1)!);
    final count = range.group(2) == null ? 1 : int.parse(range.group(2)!);
    for (var offset = 0; offset < count; offset += 1) {
      addLine(changes, file, start + offset);
    }
  }
  final untracked = await git([
    'ls-files',
    '--others',
    '--exclude-standard',
    '--',
    'lib',
  ]);
  for (final file
      in untracked.split(RegExp(r'\r?\n')).where((line) => line.isNotEmpty)) {
    changes.putIfAbsent(file, () => <int>{});
  }
  return changes;
}

Future<void> main() async {
  final baseRef = Platform.environment['COVERAGE_BASE_REF'] ?? 'origin/main';
  final minimum =
      double.tryParse(Platform.environment['NEW_CODE_COVERAGE_MIN'] ?? '') ??
      80;
  final coverage = readCoverage();
  final changes = await changedLines(baseRef);
  for (final entry in changes.entries) {
    if (entry.value.isEmpty && coverage.containsKey(entry.key)) {
      entry.value.addAll(coverage[entry.key]!.keys);
    }
  }

  var covered = 0;
  var total = 0;
  final missing = <String>[];
  stdout.writeln('Flutter new-code coverage against $baseRef:');
  final files = changes.keys.where((file) => file.endsWith('.dart')).toList()
    ..sort();
  for (final file in files) {
    if (excluded.contains(file)) continue;
    final fileCoverage = coverage[file];
    if (fileCoverage == null) {
      missing.add(file);
      continue;
    }
    var fileCovered = 0;
    var fileTotal = 0;
    for (final line in changes[file]!) {
      if (!fileCoverage.containsKey(line)) continue;
      fileTotal += 1;
      if (fileCoverage[line]! > 0) fileCovered += 1;
    }
    if (fileTotal == 0) continue;
    covered += fileCovered;
    total += fileTotal;
    stdout.writeln(
      '  ${(100 * fileCovered / fileTotal).toStringAsFixed(2).padLeft(6)}% '
      '$file ($fileCovered/$fileTotal lines)',
    );
  }
  if (missing.isNotEmpty) {
    throw StateError(
      'Changed Dart files are absent from LCOV: ${missing.join(', ')}',
    );
  }
  if (total == 0) {
    stdout.writeln(
      'No instrumented Dart lines changed; the new-code gate is not applicable.',
    );
    return;
  }
  final percentage = 100 * covered / total;
  stdout.writeln(
    'Flutter new-code coverage: ${percentage.toStringAsFixed(2)}% ($covered/$total)',
  );
  if (percentage < minimum) {
    throw StateError(
      'Flutter new-code coverage ${percentage.toStringAsFixed(2)}% is below '
      '${minimum.toStringAsFixed(2)}%.',
    );
  }
}
