import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yakku/core/constants/api_constants.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/profile/delete_account_screen.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// "Let people I answer ask me back": an account setting kept on the server,
  /// independent of the device's push switch below.
  bool _allowAskBack = true;
  bool _askBackReady = false;
  bool _askBackUpdating = false;

  /// Whether push is switched on for THIS device (the server's per-installation
  /// `isPushAllowed`; off until this device has been granted the permission).
  bool _pushAllowed = false;
  bool _pushReady = false;
  bool _pushUpdating = false;

  String? _version;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAskBack();
      _loadPushSetting();
    });
  }

  Future<void> _loadAskBack() async {
    try {
      final settings = await AppScope.of(context).userRemote.getSettings();
      if (!mounted) return;
      setState(() {
        _allowAskBack = settings.allowAskBack;
        _askBackReady = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _askBackReady = true);
      _showError(error, fallback: 'Could not load your settings');
    }
  }

  Future<void> _setAllowAskBack(bool value) async {
    if (_askBackUpdating) return;
    final previous = _allowAskBack;
    setState(() {
      _allowAskBack = value;
      _askBackUpdating = true;
    });
    try {
      final settings = await AppScope.of(
        context,
      ).userRemote.updateSettings(allowAskBack: value);
      if (!mounted) return;
      setState(() {
        _allowAskBack = settings.allowAskBack;
        _askBackUpdating = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _allowAskBack = previous;
        _askBackUpdating = false;
      });
      _showError(error, fallback: 'Could not update your setting');
    }
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _version = info.version);
    } catch (_) {}
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

  Future<bool> _confirmTurnOffPush() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Turn off push notifications?'),
          content: const Text(
            'You will stop getting alerts on this device, like when your '
            'friends answer your asks. You can turn them back on any time.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep on'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Turn off'),
            ),
          ],
        );
      },
    );
    return confirmed == true;
  }

  Future<void> _setPushAllowed(bool value) async {
    if (_pushUpdating) return;

    // Switching on needs no confirmation; switching off does. The switch is
    // controlled, so it stays on until the user confirms.
    if (!value && !await _confirmTurnOffPush()) return;
    if (!mounted) return;

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
    AppToast.show(message);
  }

  /// The privacy policy and the terms live on the same website page.
  Future<void> _openPolicy() async {
    final opened = await launchUrl(
      Uri.parse(ApiConstants.policyUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened) AppToast.show('Could not open the page');
  }

  Future<void> _emailSupport(String subject) async {
    const email = ApiConstants.supportEmail;
    if (email.isEmpty) {
      AppToast.show('The support email is not set up yet');
      return;
    }
    final opened = await launchUrl(
      Uri(scheme: 'mailto', path: email, queryParameters: {'subject': subject}),
    );
    if (!opened) AppToast.show('Could not open your email app');
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

  void _openDeleteAccount() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const DeleteAccountScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YakkuPalette.cream,
      appBar: AppBar(
        backgroundColor: YakkuPalette.cream,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
          icon: const FaIcon(
            FontAwesomeIcons.chevronLeft,
            size: 16,
            color: YakkuPalette.Ink,
          ),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: YakkuPalette.Ink,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Theme(
        data: Theme.of(context).copyWith(switchTheme: _switchTheme),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            const _SectionLabel('PRIVACY'),
            _SettingsCard(
              children: [
                _SettingsRow(
                  icon: FontAwesomeIcons.arrowRotateLeft,
                  title: 'Let people I answer ask me back',
                  subtitle: 'You stay anonymous',
                  trailing: Switch(
                    value: _allowAskBack,
                    onChanged: _askBackReady && !_askBackUpdating
                        ? _setAllowAskBack
                        : null,
                  ),
                ),
                _SettingsRow(
                  icon: FontAwesomeIcons.bell,
                  title: 'Notifications',
                  trailing: Switch(
                    value: _pushAllowed,
                    onChanged: _pushReady && !_pushUpdating
                        ? _setPushAllowed
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _SectionLabel('ABOUT'),
            _SettingsCard(
              children: [
                _SettingsRow(
                  icon: FontAwesomeIcons.shieldHalved,
                  title: 'Privacy policy',
                  onTap: _openPolicy,
                  showChevron: true,
                ),
                _SettingsRow(
                  icon: FontAwesomeIcons.circleInfo,
                  title: 'Terms',
                  onTap: _openPolicy,
                  showChevron: true,
                ),
                _SettingsRow(
                  icon: FontAwesomeIcons.comment,
                  title: 'Email to',
                  onTap: () => _emailSupport('Hello Yakku'),
                  showChevron: true,
                ),
                _SettingsRow(
                  icon: FontAwesomeIcons.flag,
                  title: 'Report a problem',
                  onTap: () => _emailSupport('Problem report'),
                  showChevron: true,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SettingsCard(
              children: [
                _SettingsRow(
                  icon: FontAwesomeIcons.chevronLeft,
                  title: 'Log out',
                  onTap: _logOut,
                  showChevron: true,
                ),
                _SettingsRow(
                  icon: FontAwesomeIcons.trashCan,
                  title: 'Delete account',
                  color: YakkuPalette.primary,
                  onTap: _openDeleteAccount,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Yakku Technologies Pvt Ltd'
                '${_version == null ? '' : ' · v$_version'}',
                style: const TextStyle(
                  color: YakkuPalette.textSecondary,
                  fontSize: 11.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// White track off / raspberry track on, with a white thumb.
final _switchTheme = SwitchThemeData(
  thumbColor: WidgetStateProperty.all(YakkuPalette.white),
  trackColor: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.selected)) return YakkuPalette.primary;
    return YakkuPalette.settingsTile;
  }),
  trackOutlineColor: WidgetStateProperty.all(YakkuPalette.transparent),
  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
);

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 0, 10),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w800,
          color: YakkuPalette.textSecondary,
        ),
      ),
    );
  }
}

/// A white rounded card holding rows separated by thin dividers.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i < children.length - 1) {
        items.add(
          const Divider(
            height: 1,
            thickness: 1,
            indent: 52,
            color: YakkuPalette.roseBorder,
          ),
        );
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: YakkuPalette.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: YakkuPalette.roseBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: items),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showChevron = false,
    this.color = YakkuPalette.Ink,
  });

  final FaIconData icon;
  final String title;
  final String? subtitle;

  /// A switch, when the row is a setting.
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Center(child: FaIcon(icon, size: 18, color: color)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: YakkuPalette.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 10), trailing!],
            if (showChevron)
              const FaIcon(
                FontAwesomeIcons.chevronRight,
                size: 13,
                color: YakkuPalette.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}
