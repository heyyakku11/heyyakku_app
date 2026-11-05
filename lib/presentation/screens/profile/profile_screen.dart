import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:yakku/core/router/app_routes.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/core/auth/auth_controller.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/auth/open_sign_up.dart';
import 'package:yakku/presentation/screens/profile/draft_screen.dart';
import 'package:yakku/presentation/screens/profile/my_asks_screen.dart';
import 'package:yakku/presentation/screens/profile/saved_polls_screen.dart';
import 'package:yakku/presentation/screens/profile/settings_screen.dart';
import 'package:yakku/presentation/widgets/profile_option_tile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.isActive = true});

  /// True while the profile tab is the visible one; the profile is reloaded each
  /// time it becomes visible so the stats reflect what the user just did.
  final bool isActive;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _name;
  String? _phoneNumber;
  String? _anonymousName;
  String? _planName;
  int _cards = 0;
  int _votes = 0;
  int _streak = 0;
  AuthController? _authController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _authController = AppScope.of(context).authController;
      _authController!.addListener(_onAuthChanged);
      _loadProfile();
    });
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive && _authController != null) {
      _loadProfile();
    }
  }

  @override
  void dispose() {
    _authController?.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    final loggedIn = AppScope.of(context).authController.isLoggedIn;
    if (!loggedIn) {
      setState(() {
        _name = null;
        _phoneNumber = null;
        _anonymousName = null;
        _planName = null;
        _cards = 0;
        _votes = 0;
        _streak = 0;
      });
      return;
    }
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final scope = AppScope.of(context);
    if (!scope.authController.isLoggedIn) return;

    setState(() {
      _name = _nonEmpty(scope.authController.displayName);
      _phoneNumber = _nonEmpty(scope.authController.phoneNumber);
    });

    try {
      final me = await scope.userRemote.getMe();
      if (!mounted || !AppScope.of(context).authController.isLoggedIn) return;
      setState(() {
        final name = _nonEmpty(me.profile.anonymousName);
        final phone = _nonEmpty(me.account.phoneNumber);
        if (name != null) _name = name;
        _anonymousName = _nonEmpty(me.profile.anonymousName);
        if (phone != null) _phoneNumber = phone;
        final plan = _nonEmpty(me.account.currentPlan?.name);
        if (plan != null) _planName = plan;
        // The server computes these (cards = polls + checks made, votes = votes cast
        // on other people's cards, streak = the running day streak).
        _cards = me.stats.cardsMade;
        _votes = me.stats.votesCast;
        _streak = me.stats.streak.currentStreak;
      });
    } catch (_) {}
  }

  Future<void> _openWhenLoggedIn(Widget screen) async {
    final loggedIn = AppScope.of(context).authController.isLoggedIn;
    if (!loggedIn) {
      openSignUp(context);
      return;
    }
    if (!mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context).authController;
    final drafts = AppScope.of(context).draftPolls;
    final askBackInbox = AppScope.of(context).askBackInbox;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([auth, drafts, askBackInbox]),
          builder: (context, _) {
            final loggedIn = auth.isLoggedIn;
            final displayName = _name ?? _nonEmpty(auth.displayName);
            final phoneNumber = _phoneNumber ?? _nonEmpty(auth.phoneNumber);
            final name = displayName ?? 'You';
            final initial = _initial(displayName);

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () => _openWhenLoggedIn(
                        SettingsScreen(
                          phoneNumber: phoneNumber,
                          planName: _planName,
                        ),
                      ),
                      icon: const Icon(Icons.settings_outlined),
                    ),
                  ),
                  if (loggedIn) ...[
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: YakkuPalette.avatarPink,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: YakkuPalette.textPrimary,
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (_anonymousName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _anonymousName!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    // if (phoneNumber != null) ...[
                    //   const SizedBox(height: 4),
                    //   Text(
                    //     phoneNumber,
                    //     textAlign: TextAlign.center,
                    //     style: TextStyle(
                    //       fontSize: 14,
                    //       color: theme.colorScheme.onSurfaceVariant,
                    //     ),
                    //   ),
                    // ],
                    const SizedBox(height: 18),
                    _StatsCard(cards: _cards, votes: _votes, streak: _streak),
                  ] else ...[
                    const _GuestLoginPrompt(),
                  ],
                  const SizedBox(height: 16),
                  Material(
                    color: theme.cardTheme.color ?? YakkuPalette.white,
                    borderRadius: BorderRadius.circular(22),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        ProfileOptionTile(
                          icon: FontAwesomeIcons.clone,
                          label: 'My cards',
                          badgeCount: _cards,
                          showDivider: true,
                          onTap: () => _openWhenLoggedIn(const MyAsksScreen()),
                        ),
                        ProfileOptionTile(
                          icon: FontAwesomeIcons.fileLines,
                          label: 'Drafts',
                          badgeCount: drafts.drafts.length,
                          showDivider: true,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (context) => const DraftScreen(),
                              ),
                            );
                          },
                        ),
                        ProfileOptionTile(
                          icon: FontAwesomeIcons.arrowRotateLeft,
                          label: 'My ask backs',
                          badgeCount: askBackInbox.unreadTotal,
                          highlightBadge: true,
                          showDivider: true,
                          onTap: () async {
                            if (!auth.isLoggedIn) {
                              openSignUp(context);
                              return;
                            }
                            if (!context.mounted) return;
                            await context.push(AppRoutes.askBack);
                          },
                        ),
                        ProfileOptionTile(
                          icon: FontAwesomeIcons.bookmark,
                          label: 'Saved questions',
                          showDivider: true,
                          onTap: () =>
                              _openWhenLoggedIn(const SavedPollsScreen()),
                        ),
                        ProfileOptionTile(
                          icon: FontAwesomeIcons.gear,
                          label: 'Settings',
                          onTap: () => _openWhenLoggedIn(
                            SettingsScreen(
                              phoneNumber: phoneNumber,
                              planName: _planName,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GuestLoginPrompt extends StatelessWidget {
  const _GuestLoginPrompt();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Column(
        children: [
          // Text(
          //   'Log in to see your profile',
          //   textAlign: TextAlign.center,
          //   style: theme.textTheme.titleMedium?.copyWith(
          //     fontWeight: FontWeight.w700,
          //     color: theme.colorScheme.onSurface,
          //   ),
          // ),
          // const SizedBox(height: 8),
          Text(
            'Your asks, votes, and saved polls will show up here once you\'re signed in.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => openSignUp(context),
              child: const Text('Log in'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.cards,
    required this.votes,
    required this.streak,
  });

  final int cards;
  final int votes;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardTheme.color ?? YakkuPalette.white,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        child: Row(
          children: [
            _Stat(value: '$cards', label: 'Cards'),
            _Stat(value: '$votes', label: 'Votes'),
            _Stat(value: '$streak', label: 'Day streak'),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

String? _nonEmpty(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

String _initial(String? name) {
  final trimmed = name?.trim();
  if (trimmed == null || trimmed.isEmpty) return 'Y';
  return trimmed[0].toUpperCase();
}
