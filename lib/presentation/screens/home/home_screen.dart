import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/data/datasources/poll_list_datasource.dart';
import 'package:yakku/data/models/Poll.dart';
import 'package:yakku/data/models/notification/update_notification_preference_request.dart';
import 'package:yakku/data/models/poll/poll_carousel_item.dart';
import 'package:yakku/data/models/poll_option.dart';
import 'package:yakku/domain/enums/poll_answer_type.dart';
import 'package:yakku/domain/enums/poll_options_type.dart';
import 'package:yakku/domain/enums/poll_status.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/home/notification_screen.dart';
import 'package:yakku/data/models/poll/draft_poll.dart';
import 'package:yakku/presentation/screens/create/create_screen.dart';
import 'package:yakku/presentation/widgets/notification_permission_dialog.dart';
import 'package:yakku/presentation/widgets/poll_card.dart';
import 'package:yakku/presentation/widgets/yakku_carousel_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.onAskAnything,
    this.notificationsReady = false,
  });

  final VoidCallback? onAskAnything;

  /// Set by the dashboard after the launch permission prompt finishes.
  final bool notificationsReady;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<PollModel> _polls = const [];
  Object? _error;

  bool _openingNotifications = false;
  int? _unreadCount;

  @override
  void initState() {
    super.initState();

    _loadPolls();

    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshUnreadCount());
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.notificationsReady && !oldWidget.notificationsReady) {
      _refreshUnreadCount();
    }
  }

  Future<void> _refreshUnreadCount() async {
    final allowed = await AppScope.of(
      context,
    ).deviceRegistration.isNotificationAllowed();

    if (!mounted) return;

    if (!allowed) {
      setState(() {
        _unreadCount = null;
      });

      return;
    }

    try {
      final page = await AppScope.of(context).notifications.getMine();

      if (!mounted) return;

      setState(() {
        _unreadCount = page.items.where((item) => !item.isRead).length;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _unreadCount = null;
      });
    }
  }

  void _loadPolls() {
    try {
      _polls = const PollListDataSource().fetchActivePolls();
      _error = null;
    } catch (error) {
      _polls = const [];
      _error = error;
    }
  }

  void _onShare(PollModel poll) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Share "${poll.question}"')));
  }

  void _onEdit(PollModel poll) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Edit "${poll.question}"')));
  }

  Future<void> _openNotificationScreen() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const NotificationScreen()),
    );

    if (!mounted || changed != true) return;

    await _refreshUnreadCount();
  }

  Future<void> _onNotificationsPressed() async {
    if (_openingNotifications) return;

    _openingNotifications = true;

    final scope = AppScope.of(context);
    final registration = scope.deviceRegistration;

    try {
      final allowed = await registration.isNotificationAllowed();

      if (!mounted) return;

      if (allowed) {
        await _openNotificationScreen();
        return;
      }

      final allow = await showNotificationPermissionDialog(context);

      if (!mounted || allow != true) return;

      final granted = await registration.applyAllowChoice();

      if (!mounted) return;

      await scope.notificationPreferences.updatePreferences(
        UpdateNotificationPreferenceRequest(pushEnabled: granted),
      );

      if (!mounted) return;

      if (!granted) {
        _showMessage('Notifications are blocked in system settings');
        return;
      }

      await _refreshUnreadCount();

      if (!mounted) return;

      await _openNotificationScreen();
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        DioErrorMapper.map(
          error,
          fallback: 'Could not save notification preference',
        ).message,
      );
    } finally {
      _openingNotifications = false;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/yakku.png',
              height: 42,
              width: 42,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 6),
            Text(
              'Yakku',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _onNotificationsPressed,
            icon: Badge(
              isLabelVisible: (_unreadCount ?? 0) > 0,
              label: Text('${_unreadCount ?? 0}'),
              child: const Icon(Icons.notifications_none_rounded),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth >= 600;

            final horizontalPadding = isWideScreen
                ? AppSpacing.xxl
                : AppSpacing.screen;

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.sm,
                horizontalPadding,
                AppSpacing.xxl,
              ),
              itemCount: 1 + _itemCount,
              itemBuilder: (context, index) {
                // ─────────────────────────────
                // FEATURED POLL CAROUSEL
                // ─────────────────────────────
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                    child: PollCarousel(items: pollCarouselItems),
                  );
                }

                // ─────────────────────────────
                // POLL ERROR / EMPTY STATE
                // ─────────────────────────────
                if (_error != null) {
                  return const _PollMessage(text: 'Could not load polls.');
                }

                if (_polls.isEmpty) {
                  return const _PollMessage(text: 'No polls yet.');
                }

                // ─────────────────────────────
                // NORMAL POLL CARDS
                // ─────────────────────────────
                final poll = _polls[index - 1];

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: PollCard(
                    poll: poll,
                    onShare: () => _onShare(poll),
                    onEdit: _onEdit,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  int get _itemCount {
    if (_error != null || _polls.isEmpty) {
      return 1;
    }

    return _polls.length;
  }
}

