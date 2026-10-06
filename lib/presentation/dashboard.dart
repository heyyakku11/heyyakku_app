import 'package:flutter/material.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/data/models/notification/update_notification_preference_request.dart';
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

class _DashboardState extends State<Dashboard> {
  static const _createNavIndex = 1;

  int _navIndex = 0;
  late final PageController _pageController;
  late final List<BottomNavigationBarItem> _navItems;
  bool _notificationPromptStarted = false;
  bool _notificationsReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncDeviceAndNotifications();
    });
    _pageController = PageController();
    _navItems = const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home_rounded),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.add_circle_outline),
        activeIcon: Icon(Icons.add_circle),
        label: 'Create',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.inbox_outlined),
        activeIcon: Icon(Icons.inbox),
        label: 'Inbox',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline_rounded),
        activeIcon: Icon(Icons.person_rounded),
        label: 'Profile',
      ),
    ];
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
        registration.registerDeviceInBackground();
        return;
      }

      final allow = await showNotificationPermissionDialog(context);
      if (!mounted || allow == null) return;

      final granted = allow ? await registration.applyAllowChoice() : false;
      if (!allow) {
        await registration.applySkipChoice();
      }
      if (!mounted) return;

      await scope.notificationPreferences.updatePreferences(
        UpdateNotificationPreferenceRequest(pushEnabled: granted),
      );
    } catch (error) {
      if (!mounted) return;
      final message = DioErrorMapper.map(
        error,
        fallback: 'Could not save notification preference',
      ).message;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _notificationsReady = true);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _pageToNav(int pageIndex) =>
      pageIndex >= _createNavIndex ? pageIndex + 1 : pageIndex;

  int _navToPage(int navIndex) =>
      navIndex > _createNavIndex ? navIndex - 1 : navIndex;

  void _openCreateSheet() {
    showCreatePollSheet(context);
  }

  void _onPageChanged(int pageIndex) {
    setState(() => _navIndex = _pageToNav(pageIndex));
  }

  void _onNavTap(int navIndex) {
    if (navIndex == _createNavIndex) {
      _openCreateSheet();
      return;
    }
    final pageIndex = _navToPage(navIndex);
    _pageController.jumpToPage(pageIndex);
    setState(() => _navIndex = navIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const ClampingScrollPhysics(),
        onPageChanged: _onPageChanged,
        children: [
          HomeScreen(
            onAskAnything: _openCreateSheet,
            notificationsReady: _notificationsReady,
          ),
          const InboxScreen(),
          const ProfileScreen(),
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
