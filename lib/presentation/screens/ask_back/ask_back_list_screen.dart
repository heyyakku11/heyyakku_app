import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/core/router/app_routes.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/ask_back/ask_back_models.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/ask_back/ask_back_format.dart';
import 'package:yakku/presentation/screens/ask_back/ask_back_inbox_controller.dart';

/// The user's Ask Back conversations: each one is a private chat about a vote's
/// reason, with the other person shown only by their anonymous name.
class AskBackListScreen extends StatefulWidget {
  const AskBackListScreen({super.key});

  @override
  State<AskBackListScreen> createState() => _AskBackListScreenState();
}

class _AskBackListScreenState extends State<AskBackListScreen> {
  final ScrollController _scroll = ScrollController();
  AskBackInboxController? _inbox;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final inbox = AppScope.of(context).askBackInbox;
    if (_inbox != inbox) {
      _inbox = inbox;
      inbox.start();
    }
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 240) {
      _inbox?.loadMore();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inbox = AppScope.of(context).askBackInbox;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ask back')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: inbox,
          builder: (context, _) {
            if (!inbox.hasLoaded && inbox.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!inbox.hasLoaded && inbox.error != null) {
              return _Message(
                icon: Icons.cloud_off_rounded,
                title: 'Could not load conversations',
                body: inbox.error!,
                action: FilledButton(
                  onPressed: inbox.refresh,
                  child: const Text('Try again'),
                ),
              );
            }
            if (inbox.items.isEmpty) {
              return RefreshIndicator(
                onRefresh: inbox.refresh,
                child: LayoutBuilder(
                  builder: (context, constraints) => ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: constraints.maxHeight,
                        child: const _Message(
                          icon: Icons.forum_outlined,
                          title: 'No conversations yet',
                          body:
                              'When you ask someone back about their reason, the private chat shows up here.',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: inbox.refresh,
              child: ListView.separated(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: inbox.items.length + (inbox.isLoadingMore ? 1 : 0),
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  indent: 72,
                  color: theme.dividerColor.withValues(alpha: 0.4),
                ),
                itemBuilder: (context, index) {
                  if (index >= inbox.items.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  }
                  return _ConversationTile(item: inbox.items[index]);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.item});

  final AskBackListItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unread = item.unreadCount > 0;
    final last = item.lastMessage;
    final preview = last == null
        ? 'Say hello'
        : (last.isMine ? 'You: ${last.preview}' : last.preview);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screen,
        vertical: 6,
      ),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: YakkuPalette.pillPink,
        child: Text(
          item.other.anonymousName.isEmpty
              ? '?'
              : item.other.anonymousName.characters.first.toUpperCase(),
          style: const TextStyle(
            color: YakkuPalette.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              item.other.anonymousName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            AskBackFormat.listTime(last?.createdAt ?? item.lastActivityAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: unread ? YakkuPalette.primary : theme.colorScheme.onSurfaceVariant,
              fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          children: [
            if (item.status != AskBackStatus.active) ...[
              _StatusChip(status: item.status),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                preview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: unread
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (item.isMuted)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(
                  Icons.notifications_off_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            if (unread)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: const BoxDecoration(
                  color: YakkuPalette.primary,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: Text(
                  item.unreadCount > 99 ? '99+' : '${item.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
      onTap: () => context.push(AppRoutes.askBackChatLocation(item.id)),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final AskBackStatus status;

  @override
  Widget build(BuildContext context) {
    final blocked = status == AskBackStatus.blocked;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: (blocked ? Colors.red : Colors.grey).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        blocked ? 'Blocked' : 'Closed',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: blocked ? Colors.red.shade700 : Colors.grey.shade700,
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
