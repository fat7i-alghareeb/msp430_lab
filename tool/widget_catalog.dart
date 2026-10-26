import 'dart:io';

/// Lists every shared widget with the first sentence of its doc comment — the
/// cheap way to answer "does this already exist?" before building one.
///
/// ```bash
/// dart run tool/widget_catalog.dart                 # lib/common (shared widgets)
/// dart run tool/widget_catalog.dart --all           # + widgets inside features/
/// dart run tool/widget_catalog.dart button          # only names/paths/summaries containing "button"
/// ```
///
/// It reads the code, so it can never be out of date the way a hand-written
/// list can. A few hundred tokens is the whole catalogue; reading the files it
/// finds is what costs.
void main(List<String> args) {
  final all = args.contains('--all');
  final terms = args
      .where((a) => !a.startsWith('--'))
      .map((a) => a.toLowerCase())
      .toList();

  final roots = <String>['lib/common/widgets', if (all) 'lib/features'];
  final entries = <CatalogEntry>[];
  for (final root in roots) {
    final dir = Directory(root);
    if (!dir.existsSync()) continue;
    for (final file in dir.listSync(recursive: true).whereType<File>()) {
      final path = file.path.replaceAll(r'\', '/');
      if (!path.endsWith('.dart') || _generated(path)) continue;
      if (root == 'lib/features' && !path.contains('/presentation/ui/')) {
        continue;
      }
      entries.addAll(parseCatalog(path, file.readAsStringSync()));
    }
  }

  entries.sort((a, b) => a.path != b.path
      ? a.path.compareTo(b.path)
      : a.name.compareTo(b.name));

  var shown = 0;
  String? lastPath;
  for (final e in entries) {
    if (terms.isNotEmpty) {
      final haystack = '${e.name} ${e.path} ${e.summary}'.toLowerCase();
      if (!terms.every(haystack.contains)) continue;
    }
    if (e.path != lastPath) {
      stdout.writeln(e.path.replaceFirst('lib/common/widgets/', ''));
      lastPath = e.path;
    }
    stdout.writeln(
      '  ${e.name}${e.summary.isEmpty ? '' : ' — ${e.summary}'}',
    );
    shown++;
  }
  stdout.writeln(
    shown == 0
        ? 'Nothing matches. Build it — then run /finish so it is catalogued.'
        : '\n$shown shown. Open the file of the closest match before writing a new one.',
  );
}

bool _generated(String path) =>
    path.endsWith('.g.dart') ||
    path.endsWith('.freezed.dart') ||
    path.endsWith('.gen.dart') ||
    path.endsWith('.config.dart');

/// A public widget (or design-system type) found in a file.
class CatalogEntry {
  const CatalogEntry(this.path, this.name, this.summary);

  final String path;
  final String name;
  final String summary;
}

/// The public classes and enums in [source], each with the first sentence of
/// its doc comment. Private (`_Name`) types are skipped.
List<CatalogEntry> parseCatalog(String path, String source) {
  final lines = source.split('\n');
  final declaration = RegExp(
    r'^(?:abstract\s+final\s+class|abstract\s+class|final\s+class|class|enum|mixin|extension)\s+([A-Z][A-Za-z0-9]*)',
  );
  final result = <CatalogEntry>[];
  for (var i = 0; i < lines.length; i++) {
    final match = declaration.firstMatch(lines[i].trimRight());
    if (match == null) continue;

    var j = i - 1;
    // Skip annotations between the doc comment and the declaration.
    while (j >= 0 && lines[j].trimLeft().startsWith('@')) {
      j--;
    }
    final doc = <String>[];
    while (j >= 0 && lines[j].trimLeft().startsWith('///')) {
      doc.insert(0, lines[j].trimLeft().substring(3).trim());
      j--;
    }
    result.add(CatalogEntry(path, match.group(1)!, _firstSentence(doc)));
  }
  return result;
}

String _firstSentence(List<String> doc) {
  final text = doc
      .takeWhile((l) => !l.startsWith('```'))
      .where((l) => l.isNotEmpty)
      .join(' ')
      .replaceAll(RegExp(r'\[|\]|`'), '');
  if (text.isEmpty) return '';
  final end = text.indexOf(RegExp(r'[.!?](\s|$)'));
  final sentence = end == -1 ? text : text.substring(0, end + 1);
  return sentence.length > 110 ? '${sentence.substring(0, 107)}…' : sentence;
}
