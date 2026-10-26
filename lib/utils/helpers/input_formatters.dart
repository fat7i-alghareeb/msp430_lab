import 'package:flutter/services.dart';

class ArabicToEnglishDigitsFormatter extends TextInputFormatter {
  const ArabicToEnglishDigitsFormatter();

  static const Map<String, String> _map = <String, String>{
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

  static String convert(String input) {
    if (input.isEmpty) return input;
    final buffer = StringBuffer();
    for (var i = 0; i < input.length; i++) {
      final ch = input[i];
      buffer.write(_map[ch] ?? ch);
    }
    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final converted = convert(newValue.text);
    if (converted == newValue.text) return newValue;

    final selectionIndex = newValue.selection.extentOffset.clamp(
      0,
      converted.length,
    );
    return TextEditingValue(
      text: converted,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}

class AppNumericTextFormatter extends TextInputFormatter {
  const AppNumericTextFormatter({
    this.allowDecimal = false,
    this.allowNegative = false,
  });

  final bool allowDecimal;
  final bool allowNegative;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final converted = ArabicToEnglishDigitsFormatter.convert(newValue.text);

    var dotUsed = false;
    var minusUsed = false;

    final buffer = StringBuffer();
    for (var i = 0; i < converted.length; i++) {
      final ch = converted[i];
      if (ch == '-') {
        if (!allowNegative || minusUsed || buffer.isNotEmpty) continue;
        minusUsed = true;
        buffer.write(ch);
        continue;
      }

      if (ch == '.') {
        if (!allowDecimal || dotUsed) continue;
        dotUsed = true;
        buffer.write(ch);
        continue;
      }

      final isDigit = ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57;
      if (isDigit) {
        buffer.write(ch);
      }
    }

    final cleaned = buffer.toString();
    if (cleaned == newValue.text) return newValue;

    final selectionIndex = newValue.selection.extentOffset.clamp(
      0,
      cleaned.length,
    );
    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}

class AppStringOnlyFormatter extends TextInputFormatter {
  const AppStringOnlyFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final converted = ArabicToEnglishDigitsFormatter.convert(newValue.text);

    final buffer = StringBuffer();
    for (var i = 0; i < converted.length; i++) {
      final ch = converted[i];
      final isDigit = ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57;
      if (!isDigit) {
        buffer.write(ch);
      }
    }

    final cleaned = buffer.toString();
    if (cleaned == newValue.text) return newValue;

    final selectionIndex = newValue.selection.extentOffset.clamp(
      0,
      cleaned.length,
    );
    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
