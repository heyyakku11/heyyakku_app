import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:yakku/core/router/app_routes.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/core/auth/auth_controller.dart';
import 'package:yakku/core/profile/avatar_preferences.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/auth/open_sign_up.dart';
import 'package:yakku/presentation/screens/profile/draft_screen.dart';
import 'package:yakku/presentation/screens/profile/my_cards_screen.dart';
import 'package:yakku/presentation/screens/profile/saved_polls_screen.dart';
import 'package:yakku/presentation/screens/personality/personality_navigation.dart';
import 'package:yakku/presentation/screens/profile/edit_profile_screen.dart';
import 'package:yakku/presentation/screens/profile/settings_screen.dart';
import 'package:yakku/presentation/screens/profile/widgets/profile_avatar.dart';
import 'package:yakku/presentation/screens/profile/widgets/profile_personality_card.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';
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
  final _avatarPrefs = AvatarPreferences();
  AvatarColor _avatarColor = AvatarColors.defaultColor;
  int _cards = 0;

  /// Visual only for now: Community is not built yet, so nothing is saved.
  bool _showInCommunity = true;
  AuthController? _authController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _authController = AppScope.of(context).authController;
      _authController!.addListener(_onAuthChanged);
      _loadAvatar();
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

  Future<void> _loadAvatar() async {
    final color = await _avatarPrefs.load();
    if (!mounted) return;
    setState(() => _avatarColor = color);
  }

  /// Opens the edit screen (new name, avatar colour); the colour is picked up
  /// again when it closes. A new name arrives through the auth controller.
  Future<void> _openEdit(String name) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            EditProfileScreen(name: name, avatarColor: _avatarColor),
      ),
    );
    if (mounted) await _loadAvatar();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    final loggedIn = AppScope.of(context).authController.isLoggedIn;
    if (!loggedIn) {
      setState(() {
        _name = null;
        _cards = 0;
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
    });
    unawaited(AppScope.of(context).personalityCards.refresh());

    try {
      final me = await scope.userRemote.getMe();
      if (!mounted || !AppScope.of(context).authController.isLoggedIn) return;
      setState(() {
        final name = _nonEmpty(me.profile.anonymousName);
        if (name != null) _name = name;
        // The server counts the cards made (polls + checks).
        _cards = me.stats.cardsMade;
      });
    } catch (_) {}
  }

  Future<void> _onPersonalityAsk() async {
    final store = AppScope.of(context).personalityCards;
    final card = store.card;
    if (card == null) return;
    await openPersonalityAsk(context, card, store.traits);
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
    final cards = AppScope.of(context).personalityCards;
    final askBackInbox = AppScope.of(context).askBackInbox;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([auth, drafts, askBackInbox, cards]),
          builder: (context, _) {
            final loggedIn = auth.isLoggedIn;
            final displayName = _name ?? _nonEmpty(auth.displayName);
            final name = displayName ?? 'You';

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  if (loggedIn) ...[
                    ProfileAvatar(color: _avatarColor.color),
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
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _openEdit(name),
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 14,
                              color: YakkuPalette.Raspberry,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Edit name and avatar',
                              style: TextStyle(
                                color: YakkuPalette.Raspberry,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
                    if (cards.card != null) ...[
                      const SizedBox(height: 14),
                      ProfilePersonalityCard(
                        card: cards.card!,
                        traitCount: cards.traits.length,
                        topTraits: cards.topTraits,
                        showInCommunity: _showInCommunity,
                        onAskNow: _onPersonalityAsk,
                        onFullResult: () =>
                            AppToast.show('Full results are coming soon'),
                        onShowInCommunityChanged: (value) =>
                            setState(() => _showInCommunity = value),
                      ),
                    ],
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
                          onTap: () => _openWhenLoggedIn(const MyCardsScreen()),
                        ),
                        if (drafts.drafts.isNotEmpty)
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
                          onTap: () =>
                              _openWhenLoggedIn(const SettingsScreen()),
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

String? _nonEmpty(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}
