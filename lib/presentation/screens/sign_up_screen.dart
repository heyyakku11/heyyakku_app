import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:yakku/core/router/app_routes.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/presentation/app_scope.dart';

/// Phone sign-up. Reached from onboarding by replacing the route, and it can't
/// be popped: there is nothing behind it to go back to.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  static const _phoneLength = 10;
  static const _fieldHeight = 56.0;

  final _phoneController = TextEditingController();
  bool _isAdult = true;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String get _digits => _phoneController.text.replaceAll(' ', '');

  bool get _canSend => _digits.length == _phoneLength && _isAdult;

  /// Queues the OTP on the background worker and moves straight on; the OTP
  /// screen observes the in-flight send and reports a failure there.
  void _sendCode() {
    FocusScope.of(context).unfocus();
    AppScope.of(context).loginAuth.sendOtpInBackground(phone: '+91$_digits');
    context.pushNamed(AppRoutes.otpName, extra: _digits);
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: color, width: 1.2),
  );

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: YakkuPalette.cream,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Wordmark(),
                const SizedBox(height: 28),
                const Text(
                  'Sign up',
                  style: TextStyle(
                    color: YakkuPalette.Ink,
                    fontSize: 42,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 22),
                _buildBanner(),
                const SizedBox(height: 28),
                const Text(
                  'Phone number',
                  style: TextStyle(
                    color: YakkuPalette.Ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                _buildPhoneRow(),
                const SizedBox(height: 18),
                _buildAgeCheck(),
                const Spacer(),
                _buildSendButton(),
                const SizedBox(height: 14),
                _buildTerms(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: YakkuPalette.accentGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          _ShieldOutline(size: 20, color: YakkuPalette.Success),
          SizedBox(width: 12),
          Text(
            'Private and anonymous. Always.',
            style: TextStyle(
              color: YakkuPalette.Ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneRow() {
    return Row(
      children: [
        Container(
          height: _fieldHeight,
          width: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: YakkuPalette.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: YakkuPalette.roseBorder, width: 1.2),
          ),
          child: const Text(
            '+91',
            style: TextStyle(
              color: YakkuPalette.Ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: _fieldHeight,
            child: TextField(
              controller: _phoneController,
              // Fill the full field height so the border matches the +91 box
              // exactly; otherwise the border hugs the text's own height.
              expands: true,
              maxLines: null,
              minLines: null,
              textAlignVertical: TextAlignVertical.center,
              keyboardType: TextInputType.phone,
              cursorColor: YakkuPalette.primary,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(_phoneLength),
                _PhoneGroupFormatter(),
              ],
              style: const TextStyle(
                color: YakkuPalette.Ink,
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: '98765 43210',
                hintStyle: const TextStyle(color: YakkuPalette.hint),
                filled: true,
                fillColor: YakkuPalette.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 0,
                ),
                enabledBorder: _border(YakkuPalette.primary),
                focusedBorder: _border(YakkuPalette.primary),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgeCheck() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _isAdult = !_isAdult),
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: _isAdult ? YakkuPalette.primary : YakkuPalette.white,
                  borderRadius: BorderRadius.circular(8),
                  // An unticked box keeps the raspberry outline: it's required.
                  border: Border.all(color: YakkuPalette.primary, width: 1.5),
                ),
                alignment: Alignment.center,
                child: _isAdult
                    ? const FaIcon(
                        FontAwesomeIcons.check,
                        size: 12,
                        color: YakkuPalette.white,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              const Text(
                "I'm 18 or older",
                style: TextStyle(
                  color: YakkuPalette.Ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (!_isAdult) ...[
          const SizedBox(height: 14),
          const Row(
            children: [
              FaIcon(
                FontAwesomeIcons.triangleExclamation,
                size: 14,
                color: YakkuPalette.Error,
              ),
              SizedBox(width: 8),
              Text(
                'Tick “I’m 18 or older” to continue.',
                style: TextStyle(
                  color: YakkuPalette.Error,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: FilledButton(
        onPressed: _canSend ? _sendCode : null,
        style: FilledButton.styleFrom(
          backgroundColor: YakkuPalette.primary,
          disabledBackgroundColor: YakkuPalette.primary.withValues(alpha: 0.5),
          foregroundColor: YakkuPalette.white,
          disabledForegroundColor: YakkuPalette.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(29),
          ),
        ),
        child: const Text(
          'Send code',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildTerms() {
    return const Text.rich(
      TextSpan(
        text: 'By signing up you agree to the ',
        style: TextStyle(fontSize: 12),
        children: [
          TextSpan(
            text: 'Terms',
            style: TextStyle(
              color: YakkuPalette.primary,
              decoration: TextDecoration.underline,
            ),
          ),
          TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy policy',
            style: TextStyle(
              color: YakkuPalette.primary,
              decoration: TextDecoration.underline,
            ),
          ),
          TextSpan(
            text: ', and to get messages from Yakku on SMS and WhatsApp.',
          ),
        ],
      ),
      textAlign: TextAlign.center,
      style: TextStyle(
        color: YakkuPalette.textSecondary,
        fontSize: 11,
        height: 1.4,
      ),
    );
  }
}

/// Shows a 10-digit number as "98765 43210". Expects digits only as input.
class _PhoneGroupFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text;
    final text = digits.length > 5
        ? '${digits.substring(0, 5)} ${digits.substring(5)}'
        : digits;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        text: 'Yakku',
        style: TextStyle(
          color: YakkuPalette.Ink,
          fontSize: 28,
          height: 1,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
        children: [
          TextSpan(
            text: '.',
            style: TextStyle(color: YakkuPalette.primary),
          ),
        ],
      ),
    );
  }
}

/// Outlined shield (Font Awesome's free set only has filled ones).
class _ShieldOutline extends StatelessWidget {
  const _ShieldOutline({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _ShieldPainter(color));
  }
}

class _ShieldPainter extends CustomPainter {
  const _ShieldPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Drawn on a 24x24 grid, then scaled to the requested size.
    final s = size.width / 24;
    final path = Path()
      ..moveTo(12 * s, 2.5 * s)
      ..lineTo(20.5 * s, 5.8 * s)
      ..lineTo(20.5 * s, 12 * s)
      ..cubicTo(20.5 * s, 17 * s, 16.8 * s, 20.5 * s, 12 * s, 22 * s)
      ..cubicTo(7.2 * s, 20.5 * s, 3.5 * s, 17 * s, 3.5 * s, 12 * s)
      ..lineTo(3.5 * s, 5.8 * s)
      ..close();
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * s
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ShieldPainter oldDelegate) => oldDelegate.color != color;
}
