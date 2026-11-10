import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/core/router/app_routes.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/ask_back/ask_back_models.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/ask_back/ask_back_format.dart';
import 'package:yakku/presentation/screens/ask_back/ask_back_inbox_controller.dart';
import 'package:yakku/presentation/screens/profile/my_cards_screen.dart';

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
      backgroundColor: YakkuPalette.cream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Back',
              icon: const FaIcon(
                FontAwesomeIcons.chevronLeft,
                size: 16,
                color: YakkuPalette.Ink,
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: Text(
                'My ask backs',
                style: TextStyle(
                  color: YakkuPalette.Ink,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Chats about a reason. 1 question \u2192 1 reply, open for 24 hours.',
                style: TextStyle(
                  color: YakkuPalette.textSecondary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
            Expanded(
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
                              child: _EmptyState(
                                onSeeCards: () =>
                                    Navigator.of(context).push<void>(
                                      MaterialPageRoute<void>(
                                        builder: (_) => const MyCardsScreen(),
                                      ),
                                    ),
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
                      itemCount:
                          inbox.items.length + (inbox.isLoadingMore ? 1 : 0),
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        indent: 72,
                        color: theme.dividerColor.withValues(alpha: 0.4),
                      ),
                      itemBuilder: (context, index) {
                        if (index >= inbox.items.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        return _ConversationTile(item: inbox.items[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown while the user has no ask-back chats yet.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onSeeCards});

  final VoidCallback onSeeCards;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: YakkuPalette.pinkWash,
            ),
            child: const FaIcon(
              FontAwesomeIcons.arrowRotateLeft,
              size: 28,
              color: YakkuPalette.Raspberry,
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'No ask backs yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: YakkuPalette.Ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'When a friend leaves a reason on your card, tap Ask back to chat '
            'about it. Anonymous both ways.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: YakkuPalette.textSecondary,
              fontSize: 14.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onSeeCards,
            style: FilledButton.styleFrom(
              backgroundColor: YakkuPalette.Ink,
              foregroundColor: YakkuPalette.white,
              minimumSize: const Size(0, 52),
              padding: const EdgeInsets.symmetric(horizontal: 30),
              shape: const StadiumBorder(),
            ),
            child: const Text(
              'See my cards',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ],
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
              color: unread
                  ? YakkuPalette.primary
                  : theme.colorScheme.onSurfaceVariant,
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
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
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
