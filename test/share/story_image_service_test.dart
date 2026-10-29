import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:yakku/core/share/story_image_service.dart';

Future<ui.Image> _decode(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  return (await codec.getNextFrame()).image;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  late StoryImageService service;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('story_test');
    service = StoryImageService(tempDir: () async => tmp);
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  testWidgets('renders a 1080x1920 PNG', (tester) async {
    await tester.runAsync(() async {
      final bytes = await service.renderPng(
        question: 'Would you rather?',
        options: ['Pizza', 'Tacos'],
      );
      final image = await _decode(bytes);
      expect(image.width, 1080);
      expect(image.height, 1920);
    });
  });

  testWidgets('very long text and options render without throwing', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final bytes = await service.renderPng(
        question: List.filled(80, 'Averyveryverylongword').join(' '),
        options: List.filled(6, 'An option label that is far too long ' * 4),
      );
      final image = await _decode(bytes);
      expect([image.width, image.height], [1080, 1920]);
    });
  });

  testWidgets('render writes a file and delete removes it', (tester) async {
    await tester.runAsync(() async {
      final file = await service.render(question: 'Hello?');
      expect(file.existsSync(), isTrue);
      expect(file.path.endsWith('.png'), isTrue);
      final second = await service.render(question: 'Again?');
      expect(file.existsSync(), isFalse, reason: 'stale file cleared');
      await service.delete(second);
      expect(second.existsSync(), isFalse);
    });
  });

  testWidgets('empty question throws StoryImageException', (tester) async {
    await tester.runAsync(() async {
      expect(
        () => service.render(question: '   '),
        throwsA(isA<StoryImageException>()),
      );
    });
  });
}
