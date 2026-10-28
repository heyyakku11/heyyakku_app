import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yakku/core/auth/otp_error_codes.dart';
import 'package:yakku/core/network/api_exception.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/auth/notification_permission_screen.dart';
import 'package:yakku/presentation/widgets/app_alert.dart';

/// "Enter the 6-digit code" step. Verifies by itself once all 6 digits are in.
/// Pops `true` when the user is logged in, `false` for "Wrong number?" / back.
class AskOtpScreen extends StatefulWidget {
  const AskOtpScreen({
    super.key,
    required this.phone,
    required this.firstName,
    this.onLoggedIn,
  });

  /// Full E.164 phone, e.g. +919876543210.
  final String phone;
  final String firstName;

  /// When set, runs after login while this screen stays up; the widget it
  /// returns replaces this screen and the login screen (null = back to root).
  /// When null, this screen just pops `true`.
  final Future<Widget?> Function()? onLoggedIn;

  @override
  State<AskOtpScreen> createState() => _AskOtpScreenState();
}

class _AskOtpScreenState extends State<AskOtpScreen> {
  static const _length = 6;

  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  bool _isVerifying = false;
  bool _isWaitingForSend = true;
  bool _sendFailed = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onCodeChanged);
    _focusNode.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_awaitPendingSend());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// `+91 98xxx xx210` from `+919876543210`.
  String get _maskedPhone {
    final digits = widget.phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return widget.phone;
    final local = digits.substring(digits.length - 10);
    return '+91 ${local.substring(0, 2)}xxx xx${local.substring(7)}';
  }

  bool get _inputEnabled => !_isVerifying && !_isWaitingForSend && !_sendFailed;

  Future<void> _awaitPendingSend() async {
    final pending = AppScope.of(context).loginAuth.pendingSend;
    if (pending == null) {
      if (!mounted) return;
      setState(() {
        _isWaitingForSend = false;
        _sendFailed = false;
      });
      _focusNode.requestFocus();
      return;
    }

    try {
      await pending;
      if (!mounted) return;
      setState(() {
        _isWaitingForSend = false;
        _sendFailed = false;
      });
      _focusNode.requestFocus();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isWaitingForSend = false;
        _sendFailed = true;
      });
      final message = DioErrorMapper.map(
        error,
        fallback: 'Failed to send code. Please try again.',
      ).message;
      await showAppAlert(
        context,
        title: 'Could not send code',
        message: message,
      );
      if (!mounted) return;
      Navigator.of(context).pop(false);
    }
  }

  void _onCodeChanged() {
    setState(() {});
    if (_controller.text.length == _length) {
      unawaited(_verify());
    }
  }

  ApiException _mappedError(Object error) {
    return DioErrorMapper.map(
      error,
      fallback: 'Failed to verify code. Please try again.',
    );
  }

  String? _otpErrorCode(ApiException error) {
    final fromCode = OtpErrorCodes.normalize(error.code);
    if (fromCode != null) return fromCode;

    final message = error.message.toLowerCase();
    // e.g. "Too many invalid OTP attempts" must win over the plain "invalid".
    if (error.kind == ApiErrorKind.rateLimited ||
        message.contains('too many') ||
        (message.contains('retry') && message.contains('limit'))) {
      return OtpErrorCodes.retryLimitExceeded;
    }
    if (message.contains('not found')) return OtpErrorCodes.notFound;
    if (message.contains('invalid')) return OtpErrorCodes.invalid;
    return null;
  }

  Future<void> _handleVerifyFailure(Object error) async {
    _controller.clear();

    final mapped = _mappedError(error);
    switch (_otpErrorCode(mapped)) {
      case OtpErrorCodes.invalid:
        await showAppAlert(
          context,
          title: 'Invalid code',
          message: mapped.message,
        );
      case OtpErrorCodes.notFound:
        await showAppAlert(
          context,
          title: 'Code not found',
          message: mapped.message,
        );
      case OtpErrorCodes.retryLimitExceeded:
        await showAppAlert(
          context,
          title: 'Too many attempts',
          message: mapped.message,
          buttonLabel: 'Discard',
        );
        if (!mounted) return;
        // Discard the whole create flow: OTP, login and everything under it.
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      default:
        await showAppAlert(
          context,
          title: 'Verification failed',
          message: mapped.message,
        );
    }
    if (mounted) _focusNode.requestFocus();
  }

  Future<void> _verify() async {
    final otp = _controller.text;
    if (otp.length != _length || !_inputEnabled) return;

    setState(() => _isVerifying = true);

    final scope = AppScope.of(context);
    try {
      await scope.authController.verifyOtp(
        phone: widget.phone,
        otp: otp,
        firstName: widget.firstName,
        guestToken: scope.guestTokenStore.guestToken,
        device: await scope.deviceRegistration.loginDevice(),
      );
      if (!mounted) return;
      // Now logged in: ask for notifications and register this device.
      await NotificationPermissionScreen.showIfNeeded(context);
      if (!mounted) return;

      final onLoggedIn = widget.onLoggedIn;
      if (onLoggedIn == null) {
        Navigator.of(context).pop(true);
        return;
      }

      // Keep this screen up (spinner) while the follow-up runs, so the login
      // form never flashes back; then replace both with the next screen.
      try {
        final next = await onLoggedIn();
        if (!mounted) return;
        final navigator = Navigator.of(context);
        if (next == null) {
          navigator.popUntil((route) => route.isFirst);
        } else {
          unawaited(
            navigator.pushAndRemoveUntil(
              MaterialPageRoute<void>(builder: (_) => next),
              (route) => route.isFirst,
            ),
          );
        }
        return;
      } catch (error) {
        if (!mounted) return;
        final message = DioErrorMapper.map(
          error,
          fallback: 'Could not send this check. Please try again.',
        ).message;
        await showAppAlert(context, title: "Couldn't send", message: message);
        if (!mounted) return;
        Navigator.of(context).pop(false);
        return;
      }
    } catch (e) {
      if (!mounted) return;
      await _handleVerifyFailure(e);
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
        // The field is disabled while verifying (which drops focus), so
        // re-focus once it is enabled again to let the user retype at once.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _inputEnabled) _focusNode.requestFocus();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = _controller.text;

    return PopScope(
      canPop: !_isVerifying,
      child: Scaffold(
        backgroundColor: YakkuPalette.cream,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: _isVerifying
                      ? null
                      : () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  color: YakkuPalette.textPrimary,
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Enter the 6-digit code',
                  style: TextStyle(
                    fontSize: 28,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    color: YakkuPalette.textPrimary,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      color: YakkuPalette.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(text: 'Sent an otp to $_maskedPhone. '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: _isVerifying
                              ? null
                              : () => Navigator.of(context).pop(false),
                          child: const Text(
                            'Wrong number?',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.35,
                              color: YakkuPalette.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isWaitingForSend) ...[
                  const SizedBox(height: 14),
                  const LinearProgressIndicator(
                    minHeight: 2,
                    color: YakkuPalette.primary,
                  ),
                ],
                const SizedBox(height: 28),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _inputEnabled ? _focusNode.requestFocus : null,
                  child: Stack(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (var i = 0; i < _length; i++)
                            _DigitBox(
                              digit: i < code.length ? code[i] : '',
                              active:
                                  _focusNode.hasFocus &&
                                  i == code.length.clamp(0, _length - 1) &&
                                  _inputEnabled,
                            ),
                        ],
                      ),
                      // Real input: invisible, drives the boxes above (also
                      // handles paste and SMS/WhatsApp autofill).
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0,
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            enabled: _inputEnabled,
                            autofocus: false,
                            showCursor: false,
                            enableInteractiveSelection: false,
                            keyboardType: TextInputType.number,
                            autofillHints: const [AutofillHints.oneTimeCode],
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(_length),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: YakkuPalette.pinkTintSoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 16,
                        color: YakkuPalette.primary,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your number keeps Yakku safe. Friends never see it.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: YakkuPalette.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Center(
                  child: _isVerifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: YakkuPalette.primary,
                          ),
                        )
                      : const Text(
                          'Checks by itself when all 6 digits are in',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: YakkuPalette.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DigitBox extends StatelessWidget {
  const _DigitBox({required this.digit, required this.active});

  final String digit;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: YakkuPalette.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: active ? YakkuPalette.primary : YakkuPalette.hairline,
          width: active ? 1.5 : 1,
        ),
      ),
      child: Text(
        digit,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: YakkuPalette.textPrimary,
        ),
      ),
    );
  }
}
