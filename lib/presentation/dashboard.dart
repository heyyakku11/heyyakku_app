import 'dart:async';

import 'package:flutter/material.dart';
import '../data/models/dashboard_item.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/activity_screen.dart';
import 'package:yakku/presentation/screens/create_screen.dart';
import 'package:yakku/presentation/screens/home_screen.dart';
import 'package:yakku/presentation/screens/profile_screen.dart';
import 'package:yakku/presentation/widgets/notification_permission_dialog.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _index = 0;
  late final PageController _pageController;
  late final List<DashboardItem> _items;
  bool _deviceFlowStarted = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _items = [
      DashboardItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Home',
        page: HomeScreen(onAskAnything: _goToCreate),
      ),
      const DashboardItem(
        icon: Icons.add_circle_outline,
        activeIcon: Icons.add_circle,
        label: 'Create',
        page: CreateScreen(),
      ),
      const DashboardItem(
        icon: Icons.favorite_border_rounded,
        activeIcon: Icons.favorite_rounded,
        label: 'Activity',
        page: ActivityScreen(),
      ),
      const DashboardItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Profile',
        page: ProfileScreen(),
      ),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_runDeviceRegistrationFlow());
    });
  }

  Future<void> _runDeviceRegistrationFlow() async {
    if (_deviceFlowStarted || !mounted) return;
    _deviceFlowStarted = true;

    final deviceRegistration = AppScope.of(context).deviceRegistration;
    final shouldPrompt = await deviceRegistration.shouldPromptForPermission();
    if (!mounted) return;

    if (shouldPrompt) {
      final allow = await showNotificationPermissionDialog(context);
      if (!mounted) return;
      if (allow == true) {
        await deviceRegistration.applyAllowChoice();
      } else {
        await deviceRegistration.applySkipChoice();
      }
      return;
    }

    deviceRegistration.registerDeviceInBackground();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToCreate() => _pageController.jumpToPage(1);

  void _onPageChanged(int index) {
    setState(() => _index = index);
  }

  void _onNavTap(int index) {
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const ClampingScrollPhysics(),
        onPageChanged: _onPageChanged,
        children: _items.map((item) => item.page).toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _onNavTap,
        items: _items.map((item) {
          return BottomNavigationBarItem(
            icon: Icon(item.icon),
            activeIcon: Icon(item.activeIcon),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }
}
