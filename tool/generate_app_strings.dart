import 'dart:convert';
import 'dart:io';
import 'package:msp430_lab/core/config/localization_config.dart';

/// Generates lib/utils/gen/app_strings.g.dart from all
/// JSON files declared in [AppLocalizationConfig.supportedLanguageCodes].
///
/// - Only keys that exist in **all** languages are generated.
/// - Each getter is camelCase and uses 'key'.tr().
/// - Each getter has a doc comment with translations from all languages:
///   /// Welcome - مرحبا - ...
/// - A PLURAL group — `key.zero` · `key.one` · `key.two` · `key.few` ·
///   `key.many` · `key.other` — becomes ONE method taking the count, the
///   count as printed (`{n}`), and any other `{}` values. Arabic has six
///   forms where English has two, so only `key.other` has to exist in every
///   language; a form a language does not write falls back to its `other`.
Future<void> main(List<String> args) async {
  const outputPath = 'lib/utils/gen/app_strings.g.dart';

  stdout.writeln('🌐 AppStrings generator starting...');
  stdout.writeln(
    '📁 Translations path: ${AppLocalizationConfig.translationsPath}',
  );
  stdout.writeln(
    '🈯 Supported languages: ${AppLocalizationConfig.supportedLanguageCodes.join(', ')}',
  );

  if (AppLocalizationConfig.supportedLanguageCodes.isEmpty) {
    stderr.writeln(
      '❌ No supportedLanguageCodes configured in AppLocalizationConfig.',
    );
    stderr.writeln('🛑 AppStrings generator FAILED.');
    exitCode = 1;
    return;
  }

  // Load and flatten all language JSON files.
  final languageMaps =
      <String, Map<String, String>>{}; // langCode -> keyPath -> value

  for (final code in AppLocalizationConfig.supportedLanguageCodes) {
    final inputPath = '${AppLocalizationConfig.translationsPath}/$code.json';
    final inputFile = File(inputPath);

    if (!await inputFile.exists()) {
      stderr.writeln('❌ Missing translations file for "$code": $inputPath');
      stderr.writeln('🛑 AppStrings generator FAILED.');
      exitCode = 1;
      return;
    }

    final raw = await inputFile.readAsString();
    if (raw.trim().isEmpty) {
      stderr.writeln('❌ Translation file for "$code" is empty: $inputPath');
      stderr.writeln('🛑 AppStrings generator FAILED.');
      exitCode = 1;
      return;
    }

    final decoded = json.decode(raw);
    if (decoded is! Map<String, dynamic>) {
      stderr.writeln(
        '❌ $inputPath must contain a top-level JSON object (found ${decoded.runtimeType}).',
      );
      stderr.writeln('🛑 AppStrings generator FAILED.');
      exitCode = 1;
      return;
    }

    final flat = _flattenJson(decoded);
    languageMaps[code] = flat;
    stdout.writeln('📖 [$code] loaded ${flat.length} keys from $inputPath');
  }

  // Plural groups: every `base.<form>` whose `base.other` exists.
  final pluralBases = <String>{};
  for (final map in languageMaps.values) {
    for (final key in map.keys) {
      final base = _pluralBaseOf(key);
      if (base != null && map.containsKey('$base.$_pluralGeneral')) {
        pluralBases.add(base);
      }
    }
  }
  bool isPluralForm(String key) {
    final base = _pluralBaseOf(key);
    return base != null && pluralBases.contains(base);
  }

  // Compute keys present in ALL languages. A plural form other than `other`
  // may be written by one language only — English has no «two».
  final allKeys = <String>{};
  for (final map in languageMaps.values) {
    allKeys.addAll(
      map.keys.where(
        (key) => !isPluralForm(key) || key.endsWith('.$_pluralGeneral'),
      ),
    );
  }

  Set<String>? commonKeys;
  for (final map in languageMaps.values) {
    commonKeys ??= map.keys.toSet();
    commonKeys = commonKeys.intersection(map.keys.toSet());
  }

  commonKeys ??= <String>{};
  commonKeys = commonKeys.where((key) => !isPluralForm(key)).toSet();

  // Report keys that are missing in some languages.
  final missingByKey =
      <String, List<String>>{}; // keyPath -> missing language codes
  for (final key in allKeys) {
    for (final code in AppLocalizationConfig.supportedLanguageCodes) {
      final map = languageMaps[code]!;
      if (!map.containsKey(key)) {
        missingByKey.putIfAbsent(key, () => <String>[]).add(code);
      }
    }
  }

  if (missingByKey.isNotEmpty) {
    stdout.writeln('⚠️ Keys missing in some languages:');
    for (final entry in missingByKey.entries) {
      stdout.writeln('   • ${entry.key} -> missing: ${entry.value.join(', ')}');
    }
    stderr.writeln(
      '🛑 AppStrings generator FAILED due to missing keys. '
      'Please add translations for all languages and run again.',
    );
    exitCode = 1;
    return;
  }

  // Placeholder counts must agree across languages. If they do not, `.tr(args:)`
  // silently drops or repeats a value in one language and nobody notices until
  // a user reports a sentence with a number missing from it.
  final placeholderMismatches = <String, Map<String, int>>{};
  for (final key in commonKeys) {
    final counts = <String, int>{};
    for (final code in AppLocalizationConfig.supportedLanguageCodes) {
      counts[code] = RegExp(
        r'\{\}',
      ).allMatches(languageMaps[code]![key]!).length;
    }
    if (counts.values.toSet().length > 1) {
      placeholderMismatches[key] = counts;
    }
  }

  // A plural group's `{}` values are not the count, so no form may drop
  // one: every form, in every language, carries as many as the reference
  // language's `other`. The COUNT is `{n}`, and the general form must show
  // it — a form that spells the number out («منذ ساعتين») may leave it out.
  final pluralProblems = <String>[];
  final reference = AppLocalizationConfig.supportedLanguageCodes.first;
  for (final base in pluralBases) {
    final expected = _positional(languageMaps[reference]!['$base.other']!);
    for (final code in AppLocalizationConfig.supportedLanguageCodes) {
      final map = languageMaps[code]!;
      final general = map['$base.$_pluralGeneral']!;
      if (!general.contains(_countToken)) {
        pluralProblems.add('[$code] $base.other has no $_countToken');
      }
      for (final form in _pluralForms) {
        final value = map['$base.$form'];
        if (value == null) continue;
        if (_positional(value) != expected) {
          pluralProblems.add(
            '[$code] $base.$form has ${_positional(value)} {} (expected '
            '$expected)',
          );
        }
        if (form != _pluralGeneral && value.trim() == general.trim()) {
          pluralProblems.add(
            '[$code] $base.$form is the same as $base.other — delete it; '
            'other already covers it',
          );
        }
      }
    }
  }
  for (final key in commonKeys) {
    for (final code in AppLocalizationConfig.supportedLanguageCodes) {
      if (languageMaps[code]![key]!.contains(_countToken)) {
        pluralProblems.add(
          '[$code] $key uses $_countToken but is not a plural group',
        );
      }
    }
  }

  if (pluralProblems.isNotEmpty) {
    stdout.writeln('⚠️ Plural groups that cannot be generated:');
    for (final problem in pluralProblems) {
      stdout.writeln('   • $problem');
    }
    stderr.writeln('🛑 AppStrings generator FAILED.');
    exitCode = 1;
    return;
  }

  if (placeholderMismatches.isNotEmpty) {
    stdout.writeln('⚠️ Placeholder counts differ between languages:');
    for (final entry in placeholderMismatches.entries) {
      stdout.writeln('   • ${entry.key} -> ${entry.value}');
    }
    stderr.writeln('🛑 AppStrings generator FAILED.');
    exitCode = 1;
    return;
  }

  // The same sentence under two keys means one of them is dead weight, and a
  // later edit to one leaves the app showing two different words for the same
  // thing. Refuse to generate rather than let that in.
  final duplicateValues = <String, List<String>>{};
  for (final code in AppLocalizationConfig.supportedLanguageCodes) {
    final byValue = <String, List<String>>{};
    final map = languageMaps[code]!;
    for (final key in <String>[
      ...commonKeys,
      ...map.keys.where(isPluralForm),
    ]) {
      byValue.putIfAbsent(map[key]!.trim(), () => <String>[]).add(key);
    }
    byValue.forEach((value, keys) {
      if (keys.length > 1) {
        duplicateValues['[$code] $value'] = keys..sort();
      }
    });
  }

  if (duplicateValues.isNotEmpty) {
    stdout.writeln('⚠️ The same value is used by more than one key:');
    for (final entry in duplicateValues.entries) {
      stdout.writeln('   • ${entry.key} -> ${entry.value.join(' · ')}');
    }
    stderr.writeln(
      '🛑 AppStrings generator FAILED. Merge the keys, or make the values '
      'genuinely different.',
    );
    exitCode = 1;
    return;
  }

  final commonKeyList = <String>[...commonKeys, ...pluralBases]..sort();

  stdout.writeln(
    'Common keys across all languages: ${commonKeyList.length} '
    '(${pluralBases.length} of them plural)',
  );

  final buffer = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
    ..writeln()
    ..writeln('part of app_strings;')
    ..writeln()
    ..writeln('class AppStrings {');

  for (final keyPath in commonKeyList) {
    final segments = keyPath.split('.');
    final propertyName = _camelOfKeyPath(segments);
    if (propertyName.isEmpty) continue;

    // A plural group is read through its general form.
    final isPlural = pluralBases.contains(keyPath);
    final lookup = isPlural ? '$keyPath.$_pluralGeneral' : keyPath;

    // Build doc comment with translations from all languages.
    final referenceValue =
        languageMaps[AppLocalizationConfig
            .supportedLanguageCodes
            .first]![lookup]!;
    final translations = <String>[];
    for (final code in AppLocalizationConfig.supportedLanguageCodes) {
      final value = languageMaps[code]![lookup];
      if (value != null && value.toString().trim().isNotEmpty) {
        translations.add(_cleanDocText(value.toString()));
      }
    }

    if (translations.isNotEmpty) {
      buffer.writeln('  /// ${translations.join(' - ')}');
    }

    // A counted sentence: the count picks the form, [n] is the count as the
    // reader sees it (through `AppFormats`), and the rest fill `{}` in order.
    // One line, like every other entry — the discipline test reads it so.
    if (isPlural) {
      final placeholders = _positional(referenceValue);
      final params = <String>[
        'num count',
        'String n',
        for (var i = 0; i < placeholders; i++) 'Object p${i + 1}',
      ].join(', ');
      final args = placeholders == 0
          ? 'const <String>[]'
          : '<String>[${List<String>.generate(placeholders, (i) => 'p${i + 1}.toString()').join(', ')}]';
      buffer.writeln(
        "  static String $propertyName($params) => "
        "_plural('$keyPath', count, n, $args);",
      );
      continue;
    }

    // A value containing `{}` is a template, not a sentence. It becomes a
    // METHOD taking one argument per placeholder instead of a getter, so a
    // caller cannot forget to fill it and cannot pass the wrong number — the
    // compiler catches both. Emitting a getter for these would leave a literal
    // `{}` on screen.
    final placeholders = RegExp(r'\{\}').allMatches(referenceValue).length;

    if (placeholders == 0) {
      buffer.writeln("  static String get $propertyName => '$keyPath'.tr();");
    } else {
      final params = List<String>.generate(
        placeholders,
        (i) => 'Object p${i + 1}',
      ).join(', ');
      final args = List<String>.generate(
        placeholders,
        (i) => 'p${i + 1}.toString()',
      ).join(', ');

      buffer.writeln(
        "  static String $propertyName($params) => "
        "'$keyPath'.tr(args: <String>[$args]);",
      );
    }
  }

  buffer
    ..writeln('}')
    ..writeln();

  final outputFile = File(outputPath);
  await outputFile.create(recursive: true);
  await outputFile.writeAsString(buffer.toString());

  stdout.writeln('Generated ${commonKeyList.length} keys into $outputPath');
  stdout.writeln('✅ AppStrings generator SUCCESS.');
}

