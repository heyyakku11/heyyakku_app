import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/create/create_screen.dart';
import 'package:yakku/presentation/screens/home/home_screen.dart';
import 'package:yakku/presentation/screens/inbox/inbox_screen.dart';
import 'package:yakku/presentation/screens/profile/profile_screen.dart';
import 'package:yakku/presentation/widgets/notification_permission_dialog.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with WidgetsBindingObserver {
  static const _createNavIndex = 1;
  static const _activityNavIndex = 2;

  int _navIndex = 0;
  late final PageController _pageController;
  bool _notificationPromptStarted = false;

  /// Unread notifications, shown as a badge on the Activity tab.
  int _unreadCount = 0;
  StreamSubscription<RemoteMessage>? _pushSub;

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

  List<BottomNavigationBarItem> get _navItems => [
    const BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.add_circle_outline),
      activeIcon: Icon(Icons.add_circle),
      label: 'Create',
    ),
    BottomNavigationBarItem(
      icon: _ActivityIcon(count: _unreadCount),
      activeIcon: _ActivityIcon(count: _unreadCount),
      label: 'Activity',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person_outline_rounded),
      activeIcon: Icon(Icons.person_rounded),
      label: 'You',
    ),
  ];

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
      _pushSub = FirebaseMessaging.onMessage.listen((_) => _refreshUnread());
    } catch (_) {
      // Firebase is optional here; the badge still refreshes on resume.
    }
    _refreshUnread();
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
    _pageController.dispose();
    super.dispose();
  }

  int _pageToNav(int pageIndex) =>
      pageIndex >= _createNavIndex ? pageIndex + 1 : pageIndex;

  /// The page index of the profile tab in the [PageView].
  static const int _profilePage = 2;

  int _navToPage(int navIndex) =>
      navIndex > _createNavIndex ? navIndex - 1 : navIndex;

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

  void _onPageChanged(int pageIndex) {
    final next = _pageToNav(pageIndex);
    _markActivityReadOnExit(next);
    setState(() => _navIndex = next);
  }

  void _onNavTap(int navIndex) {
    if (navIndex == _createNavIndex) {
      _openCreateSheet();
      return;
    }
    final pageIndex = _navToPage(navIndex);
    _markActivityReadOnExit(navIndex);
    setState(() => _navIndex = navIndex);
    _pageController.jumpToPage(pageIndex);
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
          const InboxScreen(),
          ProfileScreen(isActive: _navToPage(_navIndex) == _profilePage),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: _onNavTap,
        items: _navItems,
      ),
    );
  }
}

/// The Activity tab icon with a bubble showing how many notifications are unread.
class _ActivityIcon extends StatelessWidget {
  const _ActivityIcon({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: count > 0,
      label: Text(count > 99 ? '99+' : '$count'),
      child: const Icon(Icons.notifications),
    );
  }
}
