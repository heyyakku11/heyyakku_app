import 'package:yakku/data/models/checks/check_theme.dart';

class CheckOptionResponse {
  const CheckOptionResponse({required this.id, required this.text});

  final String id;
  final String text;

  factory CheckOptionResponse.fromJson(Map<String, dynamic> json) {
    return CheckOptionResponse(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
    );
  }
}

/// A live check from `GET /api/v1/checks`.
class CheckResponse {
  const CheckResponse({
    required this.id,
    required this.weekStart,
    required this.title,
    required this.question,
    required this.backgroundColor,
    required this.options,
    required this.used,
    required this.theme,
    this.checkType,
  });

  final String id;
  final String weekStart;
  final String title;
  final String question;
  final String backgroundColor;
  final List<CheckOptionResponse> options;
  final bool used;

  /// Stable type code such as VIBE_CHECK; null for legacy checks.
  final String? checkType;

  /// What the card renders with. Built from the backend theme, or from the flat fields when absent.
  final CheckTheme theme;

  factory CheckResponse.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? const [];
    final title = json['title']?.toString() ?? '';
    final backgroundColor = json['backgroundColor']?.toString() ?? '';
    return CheckResponse(
      checkType: json['checkType']?.toString(),
      theme:
          CheckTheme.tryParse(json['theme']) ??
          CheckTheme.legacy(title: title, backgroundColor: backgroundColor),
      id: json['id']?.toString() ?? '',
      weekStart: json['weekStart']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      backgroundColor: json['backgroundColor']?.toString() ?? '',
      options: [
        for (final option in rawOptions.whereType<Map>())
          CheckOptionResponse.fromJson(Map<String, dynamic>.from(option)),
      ],
      used: json['used'] as bool? ?? false,
    );
  }
}
