import 'package:flutter/material.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/profile/delete_account_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.phoneNumber, this.planName});

  /// From the get-user API; falls back to the stored session phone number.
  final String? phoneNumber;

  /// Current plan name from the get-user API (e.g. "Free").
  final String? planName;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// Whether push is switched on for THIS device (the server's per-installation
  /// `isPushAllowed`; off until this device has been granted the permission).
  bool _pushAllowed = false;
  bool _pushReady = false;
  bool _pushUpdating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPushSetting();
    });
  }

  Future<void> _loadPushSetting() async {
    try {
      final device = await AppScope.of(
        context,
      ).deviceRegistration.loadCurrentDevice();
      if (!mounted) return;
      setState(() {
        _pushAllowed = device.isPushAllowed;
        _pushReady = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _pushReady = true);
      _showError(error, fallback: 'Could not load notification setting');
    }
  }

  Future<void> _setPushAllowed(bool value) async {
    if (_pushUpdating) return;

    final previous = _pushAllowed;
    setState(() {
      _pushAllowed = value;
      _pushUpdating = true;
    });

    try {
      final updated = await AppScope.of(
        context,
      ).deviceRegistration.setPushAllowed(value);
      if (!mounted) return;
      setState(() {
        _pushAllowed = updated.isPushAllowed;
        _pushUpdating = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pushAllowed = previous;
        _pushUpdating = false;
      });
      _showError(error, fallback: 'Could not update notification setting');
    }
  }

  void _showError(Object error, {required String fallback}) {
    final message = DioErrorMapper.map(error, fallback: fallback).message;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _logOut() async {
    final confirmed = await showDialog<bool>(
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

    if (confirmed != true || !mounted) return;
    final auth = AppScope.of(context).authController;
    Navigator.of(context).popUntil((route) => route.isFirst);
    await auth.logout();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phoneNumber =
        widget.phoneNumber ?? AppScope.of(context).authController.phoneNumber;
    final maskedPhone = _maskPhoneNumber(phoneNumber);
    final dividerColor = theme.dividerColor.withValues(alpha: 0.55);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: Theme(
        data: theme.copyWith(switchTheme: _pinkSwitchTheme),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            const _SectionLabel('NOTIFICATIONS'),
            _SwitchRow(
              title: 'Push notifications',
              subtitle: 'Allow Yakku to send push alerts on this device',
              value: _pushAllowed,
              onChanged: _pushReady && !_pushUpdating ? _setPushAllowed : null,
            ),
            const SizedBox(height: 22),
            const _SectionLabel('PRIVACY AND SAFETY'),
            const _ChevronRow(title: 'Help and safety'),
            const SizedBox(height: 22),
            const _SectionLabel('ACCOUNT'),
            _AccountGroup(
              dividerColor: dividerColor,
              children: [
                _PlanRow(
                  planLabel: widget.planName ?? 'Free',
                  actionLabel: 'See Yakku Love',
                  onActionTap: () {},
                ),
                _ChevronRow(
                  title: 'Phone number',
                  subtitle: maskedPhone ?? 'Signed in',
                ),
                const _ChevronRow(title: 'Terms and privacy'),
                _ChevronRow(title: 'Log out', onTap: _logOut),
                _ChevronRow(
                  title: 'Delete account',
                  titleColor: YakkuPalette.primary,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const DeleteAccountScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Yakku is for people 18 and over.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final _pinkSwitchTheme = SwitchThemeData(
  thumbColor: WidgetStateProperty.all(Colors.white),
  trackColor: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.selected)) return YakkuPalette.primary;
    return const Color(0xFFE6D5DA);
  }),
  trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
);

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 0.7,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _AccountGroup extends StatelessWidget {
  const _AccountGroup({required this.children, required this.dividerColor});

  final List<Widget> children;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i < children.length - 1) {
        items.add(Divider(height: 1, thickness: 1, color: dividerColor));
      }
    }
    return Column(children: items);
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.planLabel,
    required this.actionLabel,
    this.onActionTap,
  });

  final String planLabel;
  final String actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your plan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  planLabel,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onActionTap,
            style: TextButton.styleFrom(
              foregroundColor: YakkuPalette.primary,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChevronRow extends StatelessWidget {
  const _ChevronRow({
    required this.title,
    this.subtitle,
    this.onTap,
    this.titleColor,
    this.showChevron = true,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? titleColor;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: titleColor ?? theme.colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}

/// Masks a phone like `+91 98xxx xx210` for the account row.
String? _maskPhoneNumber(String? phone) {
  if (phone == null) return null;
  final trimmed = phone.trim();
  if (trimmed.isEmpty) return null;

  final digits = trimmed.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 10) return trimmed;

  final hasCountry91 =
      (digits.length >= 12 && digits.startsWith('91')) ||
      trimmed.startsWith('+91');
  final local = hasCountry91 && digits.length >= 12
      ? digits.substring(digits.length - 10)
      : digits.substring(digits.length - 10);

  final masked =
      '${local.substring(0, 2)}xxx xx${local.substring(local.length - 3)}';
  return '+91 $masked';
}
