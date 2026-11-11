import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/ask_back/ask_back_models.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/ask_back/ask_back_chat_controller.dart';
import 'package:yakku/presentation/screens/ask_back/ask_back_format.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';

/// One private Ask Back conversation. The original question, the picked option
/// and the voter's reason sit at the top as context (read from the vote, never
/// repeated as a message). The other person is only an anonymous name.
class AskBackChatScreen extends StatefulWidget {
  const AskBackChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  State<AskBackChatScreen> createState() => _AskBackChatScreenState();
}

class _AskBackChatScreenState extends State<AskBackChatScreen>
    with WidgetsBindingObserver {
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

  Future<void> _confirmBlock() async {
    final reason = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block this conversation?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nobody can send messages until you lift the block. This only affects this conversation. You can tell us why (optional).',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reason,
              maxLength: 500,
              maxLines: 3,
              minLines: 1,
              decoration: const InputDecoration(hintText: 'Reason (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Block'),
          ),
        ],
      ),
    );
    final text = reason.text;
    reason.dispose();
    if (confirmed == true) {
      await _run(() => _chat!.block(reason: text));
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = _chat;
    if (chat == null) return const Scaffold(body: SizedBox.shrink());

    return ListenableBuilder(
      listenable: chat,
      builder: (context, _) {
        final conversation = chat.conversation;
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversation?.other.anonymousName ?? 'Ask back',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  chat.otherTyping ? 'typing…' : 'Anonymous',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: chat.otherTyping
                        ? YakkuPalette.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            actions: [if (conversation != null) _menu(conversation)],
          ),
          body: SafeArea(child: _body(chat, conversation)),
        );
      },
    );
  }

  Widget _menu(AskBackConversation conversation) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'mute':
            _run(() => _chat!.setMuted(!conversation.isMuted));
          case 'close':
            _run(_chat!.closeConversation);
          case 'block':
            _confirmBlock();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'mute',
          child: Text(
            conversation.isMuted
                ? 'Unmute notifications'
                : 'Mute notifications',
          ),
        ),
        if (conversation.status == AskBackStatus.active)
          const PopupMenuItem(
            value: 'close',
            child: Text('Close conversation'),
          ),
        if (conversation.status != AskBackStatus.blocked)
          const PopupMenuItem(value: 'block', child: Text('Block & report')),
      ],
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
    return Column(
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: chat.connected,
          builder: (context, connected, _) => connected
              ? const SizedBox.shrink()
              : const _Banner(text: 'Reconnecting… messages will catch up.'),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            // Messages (newest first), then the context card at the very top.
            itemCount: messages.length + 1,
            itemBuilder: (context, index) {
              if (index == messages.length) {
                return Column(
                  children: [
                    if (chat.isLoadingOlder)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    _ContextCard(conversation: conversation),
                  ],
                );
              }
              final message = messages[messages.length - 1 - index];
              return _Bubble(
                message: message,
                seen:
                    message.id != null && message.id == chat.lastSeenMessageId,
                onRetry: () => chat.retry(message),
              );
            },
          ),
        ),
        _composer(chat, conversation),
      ],
    );
  }

  Widget _composer(
    AskBackChatController chat,
    AskBackConversation conversation,
  ) {
    if (!chat.canSend) {
      return _ClosedBar(
        conversation: conversation,
        onReopen: () => _run(_chat!.reopenConversation),
        onUnblock: () => _run(_chat!.unblock),
      );
    }

    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _text,
              minLines: 1,
              maxLines: 5,
              maxLength: AskBackChatController.maxLength,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (value) {
                chat.onTextChanged(value);
                setState(() {});
              },
              decoration: const InputDecoration(
                hintText: 'Message',
                counterText: '',
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            onPressed: _text.text.trim().isEmpty ? null : _send,
            icon: const Icon(Icons.send_rounded),
            color: YakkuPalette.primary,
            tooltip: 'Send',
          ),
        ],
      ),
    );
  }
}

class _ContextCard extends StatelessWidget {
  const _ContextCard({required this.conversation});

  final AskBackConversation conversation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = conversation.context;
    final kind = info.contentType == 'check' ? 'Check' : 'Poll';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12, top: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: YakkuPalette.pillPink.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kind.toUpperCase(),
            style: const TextStyle(
              color: YakkuPalette.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          if (info.question != null) ...[
            const SizedBox(height: 4),
            Text(
              info.question!,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (info.selectedOption != null) ...[
            const SizedBox(height: 8),
            Text('Picked', style: theme.textTheme.bodySmall),
            Text(info.selectedOption!, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 8),
          Text('Their reason', style: theme.textTheme.bodySmall),
          Text(
            info.reason ?? 'No longer available',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: info.reason == null
                  ? FontStyle.italic
                  : FontStyle.normal,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Private. You both appear only by your Yakku names.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.seen,
    required this.onRetry,
  });

  final ChatMessage message;
  final bool seen;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mine = message.isMine;
    final failed = message.state == ChatMessageState.failed;
    final background = mine
        ? YakkuPalette.primary
        : theme.colorScheme.surfaceContainerHighest;
    final foreground = mine ? Colors.white : theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
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
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(mine ? 16 : 4),
                    bottomRight: Radius.circular(mine ? 4 : 16),
                  ),
                ),
                child: Text(
                  message.content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: foreground,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
            child: failed
                ? GestureDetector(
                    onTap: onRetry,
                    child: Text(
                      'Not sent · Tap to retry',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.state == ChatMessageState.sending)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.schedule_rounded,
                            size: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      Text(
                        message.state == ChatMessageState.sending
                            ? 'Sending…'
                            : AskBackFormat.messageTime(message.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (seen)
                        Text(
                          ' · Seen',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: YakkuPalette.primary,
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

/// Replaces the composer when nobody can send: closed, blocked or the other
/// person left.
class _ClosedBar extends StatelessWidget {
  const _ClosedBar({
    required this.conversation,
    required this.onReopen,
    required this.onUnblock,
  });

  final AskBackConversation conversation;
  final VoidCallback onReopen;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String text;
    if (conversation.other.isDeleted) {
      text = 'This person is no longer on Yakku.';
    } else if (conversation.status == AskBackStatus.blocked) {
      text = conversation.canUnblock
          ? 'You blocked this conversation.'
          : 'This conversation is blocked.';
    } else {
      text = 'This conversation is closed.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
          if (conversation.canReopen)
            TextButton(onPressed: onReopen, child: const Text('Reopen')),
          if (conversation.canUnblock)
            TextButton(onPressed: onUnblock, child: const Text('Unblock')),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      color: Colors.amber.withValues(alpha: 0.25),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}
