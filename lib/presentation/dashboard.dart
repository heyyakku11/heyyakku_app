import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yakku/core/router/app_routes.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/create/create_screen.dart';
import 'package:yakku/presentation/screens/home/home_screen.dart';
import 'package:yakku/data/models/notification/app_notification.dart';
import 'package:yakku/presentation/screens/inbox/inbox_screen.dart';
import 'package:yakku/presentation/screens/inbox/open_notification_target.dart';
import 'package:yakku/presentation/screens/profile/profile_screen.dart';
import 'package:yakku/presentation/widgets/notification_permission_dialog.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with WidgetsBindingObserver {
  static const _homeNavIndex = 0;
  static const _activityNavIndex = 1;
  static const _profileNavIndex = 3;

  int _navIndex = 0;
  late final PageController _pageController;
  bool _notificationPromptStarted = false;

  /// Unread notifications, shown as a badge on the Activity tab.
  int _unreadCount = 0;
  StreamSubscription<RemoteMessage>? _pushSub;
  StreamSubscription<RemoteMessage>? _pushOpenedSub;
  Listenable? _readChanges;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncDeviceAndNotifications();
      _listenForUnread();
    });
    _pageController = PageController();
  }

  Future<void> _syncDeviceAndNotifications() async {
    if (!mounted || _notificationPromptStarted) return;
    _notificationPromptStarted = true;

    final scope = AppScope.of(context);
    final registration = scope.deviceRegistration;

    try {
      final shouldPrompt = await registration.shouldPromptForPermission();
      if (!mounted) return;

      if (!shouldPrompt) {
        registration.syncDeviceInBackground();
        return;
      }

      final allow = await showNotificationPermissionDialog(context);
      if (!mounted || allow == null) return;

      if (allow) {
        await registration.applyAllowChoice();
      } else {
        await registration.applySkipChoice();
      }
    } catch (error) {
      if (!mounted) return;
      final message = DioErrorMapper.map(
        error,
        fallback: 'Could not save notification preference',
      ).message;
      AppToast.show(message);
    }
  }

  /// Keeps the Activity badge fresh: on start, on sign-in/out, when the app
  /// returns to the foreground, and when a push arrives while it is open.
  void _listenForUnread() {
    if (!mounted) return;
    AppScope.of(context).authController.addListener(_refreshUnread);
    try {
      // A card's results being opened reads its notifications.
      _readChanges = AppScope.of(context).notifications.readChanges
        ..addListener(_refreshUnread);
    } catch (_) {
      // The badge still refreshes on resume and on push.
    }
    try {
      _pushSub = FirebaseMessaging.onMessage.listen((_) => _refreshUnread());
      // A tap on a push while the app is in the background...
      _pushOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen(
        _openFromPush,
      );
      // ...or the push that launched the app from a closed state.
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) _openFromPush(message);
      });
    } catch (_) {
      // Firebase is optional here; the badge still refreshes on resume.
    }
    _refreshUnread();
  }

  /// Tapping a push opens the results screen of the card it is about: the
  /// payload carries `contentType` (poll|check) and `contentId`.
  void _openFromPush(RemoteMessage message) {
    if (!mounted) return;
    final scope = AppScope.of(context);
    if (!scope.authController.isLoggedIn) return;

    final data = message.data;

    // A new Ask back message: open that conversation (the push carries only its id).
    final conversationId = data['conversationId']?.toString();
    if (conversationId != null && conversationId.isNotEmpty) {
      context.push(AppRoutes.askBackChatLocation(conversationId));
      return;
    }

    final notificationId = data['notificationId']?.toString();
    if (notificationId != null && notificationId.isNotEmpty) {
      scope.notifications
          .markRead(notificationId)
          .then((_) {
            _refreshUnread();
          })
          .catchError((_) {});
    }

    final target = NotificationTarget.tryParse({
      'contentId': data['contentId'],
      'contentType': data['contentType'],
    });
    if (target == null) {
      // No card attached: land on the Activity tab instead.
      _onNavTap(_activityNavIndex);
      return;
    }
    openNotificationTarget(context, target);
  }

  Future<void> _refreshUnread() async {
    if (!mounted) return;
    final scope = AppScope.of(context);
    if (!scope.authController.isLoggedIn) {
      if (_unreadCount != 0) setState(() => _unreadCount = 0);
      return;
    }
    try {
      final count = await scope.notifications.getUnreadCount();
      if (!mounted) return;
      // Nothing is unread while the user is reading the Activity tab's list.
      if (count != _unreadCount) setState(() => _unreadCount = count);
    } catch (_) {
      // Keep the last known count.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshUnread();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pushSub?.cancel();
    _pushOpenedSub?.cancel();
    _readChanges?.removeListener(_refreshUnread);
    _pageController.dispose();
    super.dispose();
  }

  void _openCreateSheet() {
    showCreatePollSheet(context);
  }

  /// Leaving the Activity tab reads every unread notification.
  void _markActivityReadOnExit(int nextNavIndex) {
    if (_navIndex != _activityNavIndex || nextNavIndex == _activityNavIndex) {
      return;
    }
    final scope = AppScope.of(context);
    if (!scope.authController.isLoggedIn) return;
    if (_unreadCount != 0) setState(() => _unreadCount = 0);
    scope.notifications.markAllRead().catchError((_) {
      // Best effort: they stay unread and are read on the next exit.
    });
  }

  void _onPageChanged(int index) {
    _markActivityReadOnExit(index);
    setState(() => _navIndex = index);
  }

  void _onNavTap(int index) {
    if (index == _navIndex) return;
    _markActivityReadOnExit(index);
    setState(() => _navIndex = index);
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const ClampingScrollPhysics(),
        onPageChanged: _onPageChanged,
        children: [
          const HomeScreen(),
          InboxScreen(onAskSomething: () => _onNavTap(_homeNavIndex)),
          const _CommunityPlaceholder(),
          ProfileScreen(isActive: _navIndex == _profileNavIndex),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _navIndex == _homeNavIndex
          ? _CreateFab(onPressed: _openCreateSheet)
          : null,
      bottomNavigationBar: _BottomBar(
        currentIndex: _navIndex,
        showActivityDot: _unreadCount > 0,
        onTap: _onNavTap,
      ),
    );
  }
}

