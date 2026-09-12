import '../../domain/enums/poll_options_type.dart';

class PollOptionModel {
  final String id;
  final PollOptionType type;
  final String? text;
  final String? imageUrl;
  final int sortOrder;
  final bool isCustom;

  const PollOptionModel({
    required this.id,
    required this.type,
    this.text,
    this.imageUrl,
    required this.sortOrder,
    required this.isCustom,
  });

  bool get hasText => text != null && text!.trim().isNotEmpty;

  bool get hasImageUrl => imageUrl != null && imageUrl!.trim().isNotEmpty;

  factory PollOptionModel.fromJson(Map<String, dynamic> json) {
    return PollOptionModel(
      id: json['id']?.toString() ?? '',
      type: PollOptionType.fromValue(_asInt(json['type'])),
      text: _asNullableString(json['text']),
      imageUrl: _asNullableString(json['imageUrl']),
      sortOrder: _asInt(json['sortOrder']),
      isCustom: _asBool(json['isCustom']),
    );
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
