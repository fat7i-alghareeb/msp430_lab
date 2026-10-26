import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'int_extensions.dart';

typedef AppDateTimeFormatter =
    String Function(DateTime dateTime, {String locale});

/// ─────────────────────────────────────────────────────────────
/// Latin digit normalization
///
/// Intl uses locale-specific numerals (Arabic / Persian digits).
/// This extension forces all digits to English (0–9) while keeping
/// localized text (month names, AM/PM, etc.).
/// ─────────────────────────────────────────────────────────────
extension LatinDigits on String {
  static const _digitMap = {
    // Arabic-Indic digits
    '٠': '0',
    '١': '1',
    '٢': '2',
    '٣': '3',
    '٤': '4',
    '٥': '5',
    '٦': '6',
    '٧': '7',
    '٨': '8',
    '٩': '9',
    // Persian digits
    '۰': '0',
    '۱': '1',
    '۲': '2',
    '۳': '3',
    '۴': '4',
    '۵': '5',
    '۶': '6',
    '۷': '7',
    '۸': '8',
    '۹': '9',
  };

  /// Converts Arabic / Persian digits in this string to Latin digits.
  String toLatinDigits() {
    var result = this;
    _digitMap.forEach((key, value) {
      result = result.replaceAll(key, value);
    });
    return result;
  }
}

extension AppDateTimeFormatterExtensions on DateTime {
  /// Formats this value using a shared [AppDateTimeFormatter] signature.
  ///
  /// This is used by both the form widgets and the `DateTime` / ISO-string
  /// extension methods so you can swap formatting logic consistently.
  ///
  /// English digits are enforced regardless of locale.
  String formatWith(AppDateTimeFormatter formatter, {String locale = 'en_US'}) {
    return formatter(this, locale: locale).toLatinDigits();
  }
}

class _AppDateTimeFormatters {
  const _AppDateTimeFormatters._();

  static String ymd(DateTime dateTime, {String locale = 'en_US'}) {
    return DateFormat('yyyy-MM-dd', locale).format(dateTime).toLatinDigits();
  }

  static String time12(DateTime dateTime, {String locale = 'en_US'}) {
    return DateFormat('hh:mm a', locale).format(dateTime).toLatinDigits();
  }

  static String time12Compact(DateTime dateTime, {String locale = 'en_US'}) {
    return DateFormat('hh:mma', locale).format(dateTime).toLatinDigits();
  }

  static String time24(DateTime dateTime, {String locale = 'en_US'}) {
    return DateFormat('HH:mm', locale).format(dateTime).toLatinDigits();
  }

  static String fullDateTime(DateTime dateTime, {String locale = 'en_US'}) {
    final date = ymd(dateTime, locale: locale);
    final time = time12Compact(dateTime, locale: locale);
    return '($time) $date';
  }

  static String monthYearShort(DateTime dateTime, {String locale = 'en_US'}) {
    return '${dateTime.month.monthNameShort} ${dateTime.year}'.toLatinDigits();
  }

  static String year(DateTime dateTime, {String locale = 'en_US'}) {
    return '${dateTime.year}'.toLatinDigits();
  }

  static String monthDayFull(DateTime dateTime, {String locale = 'en_US'}) {
    return '${dateTime.month.monthNameFull} ${dateTime.day}'.toLatinDigits();
  }

  static String monthFull(DateTime dateTime, {String locale = 'en_US'}) {
    return dateTime.month.monthNameFull;
  }

  static String weekdayDayShort(DateTime dateTime, {String locale = 'en_US'}) {
    return '${dateTime.weekday.weekdayNameShort} ${dateTime.day}'
        .toLatinDigits();
  }
}

/// Formatting utilities for [DateTime] values.
///
/// These helpers focus on converting [DateTime] instances into
/// human-readable strings using common patterns.
extension DateTimeFormattingExtensions on DateTime {
  /// Formats this date/time using a custom ICU [pattern] and [locale].
  ///
  /// Example:
  /// `now.formatDateTime('yyyy-MM-dd HH:mm', locale: 'en_US');`
  ///
  /// English digits are enforced regardless of locale.
  String formatDateTime(String pattern, {String locale = 'en_US'}) {
    return DateFormat(pattern, locale).format(this).toLatinDigits();
  }

  /// Format as `yyyy-MM-dd`.
  ///
  /// Example: `DateTime(2025, 9, 22).toYmd()` → `'2025-09-22'`.
  String toYmd({String locale = 'en_US'}) =>
      _AppDateTimeFormatters.ymd(this, locale: locale);

  /// Format as `EEE d, MMM yyyy` (e.g. `Mon 22, Sep 2025`).
  String toWeekdayDayMonthYear({String locale = 'en_US'}) =>
      formatDateTime('EEE d, MMM yyyy', locale: locale);

