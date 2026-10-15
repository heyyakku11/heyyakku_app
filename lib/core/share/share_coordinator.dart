import 'package:flutter/foundation.dart';
import 'package:yakku/core/share/share_payload.dart';
import 'package:yakku/core/share/share_platform_adapter.dart';
import 'package:yakku/core/share/share_platform_registry.dart';
import 'package:yakku/core/share/share_result.dart';

/// Runs a share action through the selected adapter and normalises outcomes.
/// Holds no UI concerns.
class ShareCoordinator {
  ShareCoordinator({SharePlatformRegistry? registry})
    : registry = registry ?? SharePlatformRegistry.standard();

  final SharePlatformRegistry registry;

  Future<List<SharePlatformAdapter>> availablePlatforms(SharePayload payload) =>
      registry.availableFor(payload);

  Future<ShareResult> share(
    SharePlatformId platform,
    SharePayload payload,
  ) async {
    final adapter = registry.byId(platform);
    if (adapter == null) {
      return const ShareUnsupported('This share option is not available.');
    }
    try {
      if (!await adapter.isAvailable(payload)) {
        return const ShareUnsupported('This share option is not available.');
      }
      return await adapter.share(payload);
    } catch (e, st) {
      debugPrint('Share via $platform failed: $e\n$st');
      return const ShareFailure(
        ShareFailureReason.unknown,
        userMessage: 'Something went wrong. Please try again.',
      );
    }
  }
}
