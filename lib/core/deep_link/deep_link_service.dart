// Named parameters cannot be private, so they are assigned by hand.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:collection';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:yakku/core/constants/api_constants.dart';
import 'package:yakku/core/deep_link/poll_deep_link.dart';

/// Listens for incoming shared links (polls and personality cards) and hands
/// them to the app.
///
/// The `app_links` stream emits the link the app was launched with as well as
/// links that arrive while it runs. Flutter's own deep-link handling is turned
/// off (`flutter_deeplinking_enabled` in AndroidManifest.xml and
/// `FlutterDeepLinkingEnabled` in Info.plist) so this service is the only
/// thing that navigates for a link.
///
/// Start it early with [initialize]. Links that arrive before the router can
/// navigate are queued and delivered, in order, once [markReady] is called.
class DeepLinkService {
  DeepLinkService({
    AppLinks? appLinks,
    Stream<Uri>? uriStream,
    Set<String>? allowedHosts,
  }) : _uriStream = uriStream,
       _appLinks = appLinks,
       _allowedHosts = allowedHosts ?? defaultAllowedHosts;

  /// Web hosts that serve `/vote/{shareCode}` and `/personality/{shareCode}`,
  /// per build environment. These match the `appLinkHost` placeholders in
  /// android/app/build.gradle.kts.
  static const _devHost = 'heyyakku-web-git-develop-heyyakku33-9072.vercel.app';
  static const _stagingHost =
      'heyyakku-web-git-staging-heyyakku33-9072.vercel.app';
  static const _productionHost = 'heyyakku-web.vercel.app';

  /// Custom scheme used by the web "Open in app" button:
  /// `yakku:///vote/{code}` and `yakku:///personality/{code}`.
  static const customScheme = 'yakku';

  static Set<String> get defaultAllowedHosts =>
      switch (ApiConstants.environment) {
        'dev' => const {_devHost},
        'staging' => const {_stagingHost},
        'production' => const {_productionHost},
        _ => const {},
      };

  final AppLinks? _appLinks;
  final Stream<Uri>? _uriStream;
  final Set<String> _allowedHosts;

  final Queue<AppDeepLink> _pending = Queue<AppDeepLink>();
  StreamSubscription<Uri>? _subscription;
  void Function(AppDeepLink link)? _onLink;
  bool _ready = false;

  /// Starts listening. Safe to call once; later calls are ignored.
  void initialize({required void Function(AppDeepLink link) onLink}) {
    if (_subscription != null) return;
    _onLink = onLink;
    final stream = _uriStream ?? (_appLinks ?? AppLinks()).uriLinkStream;
    _subscription = stream.listen(
      _handleUri,
      onError: (Object error) {
        debugPrint('[DeepLink] stream error: $error');
      },
    );
  }

  /// Call once the router can navigate. Delivers links queued during startup.
  void markReady() {
    if (_ready) return;
    _ready = true;
    while (_pending.isNotEmpty) {
      _deliver(_pending.removeFirst());
    }
  }

  void _handleUri(Uri uri) {
    final link = linkFromUri(uri, allowedHosts: _allowedHosts);
    if (link == null) {
      debugPrint('[DeepLink] ignored link: ${uri.scheme}://${uri.host}');
      return;
    }
    if (!_ready) {
      _pending.add(link);
      return;
    }
    _deliver(link);
  }

  void _deliver(AppDeepLink link) => _onLink?.call(link);

  /// Returns the link this app should open, or `null`.
  ///
  /// Accepts `https://<allowed host>/vote/{shareCode}`,
  /// `https://<allowed host>/personality/{shareCode}` and the custom scheme
  /// forms `yakku:///vote/{shareCode}` and `yakku:///personality/{shareCode}`.
  /// Query strings and fragments are ignored.
  @visibleForTesting
  static AppDeepLink? linkFromUri(
    Uri uri, {
    required Set<String> allowedHosts,
  }) {
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'https') {
      if (!allowedHosts.contains(uri.host.toLowerCase())) return null;
    } else if (scheme != customScheme) {
      return null;
    }
    return PollDeepLink.fromPath(uri);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _onLink = null;
    _pending.clear();
  }
}