  /// Format as `d-M-yyyy` (e.g. `22-9-2025`).
  String toDayMonthYearDash({String locale = 'en_US'}) =>
      formatDateTime('d-M-yyyy', locale: locale);

  /// 24-hour time `HH:mm`.
  String toTime24({String locale = 'en_US'}) =>
      _AppDateTimeFormatters.time24(this, locale: locale);

  /// 12-hour time `hh:mm a`.
  String toTime12({String locale = 'en_US'}) =>
      _AppDateTimeFormatters.time12(this, locale: locale);

  /// 12-hour time without a space before AM/PM: `hh:mma`.
  ///
  /// Example: `DateTime(2025, 9, 22, 10, 37).toTime12Compact()` → `'10:37AM'`.
  String toTime12Compact({String locale = 'en_US'}) =>
      _AppDateTimeFormatters.time12Compact(this, locale: locale);

  /// Equivalent of the old `fullDate` helper.
  ///
  /// Example output: `'(10:37AM) 2025-09-22'`.
  String toFullDateTime({String locale = 'en_US'}) =>
      _AppDateTimeFormatters.fullDateTime(this, locale: locale);

  /// Format as `MMM yyyy` using localized short month name.
  ///
  /// Example: `DateTime(2025, 9).toMonthYearShort()` → `'Sep 2025'`.
  String toMonthYearShort({String locale = 'en_US'}) =>
      _AppDateTimeFormatters.monthYearShort(this, locale: locale);

  /// Format as `yyyy`.
  ///
  /// Example: `DateTime(2025).toYearOnly()` → `'2025'`.
  String toYearOnly({String locale = 'en_US'}) =>
      _AppDateTimeFormatters.year(this, locale: locale);

  /// Format as `MMMM d` using localized full month name.
  ///
  /// Example: `DateTime(2025, 12, 21).toMonthDayFull()` → `'December 21'`.
  String toMonthDayFull({String locale = 'en_US'}) =>
      _AppDateTimeFormatters.monthDayFull(this, locale: locale);

  /// Format as `MMMM` using localized full month name.
  ///
  /// Example: `DateTime(2025, 12).toMonthFull()` → `'December'`.
  String toMonthFull({String locale = 'en_US'}) =>
      _AppDateTimeFormatters.monthFull(this, locale: locale);

  /// Format as `EEE d` using localized short weekday name.
  ///
  /// Example: `DateTime(2025, 9, 22).toWeekdayDayShort()` → `'Mon 22'`.
  String toWeekdayDayShort({String locale = 'en_US'}) =>
      _AppDateTimeFormatters.weekdayDayShort(this, locale: locale);

  /// Smart date/time similar to the old `timeWithSmartDate` helper.
  ///
  /// If the year matches `DateTime.now().year`, uses
  /// `MMM d, h:mm a`, otherwise `MMM d, y, h:mm a`. Output is
  /// lowercased for a chat-style look.
  String toSmartDateTime({String locale = 'en_US'}) {
    final now = DateTime.now();
    final sameYear = year == now.year;
    final pattern = sameYear ? 'MMM d, h:mm a' : 'MMM d, y, h:mm a';
    return formatDateTime(pattern, locale: locale).toLowerCase();
  }

  /// Formats a time range between this and [endTime].
  ///
  /// If [isLtr] is `true`, returns `"start - end"`, otherwise
  /// `"end - start"`.
  String formatTimeRange(
    DateTime endTime, {
    bool isLtr = true,
    bool is24 = false,
    String locale = 'en_US',
  }) {
    final format = is24 ? DateFormat('HH:mm', locale) : DateFormat.jm(locale);
    final startStr = format.format(this).toLatinDigits();
    final endStr = format.format(endTime).toLatinDigits();
    return isLtr ? '$startStr - $endStr' : '$endStr - $startStr';
  }
}

/// Calendar utilities for [DateTime] values.
///
/// These helpers focus on comparing and adjusting dates, without
/// producing ISO strings.
extension DateTimeCalendarExtensions on DateTime {
  /// Returns `true` if this and [other] fall on the same calendar day.
  ///
  /// Example:
  /// `DateTime(2025, 9, 22).isSameDay(DateTime(2025, 9, 22, 23))` → `true`.
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// `true` if this date is on the same day as `DateTime.now()`.
  bool get isToday => isSameDay(DateTime.now());

  /// `true` if this date is exactly one day before `DateTime.now()`.
  bool get isYesterday =>
      isSameDay(DateTime.now().subtract(const Duration(days: 1)));

