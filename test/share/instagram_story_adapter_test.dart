import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakku/core/share/adapters/instagram_share_adapter.dart';
import 'package:yakku/core/share/instagram_story_channel.dart';
import 'package:yakku/core/share/share_payload.dart';
import 'package:yakku/core/share/share_result.dart';
import 'package:yakku/core/share/story_image_service.dart';

const _code = 'aB3dE5gH7k';
const _url = 'https://heyyakku-web.vercel.app/vote/$_code';

SharePayload _payload() => SharePayload.create(
  shareCode: _code,
  question: 'Pizza or tacos?',
  options: ['Pizza', 'Tacos'],
);

typedef _Sharer =
    Future<InstagramStoryOutcome> Function({
      required String imagePath,
      required String linkText,
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> calls;
  late File image;

  setUp(() {
    calls = [];
    image = File('${Directory.systemTemp.path}/story_adapter_test.png')
      ..writeAsBytesSync([1, 2, 3]);
  });
  tearDown(() {
    if (image.existsSync()) image.deleteSync();
  });

  InstagramShareAdapter adapter({
    InstagramDestination destination = InstagramDestination.story,
    Future<File> Function(String, List<String>)? render,
    _Sharer? sharer,
  }) => InstagramShareAdapter(
    destination,
    clipboard: (text) async => calls.add('clip:$text'),
    launcher: (uri) async {
      calls.add('launch:$uri');
      return true;
    },
    renderStoryImage:
        render ??
        (q, o) async {
          calls.add('render:$q|${o.join(',')}');
          return image;
        },
    storySharer:
        sharer ??
        ({required imagePath, required linkText}) async {
          calls.add('native:$imagePath|$linkText');
          return InstagramStoryOutcome.opened;
        },
  );

  test(
    'copies the share URL, renders with options, passes the image to native',
    () async {
      final result = await adapter().share(_payload());

      expect(result, isA<ShareSuccess>());
      expect(calls, [
        'clip:$_url',
        'render:Pizza or tacos?|Pizza,Tacos',
        'native:${image.path}|$_url',
      ]);
      expect(
        image.existsSync(),
        isTrue,
        reason: 'Instagram reads the file after launch; it must not be deleted',
      );
    },
  );

  test('success message does not claim a Link sticker was created', () async {
    final result = await adapter().share(_payload()) as ShareSuccess;
    expect(result.feedbackMessage, contains('Add a Link sticker'));
  });

  test('Instagram not installed gives a failure', () async {
    final result = await adapter(
      sharer: ({required imagePath, required linkText}) async =>
          InstagramStoryOutcome.notInstalled,
    ).share(_payload());

    expect(result, isA<ShareFailure>());
    expect(calls.where((c) => c.startsWith('launch:')), isEmpty);
  });

  test('native error is reported as a failure, not a false success', () async {
    final result = await adapter(
      sharer: ({required imagePath, required linkText}) async =>
          throw PlatformException(code: 'no_handler'),
    ).share(_payload());

    expect(result, isA<ShareFailure>());
    expect((result as ShareFailure).userMessage, contains('no_handler'));
    expect(calls.where((c) => c.startsWith('launch:')), isEmpty);
  });

  test('image render failure is reported as a failure', () async {
    final result = await adapter(
      render: (_, _) async => throw const StoryImageException('boom'),
    ).share(_payload());

    expect(result, isA<ShareFailure>());
    expect(calls, ['clip:$_url']);
  });

  test('inbox destination is unchanged and never renders an image', () async {
    final result = await adapter(
      destination: InstagramDestination.inbox,
    ).share(_payload());

    expect(result, isA<ShareSuccess>());
    expect(calls, [
      'clip:$_url',
      'launch:https://www.instagram.com/direct/inbox/',
    ]);
  });

  testWidgets(
    'real StoryImageService output (1080x1920 PNG) reaches the native sharer',
    (tester) async {
      await tester.runAsync(() async {
        final tmp = Directory.systemTemp.createTempSync('story_adapter');
        addTearDown(() => tmp.deleteSync(recursive: true));
        final service = StoryImageService(tempDir: () async => tmp);

        String? seenPath;
        Uint8List? seenBytes;
        final real = InstagramShareAdapter(
          InstagramDestination.story,
          clipboard: (_) async {},
          renderStoryImage: (q, o) => service.render(question: q, options: o),
          storySharer: ({required imagePath, required linkText}) async {
            seenPath = imagePath;
            seenBytes = File(imagePath).readAsBytesSync();
            return InstagramStoryOutcome.opened;
          },
        );

        expect(await real.share(_payload()), isA<ShareSuccess>());

        final codec = await ui.instantiateImageCodec(seenBytes!);
        final decoded = (await codec.getNextFrame()).image;
        expect([decoded.width, decoded.height], [1080, 1920]);
        expect(seenPath, contains('yakku_story'));
      });
    },
  );

  group('InstagramStoryChannel', () {
    const channel = MethodChannel('com.example.yakku/instagram_story');
    tearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    void mock(Future<Object?> Function(MethodCall) handler) =>
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, handler);

    test('sends path, link and app id to shareToStory', () async {
      MethodCall? seen;
      mock((call) async {
        seen = call;
        return 'opened';
      });

      final outcome = await const InstagramStoryChannel().shareToStory(
        imagePath: '/tmp/a.png',
        linkText: _url,
        appId: '123',
      );

      expect(outcome, InstagramStoryOutcome.opened);
      expect(seen!.method, 'shareToStory');
      expect(seen!.arguments, {
        'imagePath': '/tmp/a.png',
        'linkText': _url,
        'appId': '123',
      });
    });

    test('maps notInstalled and rejects unknown results', () async {
      mock((_) async => 'notInstalled');
      expect(
        await const InstagramStoryChannel().shareToStory(
          imagePath: 'p',
          linkText: 'l',
        ),
        InstagramStoryOutcome.notInstalled,
      );

      mock((_) async => 'weird');
      expect(
        const InstagramStoryChannel().shareToStory(
          imagePath: 'p',
          linkText: 'l',
        ),
        throwsA(isA<PlatformException>()),
      );
    });
  });

  test('placeholder Meta App ID is reported as not configured', () {
    expect(InstagramStoryConfig.isConfigured, isFalse);
  });
}
