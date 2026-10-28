import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yakku/core/constants/api_constants.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/presentation/app_scope.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _confirmed = false;

  bool _deleting = false;

  Future<void> _deleteAccount() async {
    if (_deleting) return;
    setState(() => _deleting = true);

    final auth = AppScope.of(context).authController;
    final navigator = Navigator.of(context);

    try {
      await auth.deleteAccount();
      // Session is cleared; return to the root so the router shows onboarding.
      navigator.popUntil((route) => route.isFirst);
    } catch (error) {
      final message = DioErrorMapper.map(
        error,
        fallback: 'Could not delete your account',
      ).message;
      AppToast.show(message);
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _openPolicy() async {
    final opened = await launchUrl(
      Uri.parse(ApiConstants.policyUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened) AppToast.show('Could not open the policy page');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delete your account?',
                        style: TextStyle(
                          fontSize: 28,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your account will be permanently deleted after 30 days.',
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const _CheckLine(
                        'Your account stays pending deletion for 30 days. '
                        'Sign in again during that time and the deletion is cancelled.',
                      ),
                      const SizedBox(height: 16),
                      const _CheckLine(
                        'During those 30 days, your asks stay visible to other people.',
                      ),
                      const SizedBox(height: 16),
                      const _CheckLine(
                        'After 30 days, your account, phone number and asks are permanently deleted.',
                      ),
                      const SizedBox(height: 16),
                      const _CheckLine(
                        'Limited logs and payment records may be kept where needed for '
                        'security, accounting or legal reasons.',
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _openPolicy,
                        style: TextButton.styleFrom(
                          foregroundColor: YakkuPalette.primary,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Read the full privacy policy',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _confirmed,
                      onChanged: (value) {
                        setState(() => _confirmed = value ?? false);
                      },
                      activeColor: YakkuPalette.primary,
                      side: BorderSide(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _confirmed = !_confirmed),
                      child: Text(
                        'I understand this is permanent',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _confirmed && !_deleting ? _deleteAccount : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: YakkuPalette.danger,
                    disabledBackgroundColor: YakkuPalette.dangerDisabled,
                    foregroundColor: YakkuPalette.white,
                    disabledForegroundColor: YakkuPalette.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _deleting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: YakkuPalette.white,
                          ),
                        )
                      : const Text('Delete my account'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: _deleting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(
                    'Keep my account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckLine extends StatelessWidget {
  const _CheckLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.check, size: 18, color: YakkuPalette.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              height: 1.35,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