  /// `true` if this date is exactly one day after `DateTime.now()`.
  bool get isTomorrow => isSameDay(DateTime.now().add(const Duration(days: 1)));

  /// Midnight at the start of the same calendar day.
  ///
  /// Example: `2025-09-22 10:37` → `2025-09-22 00:00`.
  DateTime get startOfDay => DateTime(year, month, day);

  /// Last millisecond of the same calendar day.
  ///
  /// Example: `2025-09-22 10:37` → `2025-09-22 23:59:59.999`.
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  /// Returns a copy of this [DateTime] with selected fields replaced.
  ///
  /// Example:
  /// `now.copyWith(hour: 0, minute: 0)`.
  DateTime copyWith({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? millisecond,
    int? microsecond,
  }) {
    return DateTime(
      year ?? this.year,
      month ?? this.month,
      day ?? this.day,
      hour ?? this.hour,
      minute ?? this.minute,
      second ?? this.second,
      millisecond ?? this.millisecond,
      microsecond ?? this.microsecond,
    );
  }

  /// Adds [days] to this [DateTime].
  ///
  /// Example: `now.addDays(7)`.
  DateTime addDays(int days) => add(Duration(days: days));

  /// Subtracts [days] from this [DateTime].
  ///
  /// Example: `now.subtractDays(1)`.
  DateTime subtractDays(int days) => subtract(Duration(days: days));
}

/// Safe parsing helpers for ISO-8601 date-time strings.
extension DateTimeParsingExtensions on String {
  /// Parses this ISO-8601 string into a [DateTime], or returns `null`
  /// if parsing fails.
  ///
  /// Example:
  /// `'2025-09-22T07:37:39.849Z'.toDateTimeOrNull()`.
  DateTime? toDateTimeOrNull() {
    try {
      return DateTime.parse(this);
    } catch (_) {
      return null;
    }
  }

  /// Parses this string and converts it to UTC, or returns `null` if
  /// parsing fails.
  DateTime? toUtcDateTimeOrNull() => toDateTimeOrNull()?.toUtc();

  /// Parses this string and converts it to local time, or returns
  /// `null` if parsing fails.
  DateTime? toLocalDateTimeOrNull() => toDateTimeOrNull()?.toLocal();
}

/// Convenience helpers for [DateTimeRange].
extension DateTimeRangeExtensions on DateTimeRange {
  /// `true` if [start] and [end] lie on the same calendar day.
  bool get isSingleDay => start.isSameDay(end);

  /// Formats the range as `yyyy-MM-dd{separator}yyyy-MM-dd`.
  String formatYmdRange({String separator = ' / '}) {
    return '${start.toYmd()}$separator${end.toYmd()}';
  }
}

/// Human-friendly formatting helpers for ISO-8601 date/time strings.
extension IsoDateStringFormatting on String {
  DateTime? _parseIsoToLocal() => toLocalDateTimeOrNull();

  /// Formats this ISO string using the shared
  /// [AppDateTimeFormatter] signature.
  String isoFormat(AppDateTimeFormatter formatter, {String locale = 'en_US'}) {
    final dt = _parseIsoToLocal();
    if (dt == null) return this;
    return dt.formatWith(formatter, locale: locale);
  }

  /// Equivalent of the old `fullDate` helper.
  String isoFullDate({String locale = 'en_US'}) {
    final dt = _parseIsoToLocal();
    if (dt == null) return this;
    return dt.toFullDateTime(locale: locale);
  }

  /// Short date like `Mon 22, Sep 2025`.
  String isoDatePretty({String locale = 'en_US'}) {
    final dt = _parseIsoToLocal();
    if (dt == null) return this;
    return dt.toWeekdayDayMonthYear(locale: locale);
  }

  /// 24-hour time `HH:mm`.
  String isoTime24({String locale = 'en_US'}) {
    final dt = _parseIsoToLocal();
    if (dt == null) return this;
    return dt.toTime24(locale: locale);
  }

  /// Smart date/time similar to the old `timeWithSmartDate`.
  String isoSmartDateTime({String locale = 'en_US'}) {
    final dt = _parseIsoToLocal();
    if (dt == null) return this;
    final now = DateTime.now();
    final sameYear = dt.year == now.year;
    final pattern = sameYear ? 'MMM d, h:mm a' : 'MMM d, y, h:mm a';
    return DateFormat(pattern, locale).format(dt).toLowerCase().toLatinDigits();
  }

  /// Day-month-year with dashes, e.g. `22-9-2025`.
  String isoDayMonthYearDash({String locale = 'en_US'}) {
    final dt = _parseIsoToLocal();
    if (dt == null) return this;
    return dt.toDayMonthYearDash(locale: locale);
  }
}
