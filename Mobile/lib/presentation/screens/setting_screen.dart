import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/presentation/screens/edit_profile_screen.dart';
import 'package:yakku/presentation/widgets/section_header.dart';
import 'package:yakku/presentation/widgets/settings_tile.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  Future<void> _showInfo(String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          const SectionHeader(title: 'Account'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Card(
              child: Column(
                children: [
                  SettingsTile(
                    title: 'Edit Profile',
                    leading: Icons.person_outline_rounded,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );
                    },
                  ),
                  SettingsTile(
                    title: 'Privacy',
                    leading: Icons.lock_outline_rounded,
                    onTap: () => _showInfo(
                      'Privacy',
                      'Votes and questions are anonymous. Yakku never shows your name on polls.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SectionHeader(title: 'Other'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Card(
              child: Column(
                children: [
                  SettingsTile(
                    title: 'Help & Support',
                    leading: Icons.help_outline_rounded,
                    onTap: () => _showInfo(
                      'Help & Support',
                      'This prototype uses local mock data only. No account or network is required.',
                    ),
                  ),
                  SettingsTile(
                    title: 'About Yakku',
                    leading: Icons.info_outline_rounded,
                    onTap: () => _showInfo(
                      'About Yakku',
                      'Anonymous polling for honest opinions. Create polls on mobile and collect votes without names.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
