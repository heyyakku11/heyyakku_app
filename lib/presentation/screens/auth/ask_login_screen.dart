import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/auth/ask_otp_screen.dart';
import 'package:yakku/presentation/widgets/app_alert.dart';
import 'package:yakku/presentation/widgets/app_button.dart';
import 'package:yakku/presentation/widgets/ask_preview_card.dart';

/// "Who's asking?" step: first name + +91 phone, with a live card preview.
/// Pops `true` once the user finishes the OTP step and is logged in.
class AskLoginScreen extends StatefulWidget {
  const AskLoginScreen({
    super.key,
    required this.question,
    this.optionCount = 3,
    this.confirmDiscard = false,
    this.onLoggedIn,
  });

  final String question;
  final int optionCount;

  /// Ask before leaving, since going back discards the whole create flow.
  final bool confirmDiscard;

  /// When set, runs after login and the screen it returns replaces this one,
  /// instead of popping `true` back to a caller.
  /// Returning null means "done, go back to the root (home)".
  final Future<Widget?> Function()? onLoggedIn;

  static const countryCode = '+91';

  @override
  State<AskLoginScreen> createState() => _AskLoginScreenState();
}

class _AskLoginScreenState extends State<AskLoginScreen> {
  static const _hint = Color(0xFFB9A8AB);
  static const _inputStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: YakkuPalette.textPrimary,
  );

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();

  String? _nameError;
  String? _phoneError;
  bool _isAdult = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(_onFocusChanged);
    _phoneFocus.addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() {});

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

  String? _validateName(String value) {
    if (value.trim().isEmpty) return 'First name is required.';
    if (value.trim().length < 2) return 'Enter your first name.';
    return null;
  }

  String? _validatePhone(String value) {
    final digits = value.trim();
    if (digits.isEmpty) return 'Phone number is required.';
    if (digits.length != 10) return 'Enter a 10-digit mobile number.';
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) {
      return 'Enter a valid Indian mobile number.';
    }
    return null;
  }

  Future<void> _sendCode() async {
    if (_isSubmitting) return;

    final nameError = _validateName(_name);
    final phoneError = _validatePhone(_digits);
    setState(() {
      _nameError = nameError;
      _phoneError = phoneError;
    });
    if (nameError != null || phoneError != null) return;
    if (!_isAdult) {
      await showAppAlert(
        context,
        title: 'Could not send code',
        message: 'Please confirm you are 18 or older.',
      );
      return;
    }

    final phone = '${AskLoginScreen.countryCode}$_digits';
    final name = _name;

    setState(() => _isSubmitting = true);
    AppScope.of(
      context,
    ).loginAuth.sendOtpInBackground(phone: phone, name: name);

    // The values are captured above; reset the form for when the user returns.
    _nameController.clear();
    _phoneController.clear();
    _nameError = null;
    _phoneError = null;

    final verified = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AskOtpScreen(phone: phone, firstName: name),
      ),
    );
    if (!mounted) return;
    if (verified == true) {
      final onLoggedIn = widget.onLoggedIn;
      if (onLoggedIn == null) {
        Navigator.of(context).pop(true);
        return;
      }
      try {
        final next = await onLoggedIn();
        if (!mounted) return;
        if (next == null) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          return;
        }
        await Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute<void>(builder: (_) => next));
        return;
      } catch (error) {
        if (!mounted) return;
        final message = DioErrorMapper.map(
          error,
          fallback: 'Could not send this check. Please try again.',
        ).message;
        await showAppAlert(context, title: "Couldn't send", message: message);
      }
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  Future<void> _confirmLeave() async {
    if (_isSubmitting) return;
    final discard = await showAppConfirmDialog(
      context,
      title: 'Discard this check?',
      message: 'If you go back, your check will be discarded.',
      confirmLabel: 'Discard',
      cancelLabel: 'Continue',
    );
    if (discard == true && mounted) Navigator.of(context).pop(false);
  }

  InputDecoration _decoration({String? hint, String? prefix}) {
    return InputDecoration(
      isDense: true,
      filled: false,
      fillColor: Colors.transparent,
      counterText: '',
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      hintText: hint,
      hintStyle: const TextStyle(color: _hint, fontWeight: FontWeight.w500),
      prefixText: prefix,
      prefixStyle: const TextStyle(
        color: _hint,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.confirmDiscard,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        backgroundColor: YakkuPalette.cream,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).maybePop(false),
                        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                        color: YakkuPalette.textPrimary,
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),
                      const SizedBox(height: 4),
                      ListenableBuilder(
                        listenable: _nameController,
                        builder: (context, _) => AskPreviewCard(
                          question: widget.question,
                          askerName: _nameController.text,
                          optionCount: widget.optionCount.clamp(2, 4),
                        ),
                      ),
                      const SizedBox(height: 22),
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
                      const SizedBox(height: 16),
                      const _FieldLabel('First name'),
                      _InputBox(
                        focused: _nameFocus.hasFocus,
                        errorText: _nameError,
                        child: TextField(
                          controller: _nameController,
                          focusNode: _nameFocus,
                          enabled: !_isSubmitting,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          cursorColor: YakkuPalette.primary,
                          style: _inputStyle,
                          onChanged: (_) {
                            if (_nameError != null) {
                              setState(() => _nameError = _validateName(_name));
                            }
                          },
                          onSubmitted: (_) => _phoneFocus.requestFocus(),
                          decoration: _decoration(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const _FieldLabel('Phone number'),
                      _InputBox(
                        focused: _phoneFocus.hasFocus,
                        errorText: _phoneError,
                        child: TextField(
                          controller: _phoneController,
                          focusNode: _phoneFocus,
                          enabled: !_isSubmitting,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          maxLength: 10,
                          cursorColor: YakkuPalette.primary,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: _inputStyle,
                          onChanged: (_) {
                            if (_phoneError != null) {
                              setState(
                                () => _phoneError = _validatePhone(_digits),
                              );
                            }
                          },
                          onSubmitted: (_) => _sendCode(),
                          decoration: _decoration(
                            hint: '',
                            prefix: '${AskLoginScreen.countryCode} ',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 13,
                            color: YakkuPalette.textSecondary,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Code on WhatsApp. Friends never see your number.',
                              style: TextStyle(
                                fontSize: 12,
                                color: YakkuPalette.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: _isSubmitting
                            ? null
                            : () => setState(() => _isAdult = !_isAdult),
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
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
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: YakkuPalette.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: AppButton(
                  label: _isSubmitting ? 'Sending...' : 'Send code',
                  onPressed: _isSubmitting ? null : _sendCode,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: YakkuPalette.textPrimary,
        ),
      ),
    );
  }
}

class _InputBox extends StatelessWidget {
  const _InputBox({required this.child, required this.focused, this.errorText});

  final Widget child;
  final bool focused;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasError
                  ? Colors.redAccent
                  : focused
                  ? YakkuPalette.primary
                  : const Color(0xFFF1E7EA),
              width: focused || hasError ? 1.5 : 1,
            ),
          ),
          child: child,
        ),
        if (hasError) ...[
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
