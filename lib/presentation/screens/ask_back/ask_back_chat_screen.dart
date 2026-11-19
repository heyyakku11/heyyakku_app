import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/ask_back/ask_back_models.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/ask_back/ask_back_chat_controller.dart';
import 'package:yakku/presentation/screens/ask_back/ask_back_chat_widgets.dart';
import 'package:yakku/presentation/screens/ask_back/block_report_sheets.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';
import 'package:yakku/presentation/widgets/yakku_plans_sheet.dart';

/// One private Ask Back conversation. The picked option sits in the header and
/// the voter's reason at the top of the thread as context (read from the vote,
/// never repeated as a message). The other person is only "Anonymous friend".
///
/// The chat follows a turn rule: the asker sends first, the other person
/// replies once, then the asker again. The server decides whose turn it is and
/// how many messages are left; this screen only shows it. The flag in the
/// header blocks and reports the other person, which ends the chat.
class AskBackChatScreen extends StatefulWidget {
  const AskBackChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  State<AskBackChatScreen> createState() => _AskBackChatScreenState();
}

class _AskBackChatScreenState extends State<AskBackChatScreen>
    with WidgetsBindingObserver {
  static const String _friend = 'Anonymous friend';

  final TextEditingController _text = TextEditingController();
  final ScrollController _scroll = ScrollController();
  AskBackChatController? _chat;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(() {
      // The list is reversed, so the "top" (older messages) is the max extent.
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 240) {
        _chat?.loadOlder();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_chat != null) return;
    final scope = AppScope.of(context);
    _chat = AskBackChatController(
      conversationId: widget.conversationId,
      remote: scope.askBack,
      realtime: scope.askBackRealtime,
      inbox: scope.askBackInbox,
    )..init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Messages count as read only while the app is in front.
    _chat?.setForeground(state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chat?.dispose();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final chat = _chat;
    if (chat == null) return;
    if (chat.send(_text.text)) {
      _text.clear();
      if (_scroll.hasClients) {
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
      setState(() {});
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      AppToast.show(
        DioErrorMapper.map(error, fallback: 'Something went wrong').message,
      );
    }
  }

  Future<void> _report() async {
    final chat = _chat;
    if (chat == null) return;
    final blocked = await showBlockFlow(
      context,
      submit: (reason) => chat.block(reason: reason),
    );
    if (blocked) AppToast.show('Blocked. Thanks for telling us.');
  }

  @override
  Widget build(BuildContext context) {
    final chat = _chat;
    if (chat == null) return const Scaffold(body: SizedBox.shrink());

    return ListenableBuilder(
      listenable: chat,
      builder: (context, _) {
        final conversation = chat.conversation;
        final blocked = conversation?.status == AskBackStatus.blocked;
        final option = conversation?.context.selectedOption;
        return Scaffold(
          backgroundColor: YakkuPalette.cream,
          appBar: AskBackChatAppBar(
            title: blocked ? '$_friend · blocked' : _friend,
            subtitle: option == null || option.isEmpty
                ? null
                : 'Picked "$option"',
            typing: chat.otherTyping,
            onReport: conversation == null || blocked ? null : _report,
          ),
          body: SafeArea(child: _body(chat, conversation)),
        );
      },
    );
  }

  Widget _body(AskBackChatController chat, AskBackConversation? conversation) {
    if (chat.isLoading && conversation == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (conversation == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                chat.error ?? 'Could not open this conversation',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: chat.load,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    final messages = chat.messages;
    final tail = _tail(chat, conversation, messages);
    final extra = tail == null ? 0 : 1;
    return Column(
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: chat.connected,
          builder: (context, connected, _) => connected
              ? const SizedBox.shrink()
              : const ChatBanner(text: 'Reconnecting… messages will catch up.'),
        ),
        const TurnRuleBanner(),
        Expanded(
          // The thread starts at the top of the screen and grows downward.
          // The list is reversed so a long one stays on the newest message,
          // and shrink-wrapped so a short one sits at the top, not the bottom.
          child: Align(
            alignment: Alignment.topCenter,
            child: ListView.builder(
              controller: _scroll,
              reverse: true,
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              // Newest first: the tag under the last message, the messages,
              // then the reason at the very top of the thread. The only tags
              // here are "They replied · your turn" and "You can ask again
              // once they reply."
              itemCount: messages.length + extra + 1,
              itemBuilder: (context, index) {
                if (tail != null && index == 0) return tail;
                final position = index - extra;
                if (position == messages.length) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (chat.isLoadingOlder)
                        const Padding(
                          padding: EdgeInsets.all(8),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      ReasonBlock(
                        reason: conversation.context.reason,
                        isMine: !conversation.isAsker,
                      ),
                    ],
                  );
                }
                final message = messages[messages.length - 1 - position];
                return ChatBubble(
                  message: message,
                  seen:
                      message.id != null &&
                      message.id == chat.lastSeenMessageId,
                  onRetry: () => chat.retry(message),
                );
              },
            ),
          ),
        ),
        _composer(chat, conversation),
      ],
    );
  }

  /// The only tags in the thread, under the newest message: the green "They
  /// replied · your turn" when it is my turn after a reply, or the pink "You
  /// can ask again once they reply." while I wait. Anything else (ended,
  /// paused, blocked) is said by the bar at the bottom.
  Widget? _tail(
    AskBackChatController chat,
    AskBackConversation conversation,
    List<ChatMessage> messages,
  ) {
    if (messages.isEmpty) return null;
    Widget spaced(Widget child) => Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: child,
    );

    final last = messages.last;
    if (chat.canSend && chat.turn == AskBackTurn.me && !last.isMine) {
      return spaced(const YourTurnPill());
    }
    final waiting =
        !chat.canSend &&
        chat.turn == AskBackTurn.them &&
        conversation.status == AskBackStatus.active &&
        !conversation.other.isDeleted &&
        !chat.isPaused;
    if (waiting && last.isMine) return spaced(const WaitingForReplyPill());
    return null;
  }

  Widget _composer(
    AskBackChatController chat,
    AskBackConversation conversation,
  ) {
    if (chat.canSend) {
      return ChatComposer(
        controller: _text,
        maxLength: AskBackChatController.maxLength,
        messagesLeft: chat.messagesLeft,
        hintText: chat.messages.isEmpty
            ? 'Ask them something...'
            : 'Ask another...',
        onSend: _send,
        onChanged: (value) {
          chat.onTextChanged(value);
          setState(() {});
        },
      );
    }

    if (conversation.other.isDeleted) {
      return const ChatStatusBar(text: 'This person is no longer on Yakku.');
    }
    if (conversation.status == AskBackStatus.blocked) {
      return const ChatStatusBar(text: 'Chat ended');
    }
    if (chat.isPaused) {
      return const ChatStatusBar(text: 'Chat paused');
    }
    // Ask-back message limit reached: show the unlock CTA instead of the input.
    final limitHit =
        conversation.isAsker &&
        (chat.turn == AskBackTurn.done ||
            (chat.messagesLeft != null &&
                chat.messagesLeft! <= 0 &&
                !chat.canSend));
    if (limitHit) {
      return FreeAskUsedBar(
        waitingReplies: conversation.waitingReplies,
        onUnlock: () => showYakkuPlans(context),
      );
    }
    if (conversation.status == AskBackStatus.closed) {
      return ChatStatusBar(
        text: 'Chat ended',
        actionLabel: conversation.canReopen ? 'Reopen' : null,
        onAction: conversation.canReopen
            ? () => _run(chat.reopenConversation)
            : null,
      );
    }
    if (chat.turn == AskBackTurn.done) {
      return const ChatStatusBar(text: 'Chat ended');
    }
    return const ChatStatusBar(text: 'Waiting for their reply');
  }
}
