import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yakku/core/auth/otp_error_codes.dart';
import 'package:yakku/core/network/api_exception.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/data/models/auth/send_otp_data.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/widgets/app_alert.dart';

class OtpBottomSheet extends StatefulWidget {
  final String phone;
  final String firstName;

  const OtpBottomSheet({
    super.key,
    required this.phone,
    required this.firstName,
  });

  @override
  State<OtpBottomSheet> createState() => _OtpBottomSheetState();
}

class _OtpBottomSheetState extends State<OtpBottomSheet> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isWaitingForSend = true;
  bool _sendFailed = false;
  int _expiresInMinutes = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_awaitPendingSend());
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }

    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }

    super.dispose();
  }

  Future<void> _awaitPendingSend() async {
    final pending = AppScope.of(context).loginAuth.pendingSend;
    if (pending == null) {
      if (!mounted) return;
      setState(() {
        _isWaitingForSend = false;
        _sendFailed = false;
      });
      return;
    }

    try {
      final SendOtpData data = await pending;
      if (!mounted) return;
      setState(() {
        _isWaitingForSend = false;
        _sendFailed = false;
        _expiresInMinutes = data.expiresInMinutes;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isWaitingForSend = false;
        _sendFailed = true;
      });
      final message = DioErrorMapper.map(
        error,
        fallback: 'Failed to send OTP. Please try again.',
      ).message;
      await _showError(message, title: 'Could not send OTP');
      if (!mounted) return;
      _closeSheet();
    }
  }

  Future<void> _retrySend() async {
    if (_isWaitingForSend) return;
    setState(() {
      _isWaitingForSend = true;
      _sendFailed = false;
    });

    final scope = AppScope.of(context);
    scope.loginAuth.sendOtpInBackground(
      phone: widget.phone,
      name: widget.firstName,
    );
    await _awaitPendingSend();
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    if (value.isNotEmpty && index == 5) {
      _focusNodes[index].unfocus();
    }
  }

  void _onKeyEvent(KeyEvent event, int index) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
        _controllers[index - 1].clear();
      }
    }
  }

  String get _otp {
    return _controllers.map((controller) => controller.text).join();
  }

  bool get _isOtpComplete => _otp.length == 6;

  void _clearOtpFields() {
    for (final controller in _controllers) {
      controller.clear();
    }
    _focusNodes.first.requestFocus();
  }

  Future<void> _showError(String message, {String title = 'Verification failed'}) {
    return showAppAlert(
      context,
      title: title,
      message: message,
    );
  }

  ApiException _mappedError(Object error) {
    return DioErrorMapper.map(
      error,
      fallback: 'Failed to verify OTP. Please try again.',
    );
  }

  String? _otpErrorCode(ApiException error) {
    final fromCode = OtpErrorCodes.normalize(error.code);
    if (fromCode != null) return fromCode;

    final message = error.message.toLowerCase();
    if (message.contains('retry') && message.contains('limit')) {
      return OtpErrorCodes.retryLimitExceeded;
    }
    if (message.contains('not found')) {
      return OtpErrorCodes.notFound;
    }
    if (message.contains('invalid')) {
      return OtpErrorCodes.invalid;
    }
    return null;
  }

  void _closeSheet() {
    Navigator.of(context).pop();
  }

  Future<void> _handleVerifyFailure(Object error) async {
    _clearOtpFields();

    final mapped = _mappedError(error);
    final code = _otpErrorCode(mapped);

    switch (code) {
      case OtpErrorCodes.invalid:
        await _showError(
          mapped.message,
          title: 'Invalid code',
        );
        return;
      case OtpErrorCodes.notFound:
        await _showError(
          mapped.message,
          title: 'Code not found',
        );
        return;
      case OtpErrorCodes.retryLimitExceeded:
        await _showError(
          mapped.message,
          title: 'Too many attempts',
        );
        if (!mounted) return;
        _closeSheet();
        return;
      default:
        await _showError(mapped.message);
    }
  }

  Future<void> _verifyOtp() async {
    if (!_isOtpComplete || _isVerifying || _isWaitingForSend || _sendFailed) {
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    final scope = AppScope.of(context);
    final authController = scope.authController;

    try {
      await authController.verifyOtp(
        phone: widget.phone,
        otp: _otp,
        firstName: widget.firstName,
        guestToken: scope.guestTokenStore.guestToken,
      );
      if (!mounted) return;
      _closeSheet();
    } catch (e) {
      if (!mounted) return;
      await _handleVerifyFailure(e);
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  String get _statusText {
    if (_isWaitingForSend) {
      return 'Sending a 6-digit verification code to ${widget.phone}…';
    }
    if (_sendFailed) {
      return 'We could not send a code to ${widget.phone}. Try again.';
    }
    if (_expiresInMinutes > 0) {
      return 'We sent a 6-digit verification code to ${widget.phone}. '
          'This code will expire in $_expiresInMinutes minutes.';
    }
    return 'We sent a 6-digit verification code to ${widget.phone}.';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Verify your number',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isVerifying ? null : _closeSheet,
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              _statusText,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade600,
              ),
            ),

            if (_isWaitingForSend) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(minHeight: 2),
            ],

            const SizedBox(height: 28),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) => _otpField(index)),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ListenableBuilder(
                listenable: Listenable.merge(_controllers),
                builder: (context, _) {
                  if (_sendFailed) {
                    return ElevatedButton(
                      onPressed: _isWaitingForSend ? null : _retrySend,
                      child: const Text(
                        'Resend code',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }

                  final canVerify = _isOtpComplete &&
                      !_isVerifying &&
                      !_isWaitingForSend;
                  return ElevatedButton(
                    onPressed: canVerify ? _verifyOtp : null,
                    child: _isVerifying
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Verify OTP',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Widget _otpField(int index) {
    return SizedBox(
      width: 48,
      height: 56,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) => _onKeyEvent(event, index),
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          enabled: !_isVerifying && !_isWaitingForSend && !_sendFailed,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
          ),
          onChanged: (value) => _onOtpChanged(value, index),
        ),
      ),
    );
  }
}
