import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/presentation/screens/ask_back/ask_back_chat_controller.dart';
import 'package:yakku/presentation/screens/ask_back/ask_back_format.dart';

const Color _night = Color(0xFF1F191C);

/// The chat's top bar: back, a pink avatar, "Anonymous friend", what they
/// picked, and a flag that opens the block flow ([onReport] null hides it).
class AskBackChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AskBackChatAppBar({
    super.key,
    required this.title,
    required this.subtitle,
    this.typing = false,
    this.onReport,
  });

  final String title;
  final String? subtitle;
  final bool typing;
  final VoidCallback? onReport;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: YakkuPalette.white,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: preferredSize.height,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: YakkuPalette.roseBorder)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
                color: YakkuPalette.textPrimary,
                tooltip: 'Back',
              ),
              const AnonymousAvatar(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: YakkuPalette.textPrimary,
                        fontSize: 17,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (typing || subtitle != null)
                      Text(
                        typing ? 'typing…' : subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: typing
                              ? YakkuPalette.primary
                              : YakkuPalette.textSecondary,
                          fontSize: 13,
                          height: 1.25,
                        ),
                      ),
                  ],
                ),
              ),
              if (onReport != null)
                IconButton(
                  onPressed: onReport,
                  icon: const Icon(Icons.outlined_flag_rounded),
                  color: YakkuPalette.textPrimary,
                  tooltip: 'Report',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A circle with two dots, the face of an anonymous person.
class AnonymousAvatar extends StatelessWidget {
  const AnonymousAvatar({
    super.key,
    this.size = 40,
    this.color = YakkuPalette.avatarPink,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final dot = size * 0.12;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 2; i++) ...[
            if (i == 1) SizedBox(width: size * 0.16),
            Container(
              width: dot,
              height: dot,
              decoration: const BoxDecoration(
                color: _night,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The grey rule banner above the thread: one question, one reply, then again.
class TurnRuleBanner extends StatelessWidget {
  const TurnRuleBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: YakkuPalette.chipSand,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '1 question \u2192 1 reply. Then it\u2019s your turn again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: YakkuPalette.textSecondary,
              fontSize: 13,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// A small centred label in the thread, like "They replied · your turn".
class ThreadPill extends StatelessWidget {
  const ThreadPill({
    super.key,
    required this.text,
    this.background = YakkuPalette.chipSand,
    this.foreground = YakkuPalette.textSecondary,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: foreground,
            fontSize: 13,
            height: 1.25,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// The green pill that shows the other person replied.
class YourTurnPill extends StatelessWidget {
  const YourTurnPill({super.key});

  @override
  Widget build(BuildContext context) {
    return const ThreadPill(
      text: 'They replied \u00B7 your turn',
      background: YakkuPalette.mint,
      foreground: YakkuPalette.forestGreen,
    );
  }
}

/// The pink pill under my last message while the other person has not replied.
class WaitingForReplyPill extends StatelessWidget {
  const WaitingForReplyPill({super.key});

  @override
  Widget build(BuildContext context) {
    return const ThreadPill(
      text: 'You can ask again once they reply.',
      background: YakkuPalette.pillPink,
      foreground: YakkuPalette.primary,
    );
  }
}

/// The voter's reason at the top of the thread. Askers see "THEIR REASON" on
/// the left; the reason giver sees "MY REASON" on the right. The text is read
/// live from the vote, so it may be gone.
class ReasonBlock extends StatelessWidget {
  const ReasonBlock({super.key, required this.reason, this.isMine = false});

  final String? reason;

  /// True when the signed-in user wrote this reason (the voter).
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final gone = reason == null || reason!.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 10),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: isMine ? 0 : 4,
                right: isMine ? 4 : 0,
                bottom: 6,
              ),
              child: Text(
                isMine ? 'MY REASON' : 'THEIR REASON',
                style: const TextStyle(
                  color: YakkuPalette.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.8,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: YakkuPalette.pillPink,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMine ? 20 : 6),
                  bottomRight: Radius.circular(isMine ? 6 : 20),
                ),
              ),
              child: Text(
                gone ? 'No longer available' : reason!,
                style: TextStyle(
                  color: YakkuPalette.textPrimary,
                  fontSize: 15,
                  height: 1.35,
                  fontStyle: gone ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One message: mine is dark on the right with "Sent · 2h ago", theirs is
/// white on the left.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.seen,
    required this.onRetry,
  });

  final ChatMessage message;
  final bool seen;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final mine = message.isMine;
    final failed = message.state == ChatMessageState.failed;
    final sending = message.state == ChatMessageState.sending;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: failed ? onRetry : null,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.78,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: mine ? _night : YakkuPalette.white,
                  border: mine
                      ? null
                      : Border.all(color: YakkuPalette.roseBorder, width: 1.2),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(mine ? 20 : 6),
                    bottomRight: Radius.circular(mine ? 6 : 20),
                  ),
                ),
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: mine ? YakkuPalette.white : YakkuPalette.textPrimary,
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ),
          if (mine)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: failed
                  ? GestureDetector(
                      onTap: onRetry,
                      child: const Text(
                        'Not sent · Tap to retry',
                        style: TextStyle(
                          color: YakkuPalette.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (sending)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.schedule_rounded,
                              size: 12,
                              color: YakkuPalette.textSecondary,
                            ),
                          ),
                        Text(
                          sending
                              ? 'Sending…'
                              : 'Sent · ${AskBackFormat.relative(message.createdAt)}',
                          style: const TextStyle(
                            color: YakkuPalette.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        if (seen)
                          const Text(
                            ' · Seen',
                            style: TextStyle(
                              color: YakkuPalette.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }
}

/// "3 messages left with this person" above the input; hidden when there is
/// no limit.
class MessagesLeftCaption extends StatelessWidget {
  const MessagesLeftCaption({super.key, required this.left});

  final int left;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$left ${left == 1 ? 'message' : 'messages'} left with this person',
      textAlign: TextAlign.start,
      style: const TextStyle(
        color: YakkuPalette.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// The input: a pill field whose pink border shows only while focused, and a
/// round raspberry send button.
class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSend,
    required this.maxLength,
    this.messagesLeft,
    this.hintText = 'Ask another...',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;
  final int maxLength;

  /// Messages left with this person; null when unlimited.
  final int? messagesLeft;

  /// Placeholder in the field. First ask uses a different line.
  final String hintText;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSend = widget.controller.text.trim().isNotEmpty;
    final focused = _focus.hasFocus;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        color: YakkuPalette.white,
        border: Border(top: BorderSide(color: YakkuPalette.roseBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.messagesLeft != null) ...[
            MessagesLeftCaption(left: widget.messagesLeft!),
            const SizedBox(height: 8),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                // One pill outline only: pink when focused, soft when not.
                // The TextField itself has no border (theme outline is cleared).
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: YakkuPalette.white,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: focused
                          ? YakkuPalette.primary
                          : YakkuPalette.roseBorder,
                      width: focused ? 1.5 : 1,
                    ),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      inputDecorationTheme: const InputDecorationTheme(
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                      ),
                    ),
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focus,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: widget.maxLength,
                      textCapitalization: TextCapitalization.sentences,
                      cursorColor: YakkuPalette.primary,
                      onChanged: widget.onChanged,
                      style: const TextStyle(
                        color: YakkuPalette.textPrimary,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        hintStyle: const TextStyle(
                          color: YakkuPalette.placeholder,
                        ),
                        counterText: '',
                        isDense: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 52,
                height: 52,
                child: IconButton.filled(
                  onPressed: canSend ? widget.onSend : null,
                  tooltip: 'Send',
                  style: IconButton.styleFrom(
                    backgroundColor: YakkuPalette.primary,
                    foregroundColor: YakkuPalette.white,
                    disabledBackgroundColor: YakkuPalette.primary.withValues(
                      alpha: 0.35,
                    ),
                    disabledForegroundColor: YakkuPalette.white,
                    shape: const CircleBorder(),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Replaces the composer when nobody can send: ended, paused, waiting for the
/// other person, or the other person left. [action] is the one button it can
/// carry (Reopen).
class ChatStatusBar extends StatelessWidget {
  const ChatStatusBar({
    super.key,
    required this.text,
    this.icon = Icons.lock_outline_rounded,
    this.actionLabel,
    this.onAction,
  });

  final String text;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        color: YakkuPalette.white,
        border: Border(top: BorderSide(color: YakkuPalette.roseBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: YakkuPalette.greyBlush,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16, color: YakkuPalette.textSecondary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: YakkuPalette.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  color: YakkuPalette.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A thin notice above the thread, for example while reconnecting.
class ChatBanner extends StatelessWidget {
  const ChatBanner({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      color: YakkuPalette.butter.withValues(alpha: 0.5),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

/// Bottom CTA when the free ask back on a card is used up: unlock to read the
/// rest and ask anyone back.
class FreeAskUsedBar extends StatelessWidget {
  const FreeAskUsedBar({
    super.key,
    required this.waitingReplies,
    required this.onUnlock,
    this.cardUnlocked = false,
    this.canSpendTicket = false,
    this.ticketsLeft,
  });

  /// Reasons still waiting on the card; null when the count is unknown.
  final int? waitingReplies;
  final VoidCallback onUnlock;

  /// Card already unlocked with a ticket/purchase: upgrade plans for more asks.
  final bool cardUnlocked;

  /// Owner has a plan ticket left and this card is not unlocked yet.
  final bool canSpendTicket;

  /// Remaining plan tickets; null means unlimited (Love).
  final int? ticketsLeft;

  String get _buttonLabel {
    if (cardUnlocked) return 'Show Yakku plans';
    if (canSpendTicket) {
      final tickets = ticketsLeft;
      if (tickets == null) return 'Unlock this card';
      if (tickets == 1) return 'Unlock this card \u00B7 1 ticket left';
      return 'Unlock this card \u00B7 $tickets tickets left';
    }
    return 'Unlock now';
  }

  @override
  Widget build(BuildContext context) {
    final count = waitingReplies;
    final String title;
    final String body;
    if (cardUnlocked) {
      title = 'Want more ask backs?';
      body = count == null
          ? 'Get a Yakku plan for more asks and to keep the conversation going.'
          : 'Get a Yakku plan for more asks across all $count waiting replies.';
    } else if (canSpendTicket) {
      title = 'Unlock this card';
      body = count == null
          ? 'Spend 1 plan ticket to ask back on every reason on this card. One ticket unlocks the card once.'
          : 'Spend 1 plan ticket to unlock every reason and keep asking back ($count waiting). One ticket per card.';
    } else {
      title = 'Your free ask back is used';
      body = count == null
          ? 'Unlock this card to read all waiting replies and ask back everyone.'
          : 'Unlock this card to read all $count waiting replies and ask back everyone.';
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: const BoxDecoration(
        color: YakkuPalette.white,
        border: Border(top: BorderSide(color: YakkuPalette.roseBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF3D6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  cardUnlocked
                      ? Icons.workspace_premium_outlined
                      : canSpendTicket
                      ? Icons.lock_open_rounded
                      : Icons.lock_outline_rounded,
                  color: const Color(0xFFC9A227),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: YakkuPalette.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: const TextStyle(
                        color: YakkuPalette.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton(
            key: const ValueKey('free-ask-unlock'),
            onPressed: onUnlock,
            style: FilledButton.styleFrom(
              backgroundColor: YakkuPalette.primary,
              foregroundColor: YakkuPalette.white,
              minimumSize: const Size.fromHeight(54),
              shape: const StadiumBorder(),
            ),
            child: Text(
              _buttonLabel,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