// ═══════════════════════════════════════════════════════════════
// POLL MESSAGE
// ═══════════════════════════════════════════════════════════════

class _PollMessage extends StatelessWidget {
  const _PollMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SAMPLE POLL CAROUSEL DATA
// ═══════════════════════════════════════════════════════════════

final List<PollCarouselItem> pollCarouselItems = [
  PollCarouselItem(
    poll: PollModel(
      id: 'poll-001',
      question: 'What do you prefer to drink in the morning?',
      categoryId: 'food',
      answerType: PollAnswerType.fromValue(1),
      allowCustomOption: false,
      status: PollStatus.fromValue(1),
      totalVoteCount: 124,
      options: [
        PollOptionModel(
          id: 'option-001',
          type: PollOptionType.fromValue(1),
          text: 'Coffee',
          imageUrl: null,
          sortOrder: 1,
          isCustom: false,
        ),
        PollOptionModel(
          id: 'option-002',
          type: PollOptionType.fromValue(1),
          text: 'Tea',
          imageUrl: null,
          sortOrder: 2,
          isCustom: false,
        ),
        PollOptionModel(
          id: 'option-003',
          type: PollOptionType.fromValue(1),
          text: 'Juice',
          imageUrl: null,
          sortOrder: 3,
          isCustom: false,
        ),
      ],
    ),
  ),

  PollCarouselItem(
    poll: PollModel(
      id: 'poll-002',
      question: 'Which technologies do you enjoy working with?',
      categoryId: 'technology',
      answerType: PollAnswerType.fromValue(2),
      allowCustomOption: false,
      status: PollStatus.fromValue(1),
      totalVoteCount: 89,
      options: [
        PollOptionModel(
          id: 'option-004',
          type: PollOptionType.fromValue(1),
          text: 'Flutter',
          imageUrl: null,
          sortOrder: 1,
          isCustom: false,
        ),
        PollOptionModel(
          id: 'option-005',
          type: PollOptionType.fromValue(1),
          text: 'React',
          imageUrl: null,
          sortOrder: 2,
          isCustom: false,
        ),
        PollOptionModel(
          id: 'option-006',
          type: PollOptionType.fromValue(1),
          text: 'Spring Boot',
          imageUrl: null,
          sortOrder: 3,
          isCustom: false,
        ),
      ],
    ),
  ),

  PollCarouselItem(
    poll: PollModel(
      id: 'poll-003',
      question: 'Where would you rather spend your next vacation?',
      categoryId: 'travel',
      answerType: PollAnswerType.fromValue(1),
      allowCustomOption: true,
      status: PollStatus.fromValue(1),
      totalVoteCount: 216,
      options: [
        PollOptionModel(
          id: 'option-008',
          type: PollOptionType.fromValue(1),
          text: 'Mountains',
          imageUrl: null,
          sortOrder: 1,
          isCustom: false,
        ),
        PollOptionModel(
          id: 'option-009',
          type: PollOptionType.fromValue(1),
          text: 'Beach',
          imageUrl: null,
          sortOrder: 2,
          isCustom: false,
        ),
        PollOptionModel(
          id: 'option-010',
          type: PollOptionType.fromValue(1),
          text: 'City',
          imageUrl: null,
          sortOrder: 3,
          isCustom: false,
        ),
      ],
    ),
  ),
];

// ═══════════════════════════════════════════════════════════════
// POLL CAROUSEL
// ═══════════════════════════════════════════════════════════════

class PollCarousel extends StatefulWidget {
  const PollCarousel({super.key, required this.items});

  final List<PollCarouselItem> items;

  @override
  State<PollCarousel> createState() => _PollCarouselState();
}

class _PollCarouselState extends State<PollCarousel> {
  late final PageController _pageController;

  int _currentPage = 0;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(viewportFraction: 0.90);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 400;

        final cardHeight = isCompact ? 455.0 : 470.0;

        return Column(
          children: [
            SizedBox(
              height: cardHeight,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.items.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final item = widget.items[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: YakkuCarouselCard(
                      question: item.poll.question,
                      options: [
                        for (final option in item.poll.options)
                          option.text?.trim().isNotEmpty == true
                              ? option.text!.trim()
                              : 'Option',
                      ],
                      category: item.poll.categoryId,
                      voteCount: item.poll.totalVoteCount,
                      showAddOption: item.poll.allowCustomOption,
                      gradientIndex: index,
                      expandOptions: true,
                      onMakeItYours: () {
                        showCreatePollSheet(
                          context,
                          draft: DraftPoll.fromPollModel(item.poll),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            _CarouselIndicator(
              count: widget.items.length,
              currentIndex: _currentPage,
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CAROUSEL INDICATOR
// ═══════════════════════════════════════════════════════════════

class _CarouselIndicator extends StatelessWidget {
  const _CarouselIndicator({required this.count, required this.currentIndex});

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }
}
