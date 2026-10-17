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
    required this.sticker,
    required this.options,
    required this.used,
  });

  final String id;
  final String weekStart;
  final String title;
  final String question;
  final String backgroundColor;
  final String sticker;
  final List<CheckOptionResponse> options;
  final bool used;

  factory CheckResponse.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? const [];
    return CheckResponse(
      id: json['id']?.toString() ?? '',
      weekStart: json['weekStart']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      backgroundColor: json['backgroundColor']?.toString() ?? '',
      sticker: json['sticker']?.toString() ?? '',
      options: [
        for (final option in rawOptions.whereType<Map>())
          CheckOptionResponse.fromJson(Map<String, dynamic>.from(option)),
      ],
      used: json['used'] as bool? ?? false,
    );
  }
}
