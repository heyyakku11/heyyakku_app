import 'package:flutter/foundation.dart';
import 'package:yakku/data/datasources/ask_back_remote_data_source.dart';
import 'package:yakku/data/datasources/user_remote_data_source.dart';
import 'package:yakku/data/models/ask_back/ask_back_models.dart';
import 'package:yakku/data/models/user/user_profile_response.dart';
import 'package:yakku/data/repositories/personality_card_store.dart';
import 'package:yakku/presentation/screens/ask_back/ask_back_inbox_controller.dart';

/// Backend entitlement snapshot after payment fulfillment.
///
/// Never invents plan/access locally — every field comes from APIs.
class EntitlementSnapshot {
  const EntitlementSnapshot({
    this.currentPlan,
    this.cardAccess,
  });

  final UserPlanResponse? currentPlan;
  final AskBackAccess? cardAccess;
}

/// Reloads plan + shared stores (+ optional card access) from the backend.
///
/// Call after payment fulfillment. UI must keep using backend permission flags
/// (`reasonsRevealed`, `canUnlock`, `canSend`, …), not plan name alone.
abstract final class EntitlementRefresh {
  static Future<EntitlementSnapshot> afterFulfillment({
    required UserRemoteDataSource userRemote,
    required PersonalityCardStore personalityCards,
    AskBackRemoteDataSource? askBack,
    AskBackInboxController? askBackInbox,
    String? contentType,
    String? contentId,
  }) async {
    UserPlanResponse? plan;
    try {
      final me = await userRemote.getMe();
      plan = me.account.currentPlan;
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('[Payments] getMe after fulfill failed: $error\n$stack');
      }
    }

    try {
      await personalityCards.refresh();
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint(
          '[Payments] personality refresh after fulfill failed: $error\n$stack',
        );
      }
    }

    AskBackAccess? access;
    final type = contentType?.trim();
    final id = contentId?.trim();
    if (askBack != null &&
        type != null &&
        type.isNotEmpty &&
        id != null &&
        id.isNotEmpty) {
      try {
        access = await askBack.getCardAccess(type, id);
      } catch (error, stack) {
        if (kDebugMode) {
          debugPrint(
            '[Payments] card access refresh after fulfill failed: $error\n$stack',
          );
        }
      }
    }

    if (askBackInbox != null) {
      try {
        await askBackInbox.refresh();
      } catch (error, stack) {
        if (kDebugMode) {
          debugPrint(
            '[Payments] ask-back inbox refresh after fulfill failed: $error\n$stack',
          );
        }
      }
    }

    return EntitlementSnapshot(currentPlan: plan, cardAccess: access);
  }
}
