import 'package:yakku/data/models/home/mirror_check.dart';
import 'package:yakku/data/models/home/question_worth_asking.dart';

class HomeFeedResponse {
  const HomeFeedResponse({
    required this.mirrorChecks,
    required this.questionsWorthAsking,
  });

  final List<MirrorCheck> mirrorChecks;
  final List<QuestionWorthAsking> questionsWorthAsking;

  factory HomeFeedResponse.fromJson(Map<String, dynamic> json) {
    final rawChecks = json['mirrorChecks'] as List<dynamic>? ?? const [];
    final rawQuestions =
        json['questionsWorthAsking'] as List<dynamic>? ?? const [];

    return HomeFeedResponse(
      mirrorChecks: [
        for (final item in rawChecks)
          if (item is Map)
            MirrorCheck.fromJson(Map<String, dynamic>.from(item)),
      ],
      questionsWorthAsking: [
        for (final item in rawQuestions)
          if (item is Map)
            QuestionWorthAsking.fromJson(Map<String, dynamic>.from(item)),
      ],
    );
  }
}
