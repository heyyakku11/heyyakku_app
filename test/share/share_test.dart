import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakku/core/share/adapters/copy_link_share_adapter.dart';
import 'package:yakku/core/share/adapters/whatsapp_share_adapter.dart';
import 'package:yakku/core/share/share_coordinator.dart';
import 'package:yakku/core/share/share_payload.dart';
import 'package:yakku/core/share/share_platform_adapter.dart';
import 'package:yakku/core/share/share_platform_registry.dart';
import 'package:yakku/core/share/share_result.dart';
import 'package:yakku/presentation/widgets/share_poll_sheet.dart';

const _id = '0cbe6985-219f-4ed7-b780-b93fe2be5fe1';
const _question = 'If I told you a secret, how long before someone else knows?';

SharePayload _payload() =>
    SharePayload.create(pollId: _id, question: _question);

class _FakeAdapter extends SharePlatformAdapter {
  _FakeAdapter(this.id, {this.available = true, this.result});

  @override
  final SharePlatformId id;
  final bool available;
  final ShareResult? result;
  int calls = 0;

  @override
  String get displayName => id.value;
  @override
  IconData get icon => Icons.star;
  @override
  Color get brandColor => Colors.blue;
  @override
  Future<bool> isAvailable(SharePayload payload) async => available;
  @override
  Future<ShareResult> share(SharePayload payload) async {
    calls++;
    return result ?? const ShareSuccess();
  }
}

