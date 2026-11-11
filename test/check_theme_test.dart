import 'package:flutter_test/flutter_test.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/checks/check_response.dart';
import 'package:yakku/data/models/checks/check_theme.dart';
import 'package:yakku/data/models/home/mirror_check.dart';

Map<String, dynamic> _check({Map<String, dynamic>? theme, String? type}) => {
  'id': 'c1',
  'weekStart': '2026-11-09',
  'title': 'Vibe Check',
  'question': 'Do you vibe?',
  'backgroundColor': '#ECE3FF',
  'options': [
    {'id': 'a', 'text': 'Yes'},
    {'id': 'b', 'text': 'No'},
  ],
  'used': false,
  'checkType': type,
  'theme': theme,
};

Map<String, dynamic> _theme(Map<String, dynamic> config) => {
  'checkType': 'VIBE_CHECK',
  'isLegacy': false,
  'config': config,
};

void main() {
  const full = {
    'heading': 'Vibe Check v2',
    'backgroundColor': '#112233',
    'labelColor': '#FFFFFF',
    'questionColor': '#EEEEEE',
    'accentColor': '#7B4DD0',
    'optionBackgroundColor': '#222222',
    'optionTextColor': '#FAFAFA',
  };

  test(
    'card is driven by the backend theme: heading, colors, sticker, options',
    () {
      final response = CheckResponse.fromJson(
        _check(theme: _theme(full), type: 'VIBE_CHECK'),
      );
      final card = MirrorCheck.fromCheck(response);

      expect(card.title, 'Vibe Check v2');
      expect(card.backgroundColor.toARGB32(), 0xFF112233);
      expect(card.foregroundColor.toARGB32(), 0xFFFFFFFF);
      expect(card.questionColor!.toARGB32(), 0xFFEEEEEE);
      expect(card.chipColor.toARGB32(), 0xFF222222);
      expect(card.optionTextColor!.toARGB32(), 0xFFFAFAFA);
      expect(card.sticker, 'No filter, Just truth');
      expect(card.checkType, 'VIBE_CHECK');
      expect(card.options.map((o) => o.label), ['Yes', 'No']);
    },
  );

  test('missing optional theme properties fall back and do not crash', () {
    final minimal = {
      'heading': 'Trust Check',
      'backgroundColor': '#DDF3E4',
      'questionColor': '#21191D',
      'accentColor': '#2E8B57',
    };
    final card = MirrorCheck.fromCheck(
      CheckResponse.fromJson(_check(theme: _theme(minimal))),
    );

    expect(card.stickerColor!.toARGB32(), 0xFF2E8B57); // sticker follows accent
    expect(card.chipColor, YakkuPalette.white);
    expect(card.backgroundGradient, isNull);
  });

  test('malformed colors and a one-stop gradient are ignored safely', () {
    final theme = CheckTheme.tryParse(
      _theme({
        ...full,
        'accentColor': 'nope',
        'backgroundGradient': ['#FFFFFF'],
      }),
    )!;

    expect(theme.accentColor, YakkuPalette.primary);
    expect(theme.backgroundGradient, isNull);
  });

  test('a two-stop gradient is kept', () {
    final theme = CheckTheme.tryParse(
      _theme({
        ...full,
        'backgroundGradient': ['#FFFFFF', '#000000'],
      }),
    )!;

    expect(theme.backgroundGradient, hasLength(2));
  });

  test(
    'existing checks without a theme still render from their flat fields',
    () {
      final card = MirrorCheck.fromCheck(CheckResponse.fromJson(_check()));

      expect(card.title, 'Vibe Check');
      expect(card.backgroundColor.toARGB32(), 0xFFECE3FF);
      expect(card.sticker, 'No filter, Just truth');
      expect(card.checkType, isNull);
    },
  );

  test('an unusable theme object falls back to the legacy fields', () {
    final card = MirrorCheck.fromCheck(
      CheckResponse.fromJson(_check(theme: {'x': 1})),
    );

    expect(card.title, 'Vibe Check');
    expect(card.backgroundColor.toARGB32(), 0xFFECE3FF);
  });
}
