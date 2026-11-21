import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yakku/core/deep_link/deep_link_service.dart';
import 'package:yakku/core/deep_link/poll_deep_link.dart';

const _host = 'heyyakku-web.vercel.app';
const _code = 'AbC123xyz9';

void main() {
  group('DeepLinkService.linkFromUri', () {
    AppDeepLink? parse(String url) => DeepLinkService.linkFromUri(
      Uri.parse(url),
      allowedHosts: const {_host},
    );

    test('accepts https poll links on an allowed host', () {
      const poll = AppDeepLink(AppDeepLinkKind.poll, _code);
      expect(parse('https://$_host/vote/$_code'), poll);
      expect(parse('https://$_host/vote/$_code?x=1#y'), poll);
    });

    test('accepts https personality links on an allowed host', () {
      const card = AppDeepLink(AppDeepLinkKind.personality, _code);
      expect(parse('https://$_host/personality?share_code=$_code'), card);
      expect(parse('https://$_host/personality/$_code'), card);
      expect(parse('https://$_host/personality/$_code?x=1#y'), card);
    });

    test('accepts the custom scheme', () {
      expect(
        parse('yakku:///vote/$_code'),
        const AppDeepLink(AppDeepLinkKind.poll, _code),
      );
      expect(
        parse('yakku:///personality?share_code=$_code'),
        const AppDeepLink(AppDeepLinkKind.personality, _code),
      );
      expect(
        parse('yakku:///personality/$_code'),
        const AppDeepLink(AppDeepLinkKind.personality, _code),
      );
    });

    test('maps each kind to its in-app location', () {
      expect(parse('https://$_host/vote/$_code')!.location, '/vote/$_code');
      expect(
        parse('https://$_host/personality?share_code=$_code')!.location,
        '/personality/$_code',
      );
      expect(
        parse('https://$_host/personality/$_code')!.location,
        '/personality/$_code',
      );
    });

    test('rejects other hosts, schemes and paths', () {
      for (final bad in [
        'http://$_host/vote/$_code',
        'http://$_host/personality/$_code',
        'https://other.example.com/vote/$_code',
        'https://other.example.com/personality/$_code',
        'https://$_host.evil.com/vote/$_code',
        'https://$_host.evil.com/personality/$_code',
        'https://$_host/poll/$_code',
        'https://$_host/personalities/$_code',
        'https://$_host/vote/',
        'https://$_host/personality/',
        'https://$_host/vote/$_code/extra',
        'https://$_host/personality/$_code/extra',
        'https://$_host/vote/bad',
        'https://$_host/personality/bad',
        'other:///vote/$_code',
        'other:///personality/$_code',
      ]) {
        expect(parse(bad), isNull, reason: bad);
      }
    });
  });

  group('DeepLinkService', () {
    test('queues links until ready, then delivers in order', () async {
      final controller = StreamController<Uri>();
      final received = <AppDeepLink>[];
      final service = DeepLinkService(
        uriStream: controller.stream,
        allowedHosts: const {_host},
      )..initialize(onLink: received.add);

      controller
        ..add(Uri.parse('https://$_host/vote/AAAAAA1'))
        ..add(Uri.parse('https://evil.example.com/vote/BBBBBB2'))
        ..add(Uri.parse('yakku:///vote/CCCCCC3'))
        ..add(Uri.parse('https://$_host/personality/EEEEEE5'))
        ..add(Uri.parse('https://evil.example.com/personality/FFFFFF6'));
      await Future<void>.delayed(Duration.zero);
      expect(received, isEmpty);

      service.markReady();
      expect(received, const [
        AppDeepLink(AppDeepLinkKind.poll, 'AAAAAA1'),
        AppDeepLink(AppDeepLinkKind.poll, 'CCCCCC3'),
        AppDeepLink(AppDeepLinkKind.personality, 'EEEEEE5'),
      ]);

      controller
        ..add(Uri.parse('https://$_host/vote/DDDDDD4'))
        ..add(Uri.parse('yakku:///personality/GGGGGG7'));
      await Future<void>.delayed(Duration.zero);
      expect(received.skip(3), const [
        AppDeepLink(AppDeepLinkKind.poll, 'DDDDDD4'),
        AppDeepLink(AppDeepLinkKind.personality, 'GGGGGG7'),
      ]);

      await service.dispose();
      await controller.close();
    });
  });
}
