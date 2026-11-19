import 'package:flutter/material.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/ask_back/ask_back_models.dart';

/// Asks the owner to unlock a card for Ask Back, or explains why they cannot.
///
/// [unlock] spends a plan ticket on the card. It is only offered when
/// [AskBackAccess.canUnlock]; otherwise the sheet explains what the plan
/// allows (free plan, no tickets left, plan ended). When [unlock] throws, the
/// sheet stays open and shows the error. Returns true once the card is open
/// for asking back, null or false when the owner backed out.
Future<bool?> showAskBackUnlockSheet(
  BuildContext context, {
  required AskBackAccess access,
  required Future<AskBackAccess> Function() unlock,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: YakkuPalette.white,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (_) => AskBackUnlockSheet(access: access, unlock: unlock),
  );
}

class AskBackUnlockSheet extends StatefulWidget {
  const AskBackUnlockSheet({
    super.key,
    required this.access,
    required this.unlock,
  });

  final AskBackAccess access;
  final Future<AskBackAccess> Function() unlock;

  @override
  State<AskBackUnlockSheet> createState() => _AskBackUnlockSheetState();
}

class _AskBackUnlockSheetState extends State<AskBackUnlockSheet> {
  bool _working = false;
  String? _error;

  Future<void> _unlock() async {
    if (_working) return;
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await widget.unlock();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _working = false;
        _error = DioErrorMapper.map(
          error,
          fallback: 'Could not unlock this card. Try again.',
        ).message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = _SheetCopy.of(widget.access);
    return PopScope(
      canPop: !_working,
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
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: YakkuPalette.pillPink,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    copy.canUnlock
                        ? Icons.lock_open_rounded
                        : Icons.lock_outline_rounded,
                    size: 28,
                    color: YakkuPalette.primary,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                copy.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: YakkuPalette.textPrimary,
                  fontSize: 22,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  copy.body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: YakkuPalette.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
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
              const SizedBox(height: 20),
              if (copy.canUnlock) ...[
                FilledButton(
                  onPressed: _working ? null : _unlock,
                  style: FilledButton.styleFrom(
                    backgroundColor: YakkuPalette.primary,
                    foregroundColor: YakkuPalette.white,
                    disabledBackgroundColor: YakkuPalette.primary,
                    disabledForegroundColor: YakkuPalette.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: const StadiumBorder(),
                  ),
                  child: _working
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: YakkuPalette.white,
                          ),
                        )
                      : const Text(
                          'Unlock card',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
                const SizedBox(height: 10),
              ],
              OutlinedButton(
                onPressed: _working
                    ? null
                    : () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: YakkuPalette.textSecondary,
                  backgroundColor: YakkuPalette.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: const StadiumBorder(),
                  side: const BorderSide(
                    color: YakkuPalette.roseBorder,
                    width: 1.2,
                  ),
                ),
                child: Text(
                  copy.canUnlock ? 'Not now' : 'Close',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The wording for each situation the owner can be in.
class _SheetCopy {
  const _SheetCopy(this.title, this.body, {this.canUnlock = false});

  final String title;
  final String body;
  final bool canUnlock;

  static const List<String> _months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String _date(DateTime value) {
    final local = value.toLocal();
    return '${local.day} ${_months[local.month - 1]}';
  }

  static _SheetCopy of(AskBackAccess access) {
    final ends = access.planExpiresAt;
    if (access.planExpired || access.paused) {
      return _SheetCopy(
        'Your plan has ended',
        '${access.planName} ended${ends == null ? '' : ' on ${_date(ends)}'}. '
            'Chats you started with it are paused. Renew a plan to keep '
            'asking back.',
      );
    }
    if (access.canUnlock) {
      final tickets = access.ticketsLeft;
      final left = tickets == null
          ? 'Your plan has unlimited unlocks.'
          : '$tickets ${tickets == 1 ? 'ticket' : 'tickets'} left on your plan.';
      final until = ends == null ? '' : ' Valid until ${_date(ends)}.';
      return _SheetCopy(
        'Unlock this card',
        'Unlock every reason on this card to ask back. $left$until',
        canUnlock: true,
      );
    }
    if (access.isFreePlan) {
      return const _SheetCopy(
        'Unlock this card',
        'The free plan includes one ask back per card, on the top reason of '
            'one option. To ask back on any reason, unlock this card or get '
            'Yakku Lite or Yakku Love.',
      );
    }
    return _SheetCopy(
      'No unlocks left',
      'You have used every card unlock on ${access.planName}. Get a new plan '
          'or unlock this card on its own to ask back on every reason.',
    );
  }
}