void main() {
  group('SharePayload', () {
    test('builds canonical https URL from poll id', () {
      final p = _payload();
      expect(p.url.toString(), 'https://heyyakku-web.vercel.app/vote/$_id');
      expect(p.question, _question);
      expect(p.pollId, _id);
    });

    test('rejects invalid ids, empty question, private polls', () {
      SharePayloadError? err(void Function() f) {
        try {
          f();
        } on SharePayloadException catch (e) {
          return e.error;
        }
        return null;
      }

      expect(
        err(() => SharePayload.create(pollId: '', question: 'q')),
        SharePayloadError.invalidPollId,
      );
      expect(
        err(() => SharePayload.create(pollId: 'abc', question: 'q')),
        SharePayloadError.invalidPollId,
      );
      expect(
        err(() => SharePayload.create(pollId: _id, question: '  ')),
        SharePayloadError.emptyQuestion,
      );
      expect(
        err(
          () =>
              SharePayload.create(pollId: _id, question: 'q', isPublic: false),
        ),
        SharePayloadError.notPublic,
      );
    });

    test('requires an https, non-local website URL', () {
      for (final base in [
        'http://heyyakku-web.vercel.app',
        'https://localhost:7086',
        '',
      ]) {
        expect(
          () => SharePayload.create(
            pollId: _id,
            question: 'q',
            websiteBaseUrl: base,
          ),
          throwsA(isA<SharePayloadException>()),
          reason: base,
        );
      }
    });

    test('tolerates a trailing slash on the base URL', () {
      final p = SharePayload.create(
        pollId: _id,
        question: 'q',
        websiteBaseUrl: 'https://example.com/',
      );
      expect(p.url.toString(), 'https://example.com/vote/$_id');
    });
  });

  group('WhatsAppShareAdapter', () {
    test('formats and encodes the message', () {
      final p = _payload();
      expect(
        WhatsAppShareAdapter.formatMessage(p),
        '$_question\n\nVote here: https://heyyakku-web.vercel.app/vote/$_id',
      );
      final uri = WhatsAppShareAdapter.buildUri(p);
      expect(uri.host, 'wa.me');
      expect(
        uri.queryParameters['text'],
        WhatsAppShareAdapter.formatMessage(p),
      );
      expect(uri.toString(), contains('%0A%0AVote%20here'));
    });

    test('success when launcher opens', () async {
      Uri? launched;
      final adapter = WhatsAppShareAdapter(
        launcher: (uri) async {
          launched = uri;
          return true;
        },
      );
      expect(await adapter.share(_payload()), isA<ShareSuccess>());
      expect(launched?.host, 'wa.me');
    });

    test('failure when launcher returns false or throws', () async {
      final falseAdapter = WhatsAppShareAdapter(launcher: (_) async => false);
      expect(await falseAdapter.share(_payload()), isA<ShareFailure>());
      final throwing = WhatsAppShareAdapter(
        launcher: (_) async => throw Exception('boom'),
      );
      final r = await throwing.share(_payload());
      expect(r, isA<ShareFailure>());
      expect((r as ShareFailure).userMessage, isNot(contains('boom')));
    });
  });

  group('CopyLinkShareAdapter', () {
    test('copies exactly the canonical URL and reports success', () async {
      String? copied;
      final adapter = CopyLinkShareAdapter(writer: (t) async => copied = t);
      final r = await adapter.share(_payload());
      expect(copied, 'https://heyyakku-web.vercel.app/vote/$_id');
      expect(r, isA<ShareSuccess>());
      expect((r as ShareSuccess).feedbackMessage, 'Link copied');
    });

    test('reports clipboard failure', () async {
      final adapter = CopyLinkShareAdapter(
        writer: (_) async => throw Exception('no clipboard'),
      );
      final r = await adapter.share(_payload());
      expect(r, isA<ShareFailure>());
      expect((r as ShareFailure).reason, ShareFailureReason.clipboardFailed);
    });
  });

  group('Registry and coordinator', () {
    test('standard registry has WhatsApp and Copy link', () {
      final ids = SharePlatformRegistry.standard().all.map((a) => a.id);
      expect(ids, [SharePlatformId.whatsapp, SharePlatformId.copyLink]);
    });

    test('invokes the selected adapter only', () async {
      final a = _FakeAdapter(const SharePlatformId('a'));
      final b = _FakeAdapter(const SharePlatformId('b'));
      final c = ShareCoordinator(registry: SharePlatformRegistry([a, b]));
      expect(await c.share(b.id, _payload()), isA<ShareSuccess>());
      expect([a.calls, b.calls], [0, 1]);
    });

    test('unknown, unavailable and throwing adapters yield results', () async {
      final off = _FakeAdapter(const SharePlatformId('off'), available: false);
      final c = ShareCoordinator(registry: SharePlatformRegistry([off]));
      expect(
        await c.share(const SharePlatformId('nope'), _payload()),
        isA<ShareUnsupported>(),
      );
      expect(await c.share(off.id, _payload()), isA<ShareUnsupported>());
      expect(off.calls, 0);

      final bad = CopyLinkShareAdapter(writer: (_) async => throw 'x');
      final c2 = ShareCoordinator(registry: SharePlatformRegistry([bad]));
      expect(await c2.share(bad.id, _payload()), isA<ShareFailure>());
    });

    test('new adapters register without coordinator changes', () async {
      final registry = SharePlatformRegistry.standard();
      final extra = _FakeAdapter(const SharePlatformId('telegram'));
      registry.register(extra);
      final c = ShareCoordinator(registry: registry);
      expect(registry.all.length, 3);
      await c.share(extra.id, _payload());
      expect(extra.calls, 1);
    });
  });

  group('SharePollSheet', () {
    Future<void> open(WidgetTester tester, ShareCoordinator coordinator) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showSharePollSheet(
                  context,
                  payload: _payload(),
                  coordinator: coordinator,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows question and supported options', (tester) async {
      await open(tester, ShareCoordinator());
      expect(find.text('Share poll'), findsOneWidget);
      expect(find.text(_question), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('Copy link'), findsOneWidget);
    });

    testWidgets('success closes sheet and shows feedback', (tester) async {
      String? copied;
      final coordinator = ShareCoordinator(
        registry: SharePlatformRegistry([
          CopyLinkShareAdapter(writer: (t) async => copied = t),
        ]),
      );
      await open(tester, coordinator);
      await tester.tap(find.text('Copy link'));
      await tester.pumpAndSettle();
      expect(copied, contains('/vote/$_id'));
      expect(find.text('Share poll'), findsNothing);
      expect(find.text('Link copied'), findsOneWidget);
    });

    testWidgets('failure keeps sheet open with an inline error', (
      tester,
    ) async {
      final coordinator = ShareCoordinator(
        registry: SharePlatformRegistry([
          CopyLinkShareAdapter(writer: (_) async => throw 'x'),
        ]),
      );
      await open(tester, coordinator);
      await tester.tap(find.text('Copy link'));
      await tester.pumpAndSettle();
      expect(find.text('Share poll'), findsOneWidget);
      expect(find.textContaining("Couldn't copy"), findsOneWidget);
      expect(find.text('Link copied'), findsNothing);
    });

    testWidgets('repeated taps run the action once', (tester) async {
      var calls = 0;
      final coordinator = ShareCoordinator(
        registry: SharePlatformRegistry([
          CopyLinkShareAdapter(
            writer: (_) async {
              calls++;
              await Future<void>.delayed(const Duration(milliseconds: 200));
            },
          ),
        ]),
      );
      await open(tester, coordinator);
      await tester.tap(find.text('Copy link'));
      await tester.pump();
      await tester.tap(find.byType(InkWell).last, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(calls, 1);
    });

    testWidgets('close button dismisses', (tester) async {
      await open(tester, ShareCoordinator());
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Share poll'), findsNothing);
    });
  });
}
