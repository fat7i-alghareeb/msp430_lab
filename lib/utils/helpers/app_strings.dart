// ignore: unnecessary_library_name
library app_strings;

import 'package:easy_localization/easy_localization.dart';

part '../gen/app_strings.g.dart';

/// The form of a counted sentence for [count] — «منذ ساعة» · «منذ ساعتين» ·
/// «منذ 3 ساعات» · «منذ 11 ساعة».
///
/// Arabic writes six forms (zero · one · two · few · many · other) where
/// English writes two, and one fixed template per count printed «منذ 2
/// ساعات» and «1 تعليقات». The forms live in the
/// JSON as `key.one`, `key.two`…, and `tool/generate_app_strings.dart` turns
/// each group into ONE method that lands here.
///
/// [n] is the count as the reader sees it — always through `AppFormats` —
/// and goes where a form writes `{n}`; a form that spells the number out
/// («منذ ساعتين») simply has none. [args] fill the other `{}` in order.
String _plural(String key, num count, String n, List<String> args) {
  final named = <String, String>{'n': n};
  final general = '$key.other';

  // Outside the app — a widget test, a preview — nothing is loaded, so there
  // is no language to choose a form by, and `plural` would throw on a locale
  // that was never set. Every other string answers with its key there; so
  // does this one.
  if (general.tr(namedArgs: named, args: args) == general) return general;

  return key.plural(count, namedArgs: named, args: args);
}
