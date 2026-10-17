class QuestionWorthAsking {
  const QuestionWorthAsking({required this.question, required this.options});

  final String question;
  final List<String> options;

  factory QuestionWorthAsking.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? const [];
    return QuestionWorthAsking(
      question: json['question']?.toString() ?? '',
      options: [
        for (final item in rawOptions)
          if (item is String)
            item.trim()
          else if (item is Map)
            (item['label']?.toString() ?? '').trim(),
      ].where((label) => label.isNotEmpty).toList(),
    );
  }
}
