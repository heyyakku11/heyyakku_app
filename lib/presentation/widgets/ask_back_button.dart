import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/router/app_routes.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/ask_back/ask_back_models.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';
import 'package:yakku/presentation/widgets/ask_back_unlock_sheet.dart';
import 'package:yakku/presentation/widgets/yakku_plans_sheet.dart';

/// "Ask back" pill beside a voter's reason. Tapping it starts the private
/// conversation for that vote (or opens the one that already exists).
///
/// When [locked] and the owner can spend a plan ticket ([AskBackAccess.canUnlock]),
/// tapping opens the ticket unlock sheet. Otherwise locked taps open Yakku plans.
/// [voteId] is the reason's id. Show it only for a reason with `canAskBack`.
class AskBackButton extends StatefulWidget {
  const AskBackButton({
    super.key,
    required this.voteId,
    this.background = YakkuPalette.pillPink,
    this.foreground = YakkuPalette.primary,
    this.compact = false,
    this.locked = false,
    this.cardAccess,
    this.contentType,
    this.contentId,
    this.onPurchaseFulfilled,
  });

  final String voteId;

  /// The reason's `askBackLocked`: true when asking back still needs an unlock
  /// (closed padlock shown). False once the card is open or a conversation
  /// exists for this reason.
  final bool locked;

  /// Owner access for this card. Drives ticket unlock vs plans, and the open
  /// padlock when the card is already unlocked.
  final AskBackAccess? cardAccess;

  /// Card context for permanent `this_card` in the plans sheet.
  final String? contentType;
  final String? contentId;

  /// Called after backend confirms a purchase or ticket unlock so parents can
  /// reload access / reasons.
  final Future<void> Function()? onPurchaseFulfilled;

  /// Pill fill and the colour of its icon and label.
  final Color background;
  final Color foreground;

  /// A smaller pill for use inside a reason card.
  final bool compact;

  bool get _showOpenLock =>
      cardAccess != null && cardAccess!.unlocked && !cardAccess!.paused;

  @override
  State<AskBackButton> createState() => _AskBackButtonState();
}

class _AskBackButtonState extends State<AskBackButton> {
  bool _busy = false;

  /// The server's answer when the card or reason is not unlocked for asking back.
  static const String _lockedCode = 'ASK_BACK_LOCKED';

  Future<void> _start() async {
    if (_busy) return;
    if (widget.locked) {
      final opened = await _resolveLock();
      if (!opened || !mounted) return;
      final onFulfilled = widget.onPurchaseFulfilled;
      if (onFulfilled != null) await onFulfilled();
      if (!mounted) return;
      await _startConversation();
      return;
    }

    await _startConversation();
  }

  /// Spends a plan ticket when available; otherwise opens Yakku plans.
  /// Returns true when the lock may be cleared (ticket spent or purchase paid).
  Future<bool> _resolveLock() async {
    final access = widget.cardAccess;
    if (access != null && access.canUnlock && !access.unlocked) {
      final unlocked = await showAskBackUnlockSheet(
        context,
        access: access,
        unlock: () => AppScope.of(context).askBack.unlock(widget.voteId),
      );
      return unlocked == true;
    }

    return showYakkuPlans(
      context,
      contentType: widget.contentType,
      contentId: widget.contentId,
    );
  }

  Future<void> _startConversation() async {
    final scope = AppScope.of(context);
    final router = GoRouter.of(context);
    setState(() => _busy = true);
    try {
      AskBackConversation? conversation;
      try {
        conversation = await scope.askBack.start(widget.voteId);
      } catch (error) {
        // The list can be stale: the server has the final say on the lock.
        final stale = DioErrorMapper.map(error).code == _lockedCode;
        if (!stale) rethrow;
        if (!mounted) return;
        final opened = await _resolveLock();
        if (!opened || !mounted) return;
        final onFulfilled = widget.onPurchaseFulfilled;
        if (onFulfilled != null) await onFulfilled();
        return;
      }
      if (!mounted) return;
      unawaited(router.push(AppRoutes.askBackChatLocation(conversation.id)));
    } catch (error) {
      AppToast.show(
        DioErrorMapper.map(
          error,
          fallback: 'Could not start the conversation',
        ).message,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: widget.background,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: _busy ? null : _start,
        child: Padding(
          padding: widget.compact
              ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_busy)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.foreground,
                  ),
                )
              else
                Icon(
                  Icons.reply_rounded,
                  size: widget.compact ? 14 : 16,
                  color: widget.foreground,
                ),
              SizedBox(width: widget.compact ? 6 : 8),
              Text(
                'Ask back',
                style: TextStyle(
                  color: widget.foreground,
                  fontSize: widget.compact ? 13 : 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (widget.locked) ...[
                SizedBox(width: widget.compact ? 6 : 8),
                Icon(
                  Icons.lock_outline_rounded,
                  size: widget.compact ? 13 : 14,
                  color: widget.foreground,
                ),
              ] else if (widget._showOpenLock) ...[
                SizedBox(width: widget.compact ? 6 : 8),
                Icon(
                  Icons.lock_open_rounded,
                  size: widget.compact ? 13 : 14,
                  color: widget.foreground,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
