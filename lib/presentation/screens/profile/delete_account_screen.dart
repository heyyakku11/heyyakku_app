import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';

/// Asks the user to type DELETE before the account deletion is requested.
/// The word is only checked here in the app; the server just receives the
/// delete request.
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  static const _confirmWord = 'DELETE';

  final _controller = TextEditingController();
  bool _deleting = false;

  /// The button works only when the exact word has been typed.
  bool get _confirmed => _controller.text.trim() == _confirmWord;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    if (_deleting || !_confirmed) return;
    FocusScope.of(context).unfocus();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YakkuPalette.cream,
      appBar: AppBar(
        backgroundColor: YakkuPalette.cream,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: _deleting ? null : () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
          icon: const FaIcon(
            FontAwesomeIcons.chevronLeft,
            size: 16,
            color: YakkuPalette.Ink,
          ),
        ),
        title: const Text(
          'Delete account',
          style: TextStyle(
            color: YakkuPalette.Ink,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 62,
                          height: 62,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: YakkuPalette.Error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.trashCan,
                            size: 22,
                            color: YakkuPalette.Error,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Delete your account?',
                          style: TextStyle(
                            color: YakkuPalette.Ink,
                            fontSize: 30,
                            height: 1.1,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'This deletes your cards, votes, reasons, ask backs '
                          'and your name. Yakku+ and Yakku passes are not '
                          'refunded. It becomes permanent after 30 days; '
                          'sign in again before then to cancel.',
                          style: TextStyle(
                            color: YakkuPalette.textSecondary,
                            fontSize: 13.5,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Type DELETE to confirm',
                          style: TextStyle(
                            color: YakkuPalette.Ink,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _controller,
                          enabled: !_deleting,
                          autocorrect: false,
                          enableSuggestions: false,
                          textCapitalization: TextCapitalization.characters,
                          textInputAction: TextInputAction.done,
                          inputFormatters: [
                            // Whatever is typed or pasted becomes capitals.
                            _UpperCaseFormatter(),
                            LengthLimitingTextInputFormatter(
                              _confirmWord.length,
                            ),
                          ],
                          cursorColor: YakkuPalette.danger,
                          style: const TextStyle(
                            color: YakkuPalette.Ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                          decoration: InputDecoration(
                            hintText: _confirmWord,
                            hintStyle: const TextStyle(
                              color: YakkuPalette.hint,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.6,
                            ),
                            filled: true,
                            fillColor: YakkuPalette.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 18,
                            ),
                            border: _border(YakkuPalette.roseBorder),
                            enabledBorder: _border(YakkuPalette.roseBorder),
                            disabledBorder: _border(YakkuPalette.roseBorder),
                            focusedBorder: _border(
                              _confirmed
                                  ? YakkuPalette.Ink
                                  : YakkuPalette.danger,
                              width: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _confirmed && !_deleting ? _deleteAccount : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: YakkuPalette.Ink,
                      disabledBackgroundColor: YakkuPalette.Ink.withValues(
                        alpha: 0.35,
                      ),
                      foregroundColor: YakkuPalette.white,
                      disabledForegroundColor: YakkuPalette.white,
                      shape: const StadiumBorder(),
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
                        : const Text(
                            'Delete my account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: TextButton(
                    onPressed: _deleting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text(
                      'Keep my account',
                      style: TextStyle(
                        color: YakkuPalette.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
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

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

/// Turns everything typed or pasted into upper case.
class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
