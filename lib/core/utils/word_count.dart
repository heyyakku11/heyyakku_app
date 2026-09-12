import 'package:flutter/services.dart';

int wordCount(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return 0;
  return trimmed.split(RegExp(r'\s+')).length;
}

class MaxWordTextInputFormatter extends TextInputFormatter {
  const MaxWordTextInputFormatter(this.maxWords);

  final int maxWords;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (wordCount(newValue.text) <= maxWords) {
      return newValue;
    }
    return oldValue;
  }
}
