import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/personality/personality_card.dart';
import 'package:yakku/presentation/screens/personality/personality_navigation.dart';
import 'package:yakku/presentation/screens/personality/personality_share_screen.dart';
import 'package:yakku/presentation/widgets/personality_own_locked_view.dart';

/// Owner progress / locked-results screen.
///
/// With [celebration] true (ready push only): shows the "results are ready"
/// panel and confetti. Without it, collecting cards show vote progress; this
/// screen is not used for completed cards outside the ready push.
class PersonalityCardProgressScreen extends StatefulWidget {
  const PersonalityCardProgressScreen({
    super.key,
    required this.card,
    required this.traits,
    this.celebration = false,
  });

  final PersonalityCard card;
  final List<PersonalityTrait> traits;

  /// Push-only "Who you are is in" entry: confetti + ready panel.
  final bool celebration;

  @override
  State<PersonalityCardProgressScreen> createState() =>
      _PersonalityCardProgressScreenState();
}

class _PersonalityCardProgressScreenState
    extends State<PersonalityCardProgressScreen> {
  bool _busy = false;

  List<String> get _traitNames => [
    for (final trait in widget.traits) trait.name,
  ];

  PersonalityCardStatus get _displayStatus {
    if (widget.celebration) return PersonalityCardStatus.completed;
    return widget.card.status;
  }

  Future<void> _shareAgain() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => PersonalityShareScreen(
            shareCode: widget.card.shareCode,
            minVotes: widget.card.requiredVotes,
            traits: _traitNames,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _viewResults() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (!mounted) return;
      await openPersonalityResult(context, widget.card);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _makeGuess() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (!mounted) return;
      await openPersonalityAsk(context, widget.card, widget.traits);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YakkuPalette.cream,
      appBar: AppBar(
        backgroundColor: YakkuPalette.cream,
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.celebration ? 'Your results are ready' : 'Your card',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: PersonalityOwnLockedView(
          status: _displayStatus,
          totalVotes: widget.card.totalVotes,
          requiredVotes: widget.card.requiredVotes,
          traitNames: _traitNames,
          busy: _busy,
          showConfetti: widget.celebration,
          onMakeGuess: _busy || widget.celebration ? null : _makeGuess,
          onShareAgain: _busy || widget.celebration ? null : _shareAgain,
          onViewResults: _busy ? null : _viewResults,
        ),
      ),
    );
  }
}
