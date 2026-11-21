import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yakku/core/router/app_routes.dart';
import 'package:yakku/core/storage/card_results_celebration_store.dart';
import 'package:yakku/data/models/notification/app_notification.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/card_results_screen.dart';
import 'package:yakku/presentation/screens/personality/personality_navigation.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';

/// Opens the screen a notification points at. Shared by a tap in the Activity
/// list and a tap on the push notification itself.
Future<void> openNotificationTarget(
  BuildContext context,
  NotificationTarget target, {
  CardResultsCelebrationStore? celebrationStore,
}) async {
  try {
    if (target.isAskBackConversation) {
      final conversationId = target.conversationId;
      if (conversationId == null || conversationId.isEmpty) {
        throw StateError('Conversation not found');
      }
      await context.push(AppRoutes.askBackChatLocation(conversationId));
      return;
    }

    if (target.isPersonality) {
      final store = AppScope.of(context).personalityCards;
      await store.refresh();
      final card = store.card;
      if (card == null) throw StateError('Card not found');
      if (!context.mounted) return;
      await openPersonalityFromNotification(
        context,
        target,
        card,
        store.traits,
        celebrationStore: celebrationStore,
      );
      return;
    }

    final contentId = target.contentId;
    if (contentId == null || contentId.isEmpty) {
      throw StateError('Card not found');
    }

    var celebrateReady = target.isCardResultsReady;
    if (celebrateReady) {
      final store = celebrationStore ?? CardResultsCelebrationStore();
      celebrateReady = await store.claimFirstWatch(contentId);
    }

    final Widget screen;
    if (target.isCheck) {
      final checks = await AppScope.of(context).checkApi.getMyChecks();
      final check = checks
          .where((candidate) => candidate.id == contentId)
          .firstOrNull;
      if (check == null) throw StateError('Check not found');
      screen = CardResultsScreen.check(
        check: check,
        celebrateReady: celebrateReady,
      );
    } else {
      screen = CardResultsScreen.byPollId(
        pollId: contentId,
        celebrateReady: celebrateReady,
      );
    }
    if (!context.mounted) return;
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => screen));
  } catch (_) {
    if (!context.mounted) return;
    AppToast.show(
      target.isAskBackConversation
          ? 'This conversation is no longer available'
          : 'This card is no longer available',
    );
  }
}
