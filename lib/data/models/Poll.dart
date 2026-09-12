import 'package:yakku/data/models/poll_option.dart';
import 'package:yakku/domain/enums/poll_answer_type.dart';
import 'package:yakku/domain/enums/poll_status.dart';

class PollModel {
  final String id;
  final String question;
  final String? categoryId;
  final PollAnswerType answerType;
  final bool allowCustomOption;
  final PollStatus status;
  final List<PollOptionModel> options;

  const PollModel({
    required this.id,
    required this.question,
    this.categoryId,
    required this.answerType,
    required this.allowCustomOption,
    required this.status,
    required this.options,
  });

  bool get isMultipleChoice => answerType == PollAnswerType.multipleChoice;

  List<PollOptionModel> get standardOptions =>
      options.where((option) => !option.isCustom).toList(growable: false);

  PollOptionModel? get customOption {
    for (final option in options) {
      if (option.isCustom) return option;
    }
    return null;
  }

  bool get shouldShowCustomOption => allowCustomOption || customOption != null;

  factory PollModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final optionsJson = rawOptions is List ? rawOptions : const [];

    final options =
        optionsJson
            .whereType<Map>()
            .map(
              (option) =>
                  PollOptionModel.fromJson(Map<String, dynamic>.from(option)),
            )
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return PollModel(
      id: json['id']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      categoryId: _asNullableString(json['categoryId']),
      answerType: PollAnswerType.fromValue(
        _asInt(json['answerType'], fallback: 1),
      ),
      allowCustomOption: _asBool(json['allowCustomOption']),
      status: PollStatus.fromValue(_asInt(json['status'])),
      options: List<PollOptionModel>.unmodifiable(options),
    );
  }

  static List<PollModel> listFromJson(List<dynamic> json) {
    return json
        .whereType<Map>()
        .map((item) => PollModel.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    switch (value.toLowerCase()) {
      case 'true':
      case '1':
        return true;
      case 'false':
      case '0':
        return false;
    }
  }
  return fallback;
}

String? _asNullableString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}
