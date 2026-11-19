import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/core/router/app_routes.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/ask_back/ask_back_models.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/ask_back/ask_back_chat_widgets.dart';
import 'package:yakku/presentation/screens/ask_back/ask_back_format.dart';
import 'package:yakku/presentation/screens/ask_back/ask_back_inbox_controller.dart';
import 'package:yakku/presentation/screens/profile/my_cards_screen.dart';

/// Which slice of the inbox the segmented control shows.
enum _AskBackTab { all, yourTurn, waiting, ended }

/// The user's Ask Back conversations, grouped by turn: your turn, waiting, ended.
class AskBackListScreen extends StatefulWidget {
  const AskBackListScreen({super.key});

  @override
  State<AskBackListScreen> createState() => _AskBackListScreenState();
}

class _AskBackListScreenState extends State<AskBackListScreen> {
  final ScrollController _scroll = ScrollController();
  AskBackInboxController? _inbox;
  _AskBackTab _tab = _AskBackTab.all;

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

  List<AskBackListItem> _filter(List<AskBackListItem> items) {
    return switch (_tab) {
      _AskBackTab.all => items,
      _AskBackTab.yourTurn => items.where((item) => item.isYourTurn).toList(),
      _AskBackTab.waiting => items.where((item) => item.isWaiting).toList(),
      _AskBackTab.ended => items.where((item) => item.isEnded).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final inbox = AppScope.of(context).askBackInbox;

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
              padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Text(
                'Chats about a reason. 1 question \u2192 1 reply.',
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

                  final all = inbox.items;
                  final yourTurn = all.where((item) => item.isYourTurn).length;
                  final waiting = all.where((item) => item.isWaiting).length;
                  final ended = all.where((item) => item.isEnded).length;
                  final visible = _filter(all);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TabRow(
                        tab: _tab,
                        all: all.length,
                        yourTurn: yourTurn,
                        waiting: waiting,
                        ended: ended,
                        onChanged: (tab) => setState(() => _tab = tab),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: inbox.refresh,
                          child: visible.isEmpty
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(32),
                                  children: [
                                    const SizedBox(height: 80),
                                    Text(
                                      _emptyTabLabel(_tab),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: YakkuPalette.textSecondary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : ListView(
                                  controller: _scroll,
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    8,
                                    16,
                                    24,
                                  ),
                                  children: [
                                    ..._sections(visible),
                                    if (inbox.isLoadingMore)
                                      const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _emptyTabLabel(_AskBackTab tab) => switch (tab) {
    _AskBackTab.yourTurn => 'Nothing needs a reply right now.',
    _AskBackTab.waiting => 'You are not waiting on anyone.',
    _AskBackTab.ended => 'No ended chats yet.',
    _AskBackTab.all => 'No ask backs yet.',
  };

  /// On All: ACTIVE then ENDED. On a filter tab: one flat list.
  List<Widget> _sections(List<AskBackListItem> items) {
    if (_tab != _AskBackTab.all) {
      return [
        for (final item in items) ...[
          _ConversationCard(item: item),
          const SizedBox(height: 12),
        ],
      ];
    }

    final active = items.where((item) => !item.isEnded).toList();
    final ended = items.where((item) => item.isEnded).toList();
    return [
      if (active.isNotEmpty) ...[
        _SectionHeader(label: 'ACTIVE', count: active.length),
        for (final item in active) ...[
          _ConversationCard(item: item),
          const SizedBox(height: 12),
        ],
      ],
      if (ended.isNotEmpty) ...[
        _SectionHeader(label: 'ENDED', count: ended.length),
        for (final item in ended) ...[
          _ConversationCard(item: item),
          const SizedBox(height: 12),
        ],
      ],
    ];
  }
}

class _TabRow extends StatelessWidget {
  const _TabRow({
    required this.tab,
    required this.all,
    required this.yourTurn,
    required this.waiting,
    required this.ended,
    required this.onChanged,
  });

  final _AskBackTab tab;
  final int all;
  final int yourTurn;
  final int waiting;
  final int ended;
  final ValueChanged<_AskBackTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final chips = <(_AskBackTab, String)>[
      (_AskBackTab.all, 'All $all'),
      (_AskBackTab.yourTurn, 'Your turn $yourTurn'),
      (_AskBackTab.waiting, 'Waiting $waiting'),
      (_AskBackTab.ended, 'Ended $ended'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _TabChip(
              label: chips[i].$2,
              selected: tab == chips[i].$1,
              onTap: () => onChanged(chips[i].$1),
            ),
          ],
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? YakkuPalette.Ink : YakkuPalette.white,
      shape: const StadiumBorder(
        side: BorderSide(color: YakkuPalette.roseBorder),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? YakkuPalette.white : YakkuPalette.Ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Text(
        '$label \u00B7 $count',
        style: const TextStyle(
          color: YakkuPalette.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({required this.item});

  final AskBackListItem item;

  @override
  Widget build(BuildContext context) {
    final yourTurn = item.isYourTurn;
    final option = item.context.selectedOption;
    final title = (item.context.title?.trim().isNotEmpty ?? false)
        ? item.context.title!
        : 'Question';
    final tag = '${item.isAsker ? 'YOUR' : 'THEIR'} ${title.toUpperCase()}';
    final name = item.isAsker
        ? (item.other.anonymousName.isEmpty
              ? 'Anonymous friend'
              : item.other.anonymousName)
        : 'Someone you answered';
    final picked = option == null || option.isEmpty
        ? null
        : (item.isAsker
              ? 'Picked \u2018$option\u2019'
              : 'You picked \u2018$option\u2019');
    final last = item.lastMessage;
    final preview = last == null
        ? 'Say hello'
        : (last.isMine ? 'You: ${last.preview}' : 'They: ${last.preview}');
    final tint = _AvatarTint.of(item.id);
    final tagColors = _TagColors.of(item);

    return Material(
      color: YakkuPalette.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: yourTurn ? YakkuPalette.Ink : YakkuPalette.roseBorder,
          width: yourTurn ? 2 : 1.2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => context.push(AppRoutes.askBackChatLocation(item.id)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: tagColors.fill,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: tagColors.ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (item.isEnded)
                    Text(
                      AskBackFormat.listTime(item.lastActivityAt),
                      style: const TextStyle(
                        color: YakkuPalette.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnonymousAvatar(size: 44, color: tint),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: YakkuPalette.Ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (picked != null)
                          Text(
                            picked,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: YakkuPalette.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: YakkuPalette.textPrimary,
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _StatusBadge(item: item),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.item});

  final AskBackListItem item;

  @override
  Widget build(BuildContext context) {
    final (label, fill, ink) = item.isYourTurn
        ? ('Your turn', YakkuPalette.primary, YakkuPalette.white)
        : item.isWaiting
        ? (
            'Waiting for their reply',
            YakkuPalette.greyBlush,
            YakkuPalette.textSecondary,
          )
        : (
            item.status == AskBackStatus.blocked ? 'Blocked' : 'Chat ended',
            YakkuPalette.greyBlush,
            YakkuPalette.textSecondary,
          );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _TagColors {
  const _TagColors(this.fill, this.ink);

  final Color fill;
  final Color ink;

  static _TagColors of(AskBackListItem item) {
    if (!item.isAsker) {
      return const _TagColors(
        YakkuPalette.accentPurple,
        YakkuPalette.purpleInk,
      );
    }
    if (item.context.contentType == 'poll') {
      return const _TagColors(YakkuPalette.mint, YakkuPalette.forestGreen);
    }
    final hash = item.id.hashCode.abs() % 2;
    return hash == 0
        ? const _TagColors(YakkuPalette.pillPink, YakkuPalette.primary)
        : const _TagColors(YakkuPalette.mint, YakkuPalette.forestGreen);
  }
}

class _AvatarTint {
  static const _colors = <Color>[
    YakkuPalette.avatarPink,
    Color(0xFFB7D4F8),
    YakkuPalette.mint,
    YakkuPalette.butter,
    YakkuPalette.accentPurple,
  ];

  static Color of(String id) => _colors[id.hashCode.abs() % _colors.length];
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
