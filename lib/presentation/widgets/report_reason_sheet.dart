import 'package:flutter/material.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/poll/poll_reason.dart';

/// The choices offered when reporting. The text of the one picked is sent to
/// the API as the reason; the backend keeps no list of its own.
enum _ReportChoice {
  bullying('Mean or bullying'),
  identifiesSomeone('Says who someone is'),
  sexual('Sexual'),
  hate('Hate or slurs'),
  spam('Spam'),
  other('Something else');

  const _ReportChoice(this.label);

  final String label;
}

/// The report flow, in bottom sheets:
///
/// 1. "Report" with one option, "Report reason";
/// 2. "Why are you reporting this?" with the choices and a Report button
///    (Back returns to the first sheet);
/// 3. once [submit] succeeds, every sheet closes and "Thanks for telling us"
///    opens.
///
/// [submit] gets the reason text and sends the report. When it throws, the
/// sheet stays open and shows the error so the owner can try again. Returns
/// what [submit] returned, or null when the owner backed out or it failed.
Future<T?> showReportFlow<T>(
  BuildContext context, {
  required Future<T> Function(String reason) submit,
}) async {
  final result = await showModalBottomSheet<_Submitted<T>>(
    context: context,
    backgroundColor: YakkuPalette.white,
    isScrollControlled: true,
    useSafeArea: true,
    shape: _sheetShape,
    builder: (_) => _ReportSheet<T>(submit: submit),
  );
  if (result == null || !context.mounted) return null;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: YakkuPalette.white,
    useSafeArea: true,
    shape: _sheetShape,
    builder: (_) => const _ReportSentSheet(),
  );
  return result.value;
}

const _sheetShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
);

/// Boxes the result so a null from [showReportFlow]'s `submit` still counts as
/// a successful report.
class _Submitted<T> {
  const _Submitted(this.value);

  final T value;
}

enum _Step { start, pick }

class _ReportSheet<T> extends StatefulWidget {
  const _ReportSheet({required this.submit});

  final Future<T> Function(String reason) submit;

  @override
  State<_ReportSheet<T>> createState() => _ReportSheetState<T>();
}

class _ReportSheetState<T> extends State<_ReportSheet<T>> {
  static const _ink = YakkuPalette.textPrimary;
  static const _muted = YakkuPalette.textSecondary;

  final _details = TextEditingController();
  _Step _step = _Step.start;
  _ReportChoice? _picked;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final choice = _picked;
    if (choice == null || _sending) return;
    final text = _details.text.trim();
    // "Something else" sends what they typed; the others send their label.
    final reason = choice == _ReportChoice.other && text.isNotEmpty
        ? text
        : choice.label;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final value = await widget.submit(reason);
      if (!mounted) return;
      Navigator.of(context).pop(_Submitted<T>(value));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = DioErrorMapper.map(
          error,
          fallback: 'Could not send your report. Try again.',
        ).message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_sending,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Handle(),
                const SizedBox(height: 18),
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: KeyedSubtree(
                      key: ValueKey(_step),
                      child: _step == _Step.start ? _start() : _pick(),
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

  /// Sheet one: the single "Report reason" option.
  Widget _start() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Report',
          style: TextStyle(
            color: _ink,
            fontSize: 22,
            height: 1.2,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 14),
        const Divider(height: 1, thickness: 1, color: YakkuPalette.roseBorder),
        InkWell(
          onTap: () => setState(() => _step = _Step.pick),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.outlined_flag_rounded, size: 24, color: _ink),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report reason',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 16,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Tell us what's wrong. Our team checks it.",
                        style: TextStyle(
                          color: _muted,
                          fontSize: 13,
                          height: 1.3,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        _OutlinedPillButton(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  /// Sheet two: pick why, then send.
  Widget _pick() {
    final picked = _picked;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Why are you reporting this?',
          style: TextStyle(
            color: _ink,
            fontSize: 22,
            height: 1.2,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "Pick one. They'll never know it was you.",
          style: TextStyle(
            color: _muted,
            fontSize: 14,
            height: 1.35,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: [
            for (final choice in _ReportChoice.values)
              _CategoryChip(
                label: choice.label,
                selected: choice == picked,
                onTap: _sending
                    ? null
                    : () => setState(() {
                        _picked = choice;
                        _error = null;
                      }),
              ),
          ],
        ),
        if (picked == _ReportChoice.other) ...[
          const SizedBox(height: 14),
          TextField(
            controller: _details,
            enabled: !_sending,
            maxLength: reasonReportMaxLength,
            maxLines: 3,
            minLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Tell us more (optional)',
              filled: true,
              fillColor: YakkuPalette.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: YakkuPalette.roseBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: YakkuPalette.roseBorder),
              ),
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: YakkuPalette.primary,
              fontSize: 13,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 18),
        _PrimaryPillButton(
          label: 'Report',
          loading: _sending,
          onPressed: picked == null || _sending ? null : _send,
        ),
        const SizedBox(height: 10),
        _OutlinedPillButton(
          label: 'Back',
          onPressed: _sending
              ? null
              : () => setState(() {
                  _step = _Step.start;
                  _error = null;
                }),
        ),
      ],
    );
  }
}

/// Sheet three: the report went through.
class _ReportSentSheet extends StatelessWidget {
  const _ReportSentSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Handle(),
            const SizedBox(height: 18),
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: YakkuPalette.mint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 30,
                  color: YakkuPalette.successGreen,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Thanks for telling us',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: YakkuPalette.textPrimary,
                fontSize: 22,
                height: 1.2,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                'Our team will check it within 24 hours. If it breaks the '
                "rules, we'll remove it.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: YakkuPalette.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _PrimaryPillButton(
              label: 'Done',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        decoration: BoxDecoration(
          color: YakkuPalette.sheetHandle,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

/// The full-width pink action: Report, Done.
class _PrimaryPillButton extends StatelessWidget {
  const _PrimaryPillButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: YakkuPalette.primary,
        foregroundColor: YakkuPalette.white,
        disabledBackgroundColor: loading
            ? YakkuPalette.primary
            : YakkuPalette.primary.withValues(alpha: 0.4),
        disabledForegroundColor: YakkuPalette.white,
        minimumSize: const Size.fromHeight(56),
        shape: const StadiumBorder(),
      ),
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: YakkuPalette.white,
              ),
            )
          : Text(
              label,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
    );
  }
}

/// The full-width outlined action under the main one: Cancel, Back.
class _OutlinedPillButton extends StatelessWidget {
  const _OutlinedPillButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: YakkuPalette.textSecondary,
        backgroundColor: YakkuPalette.white,
        minimumSize: const Size.fromHeight(56),
        shape: const StadiumBorder(),
        side: const BorderSide(color: YakkuPalette.roseBorder, width: 1.2),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    );
  }
}

/// A pill to pick a report reason: black with a tick when picked, outlined
/// otherwise.
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  static const _night = Color(0xFF1F191C);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _night : YakkuPalette.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? _night : YakkuPalette.roseBorder,
          width: 1.2,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: YakkuPalette.white,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? YakkuPalette.white : _night,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
