import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../extensions/int_extensions.dart';
import 'app_strings.dart';

/// Numbers, prices, dates and times — formatted through `intl`, never by hand.
///
/// Every number prints in LATIN digits, in every language (one switch:
/// [_numberLocaleOf]), and goes through `intl` for grouping. Writing
/// `'$price $currency'` by hand looks like it works and then prints
/// `4500000` with no grouping.
///
/// Everything here takes a [BuildContext] so the locale is the one on screen,
/// not whatever `Intl.defaultLocale` happens to hold.
class AppFormats {
  AppFormats._();

  /// The locale NUMBERS are formatted against: always Latin digits.
  ///
  /// Every number in the app — prices, counts, dates, times, versions —
  /// prints `0-9`, in every language. It is ONE place: every formatter below
  /// reads this, so a number can never come out in another digit system
  /// beside it. Return `Localizations.localeOf(context).languageCode` here
  /// to get Arabic-Indic digits in Arabic instead.
  ///
  /// `en`, not plain `ar`: CLDR's `ar` also carries Latin digits, but its
  /// separators are not guaranteed across `intl` versions; `en` gives
  /// `4,500,000` everywhere.
  static String _numberLocaleOf(BuildContext context) => 'en';

  /// `4,500,000` — grouped, in Latin digits, with no currency.
  static String number(BuildContext context, num value) {
    return NumberFormat.decimalPattern(_numberLocaleOf(context)).format(value);
  }

  /// `4,500,000 USD` — the amount followed by the currency as the server
  /// sent it. With no currency, the amount alone.
  static String price(BuildContext context, num value, {String? currency}) {
    final amount = number(context, value);
    if (currency == null || currency.isEmpty) return amount;
    return '$amount $currency';
  }

  /// `10 min ago` · `2h ago` · `Yesterday` · `22 May`.
  ///
  /// Relative up to a day, then «yesterday», then a count of days up to a
  /// week, then the date itself — an item from three weeks ago reads better
  /// as its date than as «21 days ago».
  ///
  /// Each count picks its Arabic form: «منذ ساعتين», not «منذ 2 ساعات».
  static String relativeTime(BuildContext context, DateTime moment) {
    final elapsed = DateTime.now().difference(moment);

    if (elapsed.isNegative || elapsed.inMinutes < 1) return AppStrings.timeNow;
    if (elapsed.inMinutes < 60) {
      final minutes = elapsed.inMinutes;
      return AppStrings.timeMinutesAgo(minutes, number(context, minutes));
    }
    if (elapsed.inHours < 24) {
      final hours = elapsed.inHours;
      return AppStrings.timeHoursAgo(hours, number(context, hours));
    }
    if (elapsed.inDays == 1) return AppStrings.timeYesterday;
    if (elapsed.inDays < 7) {
      final days = elapsed.inDays;
      return AppStrings.timeDaysAgo(days, number(context, days));
    }
    return dayMonth(context, moment);
  }

  /// `28 May` — the day and month, for a date far enough away to need one.
  ///
  /// Month names come from `AppStrings`, not from `intl`'s date symbols: those
  /// need `initializeDateFormatting` per locale before the first use, and a
  /// month name is one word this app already translates.
  static String dayMonth(BuildContext context, DateTime moment) {
    return '${dayOfMonth(context, moment)} ${monthName(context, moment)}';
  }

  /// `28 May 2026` — a full date, e.g. under a headline.
  static String fullDate(BuildContext context, DateTime moment) {
    // The year is a label, not a quantity: no grouping separator in it.
    final year = NumberFormat('####', _numberLocaleOf(context)).format(moment.year);
    return '${dayMonth(context, moment)} $year';
  }

  /// `28` — the day alone, e.g. for a calendar block.
  static String dayOfMonth(BuildContext context, DateTime moment) {
    return number(context, moment.day);
  }

  /// `May` — the month alone, e.g. under the day in a calendar block.
  static String monthName(BuildContext context, DateTime moment) {
    return moment.month.monthNameFull;
  }

  /// A version, e.g. `1.0`, as it was written — the one place a version
  /// passes through, should the digit system above ever change.
  static String version(BuildContext context, String raw) => raw;

  /// «Author name · 5h ago» — the parts of one line, joined by « · ».
  ///
  /// Each part is wrapped in a first-strong isolate, so it takes its own
  /// direction and cannot pull its neighbour's characters into it. Names from
  /// the server are often in another script than the UI; without isolates an
  /// Arabic name beside «5h ago» swallows the «5». Empty parts are left
  /// out.
  static String line(List<String> parts) => parts
      .where((part) => part.isNotEmpty)
      .map(isolate)
      .join(' · ');

  /// [text] as one directional unit inside a line of another direction.
  static String isolate(String text) => '\u2068$text\u2069';

  /// `4:00 PM` — a wall-clock time on a twelve-hour clock.
  static String time(BuildContext context, DateTime moment) {
    final hour12 = moment.hour % 12 == 0 ? 12 : moment.hour % 12;
    final minutes = NumberFormat(
      '00',
      _numberLocaleOf(context),
    ).format(moment.minute);
    final marker = moment.hour < 12 ? AppStrings.timeAm : AppStrings.timePm;
    return '${number(context, hour12)}:$minutes $marker';
  }
}
