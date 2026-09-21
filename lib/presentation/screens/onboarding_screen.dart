import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/privacy_policy_screen.dart';
import 'package:yakku/presentation/screens/terms_of_service_screen.dart';
import 'package:yakku/presentation/widgets/app_alert.dart';
import 'package:yakku/presentation/widgets/app_button.dart';
import 'package:yakku/presentation/widgets/app_input_text.dart';

import '../widgets/otp_bottom_sheet.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _emailController = TextEditingController();
  String? _emailError;
  String? _appVersion;
  bool _isSendingOtp = false;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersion = info.version;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  String? _validateEmail(String value) {
    final email = value.trim();
    if (email.isEmpty) {
      return 'Email is required.';
    }
    if (!_isValidEmail(email)) {
      return 'Enter a valid email.';
    }
    return null;
  }

  void _onEmailChanged(String value) {
    setState(() {
      _emailError = _validateEmail(value);
    });
  }

  void _resetEmailInput() {
    if (!mounted) return;
    _emailController.clear();
    setState(() {
      _emailError = null;
    });
  }

  Future<void> _showError(String message) {
    return showAppAlert(context, title: 'Could not send OTP', message: message);
  }

  String _otpErrorMessage(Object error) {
    return DioErrorMapper.map(
      error,
      fallback: 'Failed to send OTP. Please try again.',
    ).message;
  }

  Future<void> _continue() async {
    if (_isSendingOtp) return;

    final email = _emailController.text.trim();
    final error = _validateEmail(email);

    setState(() {
      _emailError = error;
    });

    if (error != null) return;

    setState(() {
      _isSendingOtp = true;
    });

    try {
      final sendOtpData = await AppScope.of(context).authController.sendOtp(
        email,
      );
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return OtpBottomSheet(
            email: email,
            expiresInMinutes: sendOtpData.expiresInMinutes,
          );
        },
      ).whenComplete(_resetEmailInput);
    } catch (e) {
      if (!mounted) return;
      await _showError(_otpErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() {
          _isSendingOtp = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(
                  Icons.forum_rounded,
                  size: 44,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Yakku',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(fontFamily: 'Pacifico'),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Ask anonymously. Get honest opinions.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppInputText(
                controller: _emailController,
                labelText: 'Email',
                hintText: '@',
                errorText: _emailError,
                enabled: !_isSendingOtp,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onChanged: _onEmailChanged,
                onSubmitted: (_) => _continue(),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text.rich(
                TextSpan(
                  text: 'Before using Yakku, you reviewed it\'s ',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  children: [
                    TextSpan(
                      text: 'Privacy Policy',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PrivacyPolicyScreen(),
                            ),
                          );
                        },
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Terms of Service',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const TermsOfServiceScreen(),
                            ),
                          );
                        },
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
              if (_isSendingOtp)
                const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                  child: CircularProgressIndicator(),
                ),
              const Spacer(),
              AppButton(
                label: 'Get Started',
                onPressed: _isSendingOtp ? null : _continue,
              ),
              if (_appVersion != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Version $_appVersion',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