/// The forms `easy_localization` picks between, by the CLDR rules of the
/// active language.
const List<String> _pluralForms = <String>[
  'zero',
  'one',
  'two',
  'few',
  'many',
  'other',
];

/// The form every language must write, and the one a missing form falls
/// back to.
const String _pluralGeneral = 'other';

/// Where a plural form puts the count.
const String _countToken = '{n}';

/// `time.hoursAgo` for `time.hoursAgo.two`; null for a key that does not end
/// in a plural form.
String? _pluralBaseOf(String key) {
  final dot = key.lastIndexOf('.');
  if (dot <= 0) return null;
  return _pluralForms.contains(key.substring(dot + 1))
      ? key.substring(0, dot)
      : null;
}

/// How many positional `{}` a value has.
int _positional(String value) => RegExp(r'\{\}').allMatches(value).length;

String _camelOfKeyPath(List<String> segments) {
  if (segments.isEmpty) return '';

  final convertedSegments = segments
      .map(_camelSegment)
      .where((s) => s.isNotEmpty)
      .toList();
  if (convertedSegments.isEmpty) return '';

  final buffer = StringBuffer();

  final first = convertedSegments.first;
  if (first.isNotEmpty) {
    buffer.write(first[0].toLowerCase());
    if (first.length > 1) {
      buffer.write(first.substring(1));
    }
  }

  for (final seg in convertedSegments.skip(1)) {
    if (seg.isEmpty) continue;
    buffer.write(_capitalize(seg));
  }

  return buffer.toString();
}

