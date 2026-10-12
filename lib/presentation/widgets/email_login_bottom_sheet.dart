import 'package:flutter/material.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/widgets/app_alert.dart';
import 'package:yakku/presentation/widgets/app_button.dart';
import 'package:yakku/presentation/widgets/app_input_text.dart';

class EmailLoginResult {
  const EmailLoginResult({required this.email, required this.expiresInMinutes});

  final String email;
  final int expiresInMinutes;
}

class EmailLoginBottomSheet extends StatefulWidget {
  const EmailLoginBottomSheet({super.key});

  @override
  State<EmailLoginBottomSheet> createState() => _EmailLoginBottomSheetState();
}

class _EmailLoginBottomSheetState extends State<EmailLoginBottomSheet> {
  final _emailController = TextEditingController();
  String? _emailError;
  bool _isSendingOtp = false;

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

  Future<void> _showError(String message) {
    return showAppAlert(context, title: 'Could not send OTP', message: message);
  }

  Future<void> _sendOtp() async {
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
      final sendOtpData = await AppScope.of(
        context,
      ).authController.sendOtp(email);
      if (!mounted) return;
      Navigator.of(context).pop(
        EmailLoginResult(
          email: email,
          expiresInMinutes: sendOtpData.expiresInMinutes,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = DioErrorMapper.map(
        error,
        fallback: 'Failed to send OTP. Please try again.',
      ).message;
      await _showError(message);
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
                  'Log in',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isSendingOtp
                        ? null
                        : () => Navigator.of(context).pop(),
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
              'Enter your email and we will send you a code.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            AppInputText(
              controller: _emailController,
              labelText: 'Email',
              hintText: 'you@email.com',
              errorText: _emailError,
              enabled: !_isSendingOtp,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onChanged: _onEmailChanged,
              onSubmitted: (_) => _sendOtp(),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: _isSendingOtp ? 'Sending...' : 'Continue',
              onPressed: _isSendingOtp ? null : _sendOtp,
            ),
          ],
        ),
      ),
    );
  }
}
