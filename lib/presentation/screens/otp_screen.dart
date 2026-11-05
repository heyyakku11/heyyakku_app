import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:yakku/core/auth/otp_error_codes.dart';
import 'package:yakku/core/network/api_exception.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/router/app_routes.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/presentation/app_scope.dart';

/// "Enter the code": six boxes for the OTP sent to the phone number.
///
/// Sending and verifying run on the background worker through
/// [LoginAuthService]; this screen only starts the work and shows its result.
/// On a successful verify the auth state changes and the router leaves.
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.phoneDigits});

  /// The 10 national digits; the country code is always +91.
  final String phoneDigits;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const _length = 6;
  /// How long the user waits before requesting another code: 2 minutes.
  static const _resendSeconds = 120;
  static const _boxSize = Size(48, 56);

  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _timer;
  int _resendIn = _resendSeconds;
  bool _verifying = false;
  bool _sending = true;
  String? _error;
  bool _started = false;

  String get _phone => '+91${widget.phoneDigits}';

  String get _prettyPhone =>
      '+91 ${widget.phoneDigits.substring(0, 5)} ${widget.phoneDigits.substring(5)}';

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // The sign-up screen already queued the first send; just observe it.
    final pending = AppScope.of(context).loginAuth.pendingSend;
    _startTimer();
    if (pending == null) {
      _sending = false;
    } else {
      unawaited(_observeSend(pending));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _observeSend(Future<Object?> send) async {
    try {
      await send;
      if (!mounted) return;
      setState(() => _sending = false);
    } catch (error) {
      if (!mounted) return;
      _timer?.cancel();
      setState(() {
        _sending = false;
        _resendIn = 0;
        _error = _messageFor(error);
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _resendIn = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _resendIn <= 1) {
        timer.cancel();
        if (mounted) setState(() => _resendIn = 0);
        return;
      }
      setState(() => _resendIn -= 1);
    });
  }

  void _resend() {
    if (_sending || _verifying || _resendIn > 0) return;
    final auth = AppScope.of(context).loginAuth;
    auth.sendOtpInBackground(phone: _phone);
    final pending = auth.pendingSend;
    setState(() {
      _error = null;
      _sending = true;
      _controller.clear();
    });
    _startTimer();
    if (pending != null) unawaited(_observeSend(pending));
  }

  Future<void> _verify() async {
    final otp = _controller.text.trim();
    if (_verifying || otp.length != _length) return;
    final scope = AppScope.of(context);
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      final device = await scope.deviceRegistration.loginDevice();
      final guests = scope.guestTokenStore;
      await scope.loginAuth.verifyOtpInBackground(
        phone: _phone,
        otp: otp,
        guestToken: guests.hasValidGuest ? guests.guestToken : null,
        device: device,
      );
      // Logged in: the router replaces this screen on its own.
    } catch (error) {
      if (!mounted) return;
      // Clear the boxes so the user can retype straight away; the error stays
      // visible until they type again.
      _controller.clear();
      setState(() => _error = _messageFor(error));
      _focusNode.requestFocus();
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  String _messageFor(Object error) {
    final api = DioErrorMapper.map(
      error,
      fallback: 'Something went wrong. Please try again.',
    );
    switch (OtpErrorCodes.normalize(api.code)) {
      case OtpErrorCodes.invalid:
        return 'Wrong code. Check it and try again.';
      case OtpErrorCodes.notFound:
        return 'This code has expired. Request a new one.';
      case OtpErrorCodes.retryLimitExceeded:
        return 'Too many wrong attempts. Request a new code.';
    }
    if (api.kind == ApiErrorKind.rateLimited) {
      return 'Too many attempts. Please wait a moment.';
    }
    return api.message;
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.signUp);
    }
  }

  String get _resendLabel {
    final m = _resendIn ~/ 60;
    final s = (_resendIn % 60).toString().padLeft(2, '0');
    return 'Resend in $m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _controller.text.length == _length && !_verifying;
    return Scaffold(
      backgroundColor: YakkuPalette.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 22, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: _verifying ? null : _back,
                tooltip: 'Back',
                icon: const FaIcon(
                  FontAwesomeIcons.chevronLeft,
                  size: 16,
                  color: YakkuPalette.Ink,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    const Text(
                      'Enter the code',
                      style: TextStyle(
                        color: YakkuPalette.Ink,
                        fontSize: 38,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSentTo(),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Center(child: _buildBoxes()),
              const SizedBox(height: 14),
              Center(child: _buildStatus()),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: _buildContinue(canContinue),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSentTo() {
    return Text.rich(
      TextSpan(
        text: 'Sent to $_prettyPhone · ',
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: _verifying ? null : _back,
              child: const Text(
                'Edit',
                style: TextStyle(
                  color: YakkuPalette.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
      style: const TextStyle(color: YakkuPalette.textSecondary, fontSize: 13),
    );
  }

  Widget _buildBoxes() {
    final text = _controller.text;
    final hasError = _error != null;
    return SizedBox(
      width: _boxSize.width * _length + 10 * (_length - 1),
      height: _boxSize.height,
      child: Stack(
        children: [
          IgnorePointer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < _length; i++)
                  _OtpBox(
                    size: _boxSize,
                    digit: i < text.length ? text[i] : null,
                    active: _focusNode.hasFocus && i == text.length,
                    hasError: hasError,
                  ),
              ],
            ),
          ),
          // The real input: invisible, but it receives taps, the keyboard and
          // paste (including SMS autofill) for the whole row.
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                enableInteractiveSelection: false,
                showCursor: false,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(_length),
                ],
                onTap: () => setState(() {}),
                onChanged: (value) {
                  setState(() => _error = null);
                  if (value.length == _length) unawaited(_verify());
                },
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatus() {
    if (_error != null) {
      return Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FaIcon(
                FontAwesomeIcons.triangleExclamation,
                size: 12,
                color: YakkuPalette.Error,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: YakkuPalette.Error,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _resendButton(),
        ],
      );
    }
    if (_resendIn > 0) {
      return Text(
        _resendLabel,
        style: const TextStyle(
          color: YakkuPalette.textSecondary,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    return _resendButton();
  }

  Widget _resendButton() {
    final enabled = !_sending && !_verifying && _resendIn == 0;
    return GestureDetector(
      onTap: enabled ? _resend : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Text(
          _sending ? 'Sending…' : 'Resend code',
          style: TextStyle(
            color: enabled || _sending
                ? YakkuPalette.primary
                : YakkuPalette.primary.withValues(alpha: 0.4),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildContinue(bool enabled) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: FilledButton(
        onPressed: enabled ? _verify : null,
        style: FilledButton.styleFrom(
          backgroundColor: YakkuPalette.Ink,
          disabledBackgroundColor: YakkuPalette.Ink.withValues(alpha: 0.5),
          foregroundColor: YakkuPalette.white,
          disabledForegroundColor: YakkuPalette.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(29),
          ),
        ),
        child: _verifying
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: YakkuPalette.white,
                ),
              )
            : const Text(
                'Continue',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.size,
    required this.digit,
    required this.active,
    required this.hasError,
  });

  final Size size;
  final String? digit;
  final bool active;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final Color border;
    if (hasError) {
      border = YakkuPalette.primary;
    } else if (digit != null) {
      border = YakkuPalette.Ink;
    } else if (active) {
      border = YakkuPalette.primary;
    } else {
      border = YakkuPalette.roseBorder;
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: size.width,
      height: size.height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: YakkuPalette.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1.3),
      ),
      child: Text(
        digit ?? '',
        style: const TextStyle(
          color: YakkuPalette.Ink,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
