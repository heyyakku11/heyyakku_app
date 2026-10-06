import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/notification/update_notification_preference_request.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/profile/answered_polls_screen.dart';
import 'package:yakku/presentation/screens/profile/draft_screen.dart';
import 'package:yakku/presentation/screens/profile/saved_polls_screen.dart';
import 'package:yakku/presentation/screens/privacy_policy_screen.dart';
import 'package:yakku/presentation/widgets/app_switch.dart';
import 'package:yakku/presentation/widgets/profile_option_tile.dart';
import 'package:yakku/presentation/widgets/review_feedback_sheet.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool notificationsEnabled = false;
  bool _preferencesReady = false;
  bool _updatingNotifications = false;
  String? _appVersion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotificationPreference();
      _loadAppVersion();
    });
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersion = info.version;
    });
  }

  Future<void> _loadNotificationPreference() async {
    try {
      final preferences = await AppScope.of(
        context,
      ).notificationPreferences.getPreferences();
      if (!mounted) return;
      setState(() {
        notificationsEnabled = preferences.pushEnabled;
        _preferencesReady = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _preferencesReady = true);
      _showPreferenceError(
        error,
        fallback: 'Could not load notification preference',
      );
    }
  }

  Future<void> _onNotificationChanged(bool value) async {
    if (!_preferencesReady || _updatingNotifications) return;

    final previous = notificationsEnabled;
    setState(() {
      notificationsEnabled = value;
      _updatingNotifications = true;
    });

    final scope = AppScope.of(context);
    try {
      var enabled = value;
      if (value) {
        enabled = await scope.deviceRegistration.applyAllowChoice();
        if (!mounted) return;
        if (!enabled) {
          setState(() => notificationsEnabled = false);
          _showMessage('Notifications are blocked in system settings');
        }
      } else {
        await scope.deviceRegistration.applySkipChoice();
        if (!mounted) return;
      }

      await scope.notificationPreferences.updatePreferences(
        UpdateNotificationPreferenceRequest(pushEnabled: enabled),
      );
      if (!mounted) return;
      setState(() => notificationsEnabled = enabled);
    } catch (error) {
      if (!mounted) return;
      setState(() => notificationsEnabled = previous);
      _showPreferenceError(
        error,
        fallback: 'Could not update notification preference',
      );
    } finally {
      if (mounted) {
        setState(() => _updatingNotifications = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showPreferenceError(Object error, {required String fallback}) {
    _showMessage(DioErrorMapper.map(error, fallback: fallback).message);
  }

  Future<void> _logOut() async {
    final response = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to log out from Yakku?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (response != true || !mounted) return;

    await AppScope.of(context).authController.logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsetsGeometry.all(10),
                    child: Column(
                      spacing: 10,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {},
                              child: CircleAvatar(
                                radius: 25,
                                child: Icon(Icons.person),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'yakku@1232',
                                    style: TextStyle(
                                      fontWeight: FontWeight.normal,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          spacing: 10,
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: YakkuPalette.cream,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    children: [
                                      Text(
                                        '10',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        'Asked',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: YakkuPalette.cream,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    children: [
                                      Text(
                                        '8',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        'Answered',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      ProfileOptionTile(
                        icon: Icons.card_membership,
                        iconColor: Colors.black87,
                        label: 'Your Draft',
                        showDivider: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DraftScreen(),
                            ),
                          );
                        },
                      ),
                      ProfileOptionTile(
                        icon: Icons.bookmark_border,
                        iconColor: Colors.black87,
                        label: 'Saved',
                        showDivider: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SavedPollsScreen(),
                            ),
                          );
                        },
                      ),
                      ProfileOptionTile(
                        icon: Icons.check_circle_outline,
                        iconColor: Colors.black87,
                        label: 'Answered',
                        showDivider: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AnsweredPollsScreen(),
                            ),
                          );
                        },
                      ),
                      ProfileOptionTile(
                        icon: Icons.notifications_active_outlined,
                        label: 'Notification',
                        showChevron: false,
                        trailing: AppSwitch(
                          value: notificationsEnabled,
                          onChanged:
                              _preferencesReady && !_updatingNotifications
                              ? _onNotificationChanged
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),

                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                    child: Column(
                      children: [
                        ProfileOptionTile(
                          icon: Icons.policy_outlined,
                          label: 'Privacy Policy',
                          showDivider: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const PrivacyPolicyScreen(),
                              ),
                            );
                          },
                        ),
                        ProfileOptionTile(
                          icon: Icons.star_border,
                          label: 'Review & Feedback',
                          showChevron: false,
                          onTap: () => showReviewFeedbackSheet(context),
                        ),
                      ],
                    ),
                  ),
                ),

                // AppOutlinedButton(label: 'Log out', onPressed: _logOut),
                OutlinedButton(
                  onPressed: _logOut,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    backgroundColor: Colors.red.shade100,
                    side: BorderSide(color: Colors.red.shade300),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Log out',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                if (_appVersion != null) ...[
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Version $_appVersion',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