/// The Create button: a raspberry circle with a hard ink shadow.
class _CreateFab extends StatelessWidget {
  const _CreateFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Create',
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            color: YakkuPalette.Raspberry,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: YakkuPalette.Ink, offset: Offset(3, 4)),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 34),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.currentIndex,
    required this.showActivityDot,
    required this.onTap,
  });

  final int currentIndex;
  final bool showActivityDot;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: YakkuPalette.Line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                label: 'Home',
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                selected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                label: 'Activity',
                icon: Icons.notifications_none_rounded,
                activeIcon: Icons.notifications_rounded,
                selected: currentIndex == 1,
                showDot: showActivityDot,
                onTap: () => onTap(1),
              ),
              _NavItem(
                label: 'Community',
                icon: Icons.people_outline_rounded,
                activeIcon: Icons.people_rounded,
                selected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                label: 'You',
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                selected: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.selected,
    required this.onTap,
    this.showDot = false,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool selected;
  final bool showDot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? YakkuPalette.Raspberry : YakkuPalette.Muted;
    return Expanded(
      child: InkResponse(
        onTap: onTap,
        radius: 40,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge(
              isLabelVisible: showDot,
              smallSize: 9,
              backgroundColor: YakkuPalette.Dot,
              child: Icon(selected ? activeIcon : icon, color: color, size: 26),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityPlaceholder extends StatelessWidget {
  const _CommunityPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(child: Center(child: Text('Community coming soon')));
  }
}
