import 'package:flutter/material.dart';
import 'package:yakku/presentation/screens/activity/activity_screen.dart';
import 'package:yakku/presentation/screens/create/create_screen.dart';
import 'package:yakku/presentation/screens/home/home_screen.dart';
import 'package:yakku/presentation/screens/profile/profile_screen.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  static const _createNavIndex = 1;

  int _navIndex = 0;
  late final PageController _pageController;
  late final List<Widget> _pages;
  late final List<BottomNavigationBarItem> _navItems;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pages = [
      HomeScreen(onAskAnything: _openCreateSheet),
      const ActivityScreen(),
      const ProfileScreen(),
    ];
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
        icon: Icon(Icons.chat_bubble_outline_rounded),
        activeIcon: Icon(Icons.chat_bubble_rounded),
        label: 'Activity',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline_rounded),
        activeIcon: Icon(Icons.person_rounded),
        label: 'Profile',
      ),
    ];
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
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: _onNavTap,
        items: _navItems,
      ),
    );
  }
}
