import 'package:flutter/material.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/theme/yakku_palette.dart';

/// What the user can say happened. The label picked is sent to the API as the
/// report reason; the server keeps no list of its own.
const List<String> blockReportReasons = <String>[
  'Harassing me',
  'Trying to find out who I am',
  'Sexual messages',
  'Hate or slurs',
  'Spam or scam',
  'Something else',
];

/// The block flow, in one bottom sheet with two steps:
///
/// 1. "Report" with a red "Block" row and Cancel;
/// 2. "What happened?" with one reason to pick, a Block button and Back.
///
/// Blocking always sends a report, so a reason is required. [submit] gets the
/// label of the reason and blocks. When it throws, the sheet stays open and
/// shows the error so the user can try again. Returns true once [submit]
/// succeeded, false when the user backed out.
Future<bool> showBlockFlow(
  BuildContext context, {
  required Future<void> Function(String reason) submit,
}) async {
  final blocked = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: YakkuPalette.white,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (_) => BlockReportSheet(submit: submit),
  );
  return blocked ?? false;
}

enum _Step { start, pick }

class BlockReportSheet extends StatefulWidget {
  const BlockReportSheet({super.key, required this.submit});

  final Future<void> Function(String reason) submit;

  @override
  State<BlockReportSheet> createState() => _BlockReportSheetState();
}

class _BlockReportSheetState extends State<BlockReportSheet> {
  static const _ink = YakkuPalette.textPrimary;
  static const _muted = YakkuPalette.textSecondary;

  _Step _step = _Step.start;
  String? _picked;
  bool _sending = false;
  String? _error;

  Future<void> _block() async {
    final reason = _picked;
    if (reason == null || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.submit(reason);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = DioErrorMapper.map(
          error,
          fallback: 'Could not block this person. Try again.',
        ).message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_sending,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: YakkuPalette.sheetHandle,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
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
    );
  }

  Widget _title(String text) => Text(
    text,
    style: const TextStyle(
      color: _ink,
      fontSize: 22,
      height: 1.2,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.4,
    ),
  );

  /// Step one: the red "Block" row.
  Widget _start() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title('Report'),
        const SizedBox(height: 14),
        const Divider(height: 1, thickness: 1, color: YakkuPalette.roseBorder),
        InkWell(
          key: const ValueKey('block-row'),
          onTap: () => setState(() => _step = _Step.pick),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.block_rounded,
                    size: 24,
                    color: YakkuPalette.error,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Block',
                        style: TextStyle(
                          color: YakkuPalette.error,
                          fontSize: 16,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Ends this chat and reports them to our team. They '
                        "won't be told.",
                        style: TextStyle(
                          color: _muted,
                          fontSize: 13,
                          height: 1.3,
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
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }

  /// Step two: pick what happened, then block.
  Widget _pick() {
    final picked = _picked;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title('What happened?'),
        const SizedBox(height: 6),
        const Text(
          "Pick one. They'll never know it was you.",
          style: TextStyle(color: _muted, fontSize: 14, height: 1.35),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: [
            for (final reason in blockReportReasons)
              _ReasonChip(
                label: reason,
                selected: reason == picked,
                onTap: _sending
                    ? null
                    : () => setState(() {
                        _picked = reason;
                        _error = null;
                      }),
              ),
          ],
        ),
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
        FilledButton(
          key: const ValueKey('block-confirm'),
          onPressed: picked == null || _sending ? null : _block,
          style: FilledButton.styleFrom(
            backgroundColor: YakkuPalette.primary,
            foregroundColor: YakkuPalette.white,
            disabledBackgroundColor: _sending
                ? YakkuPalette.primary
                : YakkuPalette.primary.withValues(alpha: 0.4),
            disabledForegroundColor: YakkuPalette.white,
            minimumSize: const Size.fromHeight(56),
            shape: const StadiumBorder(),
          ),
          child: _sending
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: YakkuPalette.white,
                  ),
                )
              : const Text(
                  'Block',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
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

/// A pill to pick a reason: dark with a tick when picked, outlined otherwise.
class _ReasonChip extends StatelessWidget {
  const _ReasonChip({
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
