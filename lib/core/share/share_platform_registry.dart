import 'package:yakku/core/share/adapters/copy_link_share_adapter.dart';
import 'package:yakku/core/share/adapters/facebook_share_adapter.dart';
import 'package:yakku/core/share/adapters/instagram_share_adapter.dart';
import 'package:yakku/core/share/adapters/snapchat_share_adapter.dart';
import 'package:yakku/core/share/adapters/whatsapp_share_adapter.dart';
import 'package:yakku/core/share/share_payload.dart';
import 'package:yakku/core/share/share_platform_adapter.dart';

/// Central list of share destinations, in display order.
///
/// To add a platform: implement [SharePlatformAdapter] and add it to
/// [SharePlatformRegistry.standard] (or call [register]). The share sheet and
/// coordinator need no changes.
class SharePlatformRegistry {
  SharePlatformRegistry([Iterable<SharePlatformAdapter> adapters = const []]) {
    adapters.forEach(register);
  }

  /// WhatsApp + Copy Link.
  factory SharePlatformRegistry.standard() => SharePlatformRegistry(const [
    WhatsAppShareAdapter(),
    InstagramShareAdapter(InstagramDestination.inbox),
    InstagramShareAdapter(InstagramDestination.story),
    SnapchatShareAdapter(),
    FacebookShareAdapter(),
    CopyLinkShareAdapter(),
  ]);

  final Map<SharePlatformId, SharePlatformAdapter> _adapters = {};

  List<SharePlatformAdapter> get all => List.unmodifiable(_adapters.values);

  /// Registers or replaces the adapter with the same id.
  void register(SharePlatformAdapter adapter) =>
      _adapters[adapter.id] = adapter;

  SharePlatformAdapter? byId(SharePlatformId id) => _adapters[id];

  /// Adapters that report themselves available for [payload].
  Future<List<SharePlatformAdapter>> availableFor(SharePayload payload) async {
    final results = await Future.wait(
      all.map((a) async => await a.isAvailable(payload) ? a : null),
    );
    return results.whereType<SharePlatformAdapter>().toList(growable: false);
  }
}
