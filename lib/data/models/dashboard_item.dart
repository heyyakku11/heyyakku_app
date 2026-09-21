import 'package:flutter/cupertino.dart';

class DashboardItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget page;

  const DashboardItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.page,
  });
}
