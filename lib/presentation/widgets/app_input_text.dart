import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yakku/presentation/widgets/app_text_field.dart';

class AppInputText extends StatelessWidget {
  const AppInputText({
    super.key,
    required this.controller,
    this.hintText,
    this.labelText,
    this.maxLines = 1,
    this.maxLength,
    this.maxWords,
    this.showCounter = false,
    this.textInputAction,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.suffixIcon,
    this.errorText,
    this.focusNode,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String? hintText;
  final String? labelText;
  final int maxLines;
  final int? maxLength;
  final int? maxWords;
  final bool showCounter;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool readOnly;
  final Widget? suffixIcon;
  final String? errorText;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      hintText: hintText,
      labelText: labelText,
      maxLines: maxLines,
      maxLength: maxLength,
      maxWords: maxWords,
      showCounter: showCounter,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      enabled: enabled,
      readOnly: readOnly,
      suffixIcon: suffixIcon,
      errorText: errorText,
      focusNode: focusNode,
      inputFormatters: inputFormatters,
    );
  }
}