String _camelSegment(String input) {
  if (input.contains('_')) {
    final parts = input.split('_').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    final first = parts.first.toLowerCase();
    final rest = parts.skip(1).map((p) => _capitalize(p.toLowerCase())).join();
    return first + rest;
  }

  // If there are no underscores, assume the segment is already a reasonable
  // identifier (e.g. camelCase). We keep it as-is.
  return input;
}

String _capitalize(String input) {
  if (input.isEmpty) return '';
  if (input.length == 1) return input.toUpperCase();
  return input[0].toUpperCase() + input.substring(1);
}

/// Flattens a nested JSON object into key paths, e.g.:
/// {"home": {"title": "..."}} -> {"home.title": "..."}
Map<String, String> _flattenJson(Map<String, dynamic> source) {
  final result = <String, String>{};

  void walk(Map<String, dynamic> map, List<String> segments) {
    map.forEach((key, value) {
      final current = <String>[...segments, key];
      if (value is Map<String, dynamic>) {
        walk(value, current);
      } else {
        final path = current.join('.');
        result[path] = value.toString();
      }
    });
  }

  walk(source, const []);
  return result;
}

/// Cleans a translation string for use in a single-line doc comment.
String _cleanDocText(String input) {
  return input.replaceAll(RegExp(r'[\r\n]+'), ' ').trim();
}
