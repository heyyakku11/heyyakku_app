import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/widgets/app_alert.dart';
import 'package:yakku/presentation/widgets/app_button.dart';

class EmailLoginResult {
  const EmailLoginResult({
    required this.phone,
    required this.firstName,
    required this.expiresInMinutes,
  });

  /// Full E.164 phone, e.g. +919876543210.
  final String phone;
  final String firstName;
  final int expiresInMinutes;
}

/// Login sheet: first name + +91 phone, rounded borderless inputs.
class EmailLoginBottomSheet extends StatefulWidget {
  const EmailLoginBottomSheet({super.key});

  static const countryCode = '+91';

  @override
  State<EmailLoginBottomSheet> createState() => _EmailLoginBottomSheetState();
}

class _EmailLoginBottomSheetState extends State<EmailLoginBottomSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();

  String? _nameError;
  String? _phoneError;
  bool _isAdult = true;
  bool _isSendingOtp = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  String get _name => _nameController.text.trim();
  String get _digits => _phoneController.text.trim();
  String get _fullPhone => '${EmailLoginBottomSheet.countryCode}$_digits';

  bool _isValidIndianMobile(String value) {
    return RegExp(r'^[6-9]\d{9}$').hasMatch(value);
  }

  String? _validateName(String value) {
    if (value.trim().isEmpty) return 'First name is required.';
    if (value.trim().length < 2) return 'Enter your first name.';
    return null;
  }

  String? _validatePhone(String value) {
    final digits = value.trim();
    if (digits.isEmpty) return 'Phone number is required.';
    if (digits.length != 10) return 'Enter a 10-digit mobile number.';
    if (!_isValidIndianMobile(digits)) {
      return 'Enter a valid Indian mobile number.';
    }
    return null;
  }

  Future<void> _showError(String message) {
    return showAppAlert(context, title: 'Could not send OTP', message: message);
  }

  Future<void> _sendOtp() async {
    if (_isSendingOtp) return;

    final nameError = _validateName(_name);
    final phoneError = _validatePhone(_digits);
    setState(() {
      _nameError = nameError;
      _phoneError = phoneError;
    });
    if (nameError != null || phoneError != null) return;
    if (!_isAdult) {
      await _showError('Please confirm you are 18 or older.');
      return;
    }

    setState(() => _isSendingOtp = true);

    try {
      final sendOtpData = await AppScope.of(
        context,
      ).authController.sendOtp(_fullPhone);
      if (!mounted) return;
      Navigator.of(context).pop(
        EmailLoginResult(
          phone: _fullPhone,
          firstName: _name,
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
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: YakkuPalette.cream,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: _isSendingOtp
                      ? null
                      : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 22),
                  color: YakkuPalette.textPrimary,
                ),
              ),
              const Text(
                "Who's asking?",
                style: TextStyle(
                  fontSize: 30,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: YakkuPalette.textPrimary,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 28),
              _RoundedField(
                errorText: _nameError,
                child: TextField(
                  controller: _nameController,
                  focusNode: _nameFocus,
                  enabled: !_isSendingOtp,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  cursorColor: YakkuPalette.primary,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: YakkuPalette.textPrimary,
                  ),
                  onChanged: (_) {
                    if (_nameError != null) {
                      setState(() => _nameError = _validateName(_name));
                    }
                  },
                  onSubmitted: (_) => _phoneFocus.requestFocus(),
                  decoration: const InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    hintText: 'Name',
                    hintStyle: TextStyle(
                      color: Color(0xFFB9A8AB),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _RoundedField(
                errorText: _phoneError,
                child: TextField(
                  controller: _phoneController,
                  focusNode: _phoneFocus,
                  enabled: !_isSendingOtp,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  maxLength: 10,
                  cursorColor: YakkuPalette.primary,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: YakkuPalette.textPrimary,
                    letterSpacing: 0.3,
                  ),
                  onChanged: (_) {
                    if (_phoneError != null) {
                      setState(() => _phoneError = _validatePhone(_digits));
                    }
                  },
                  onSubmitted: (_) => _sendOtp(),
                  decoration: const InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Colors.transparent,
                    counterText: '',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    hintText: '98xxx xxxxx',
                    hintStyle: TextStyle(
                      color: Color(0xFFB9A8AB),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                    ),
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(left: 16, right: 2),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: 1,
                        child: Text(
                          '+91 ',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFB9A8AB),
                          ),
                        ),
                      ),
                    ),
                    prefixIconConstraints: BoxConstraints(
                      minWidth: 0,
                      minHeight: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 14,
                    color: YakkuPalette.textSecondary,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Code on WhatsApp. Friends never see your number.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: YakkuPalette.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              InkWell(
                onTap: _isSendingOtp
                    ? null
                    : () => setState(() => _isAdult = !_isAdult),
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: _isAdult
                            ? YakkuPalette.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _isAdult
                              ? YakkuPalette.primary
                              : const Color(0xFFD5C6C8),
                          width: 1.5,
                        ),
                      ),
                      child: _isAdult
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "I'm 18 or older",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: YakkuPalette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              AppButton(
                label: _isSendingOtp ? 'Sending...' : 'Send',
                onPressed: _isSendingOtp ? null : _sendOtp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundedField extends StatelessWidget {
  const _RoundedField({
    required this.child,
    this.errorText,
  });

  final Widget child;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.redAccent,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
