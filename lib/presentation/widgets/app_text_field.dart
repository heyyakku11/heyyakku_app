import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/core/utils/word_count.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
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
    this.style,
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
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final formatters = <TextInputFormatter>[
      ...?inputFormatters,
      if (maxWords != null) MaxWordTextInputFormatter(maxWords!),
    ];

    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      readOnly: readOnly,
      maxLines: maxLines,
      maxLength: maxWords != null ? null : maxLength,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      inputFormatters: formatters.isEmpty ? null : formatters,
      style: style,
      buildCounter: showCounter && maxWords == null && maxLength != null
          ? (
              context, {
              required currentLength,
              required isFocused,
              required maxLength,
            }) {
              if (!isFocused && currentLength == 0) {
                return const SizedBox.shrink();
              }
              return Text(
                '$currentLength/$maxLength',
                style: Theme.of(context).textTheme.bodySmall,
              );
            }
          : showCounter && maxWords != null
          ? (
              context, {
              required currentLength,
              required isFocused,
              required maxLength,
            }) {
              final count = wordCount(controller.text);
              return Text(
                '$count/$maxWords words',
                style: Theme.of(context).textTheme.bodySmall,
              );
            }
          : null,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        errorText: errorText,
        alignLabelWithHint: maxLines > 1,
        counterText: showCounter ? null : '',
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }
}
