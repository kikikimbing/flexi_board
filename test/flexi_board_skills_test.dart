import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('published skills follow Dart package-skills conventions', () {
    final skillsRoot = Directory('skills');
    expect(
      skillsRoot.existsSync(),
      isTrue,
      reason: 'skills/ must ship with the package',
    );

    final skillDirs = skillsRoot
        .listSync()
        .whereType<Directory>()
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    expect(skillDirs, isNotEmpty);

    final names = <String>{};
    for (final dir in skillDirs) {
      final folder = dir.uri.pathSegments.where((s) => s.isNotEmpty).last;
      expect(
        folder.startsWith('flexi-board-') || folder.startsWith('flexi_board-'),
        isTrue,
        reason: '$folder must be prefixed with the package name',
      );

      final skillFile = File('${dir.path}/SKILL.md');
      expect(skillFile.existsSync(), isTrue, reason: '$folder needs SKILL.md');

      final text = skillFile.readAsStringSync();
      expect(
        text.startsWith('---'),
        isTrue,
        reason: '$folder SKILL.md needs YAML frontmatter',
      );

      final closed = text.indexOf('\n---', 3);
      expect(closed, greaterThan(0), reason: '$folder frontmatter must close');
      final frontmatter = text.substring(4, closed);
      final fields = _parseFrontmatter(frontmatter);

      final name = fields['name'];
      expect(name, isNotNull, reason: '$folder missing name:');
      expect(name, folder, reason: 'name: must match directory');
      expect(names.add(name!), isTrue, reason: 'duplicate skill name $name');
      expect(RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(name), isTrue);

      final description = fields['description'];
      expect(description, isNotNull, reason: '$folder missing description:');
      expect(description, isNotEmpty);
      expect(description!.length, lessThanOrEqualTo(1024));
      expect(description.toLowerCase(), contains('use when'));
    }
  });
}

Map<String, String> _parseFrontmatter(String frontmatter) {
  final fields = <String, String>{};
  String? currentKey;
  final buffer = StringBuffer();

  void flush() {
    if (currentKey == null) return;
    fields[currentKey] = buffer.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
    buffer.clear();
  }

  for (final rawLine in frontmatter.split('\n')) {
    final line = rawLine.trimRight();
    final keyMatch = RegExp(r'^([A-Za-z0-9_-]+):\s*(.*)$').firstMatch(line);
    if (keyMatch != null && !line.startsWith('  ')) {
      flush();
      currentKey = keyMatch.group(1);
      final rest = keyMatch.group(2)!.trim();
      if (rest == '>-' || rest == '>' || rest == '|') {
        buffer.clear();
      } else {
        buffer.write(rest);
      }
    } else if (currentKey != null) {
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(line.trim());
    }
  }
  flush();
  return fields;
}
