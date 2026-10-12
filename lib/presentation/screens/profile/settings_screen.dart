import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/profile/delete_account_screen.dart';
import 'package:yakku/presentation/screens/profile/you_settings_store.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final YouSettingsStore _store = YouSettingsStore();
  YouSettings _settings = YouSettings.defaults;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final settings = await _store.load();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _ready = true;
    });
  }

  Future<void> _update(YouSettings next) async {
    setState(() => _settings = next);
    await _store.save(next);
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
    final email = AppScope.of(context).authController.email;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: Theme(
        data: theme.copyWith(switchTheme: _pinkSwitchTheme),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const _SectionLabel('NOTIFICATIONS'),
            _SwitchRow(
              title: 'Votes and reasons',
              subtitle: 'When friends answer your asks',
              value: _settings.votesAndReasons,
              onChanged: _ready
                  ? (value) =>
                        _update(_settings.copyWith(votesAndReasons: value))
                  : null,
            ),
            _SwitchRow(
              title: 'Your result is ready',
              subtitle: 'The moment your You vs Crowd unlocks',
              value: _settings.resultReady,
              onChanged: _ready
                  ? (value) => _update(_settings.copyWith(resultReady: value))
                  : null,
            ),
            _SwitchRow(
              title: 'Friends asked you',
              subtitle: 'When someone you know asks something',
              value: _settings.friendsAsked,
              onChanged: _ready
                  ? (value) => _update(_settings.copyWith(friendsAsked: value))
                  : null,
            ),
            _SwitchRow(
              title: 'Weekly drop',
              subtitle: 'A new check every Monday evening',
              value: _settings.weeklyDrop,
              onChanged: _ready
                  ? (value) => _update(_settings.copyWith(weeklyDrop: value))
                  : null,
            ),
            const SizedBox(height: 18),
            const _SectionLabel('PRIVACY AND SAFETY'),
            _SwitchRow(
              title: 'Tell voters if they read me right',
              subtitle: 'They never see your full result',
              value: _settings.tellVoters,
              onChanged: _ready
                  ? (value) => _update(_settings.copyWith(tellVoters: value))
                  : null,
            ),
            _SwitchRow(
              title: 'Kind mode',
              subtitle: 'Only show reasons our filter rates as kind',
              value: _settings.kindMode,
              onChanged: _ready
                  ? (value) => _update(_settings.copyWith(kindMode: value))
                  : null,
            ),
            const _ChevronRow(
              title: 'Blocked words',
              subtitle: 'Reasons with these words never reach you',
            ),
            const _ChevronRow(title: 'Help and safety'),
            const SizedBox(height: 18),
            const _SectionLabel('ACCOUNT'),
            _ChevronRow(
              title: 'Email',
              subtitle: email == null || email.isEmpty ? 'Signed in' : email,
              showChevron: false,
            ),
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
            const SizedBox(height: 28),
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
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 0.6,
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
      padding: const EdgeInsets.symmetric(vertical: 8),
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
                const SizedBox(height: 2),
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
          Switch(value: value, onChanged: onChanged),
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
                    const SizedBox(height: 2),
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
