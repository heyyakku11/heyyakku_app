import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/storage/preference_storage_service.dart';
import 'package:yakku/core/storage/storage_keys.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/personality/personality_card.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/personality/personality_navigation.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';

/// What the Community tab shows while Community is not open yet: a "notify me"
/// card, the user's early-access card (it changes with their personality
/// card: draft, collecting, completed) and a preview of what people will ask.
class CommunityPlaceholder extends StatefulWidget {
  const CommunityPlaceholder({super.key, this.showTitle = true});

  /// The big "Community" heading; hidden where the screen already has a header.
  final bool showTitle;

  @override
  State<CommunityPlaceholder> createState() => _CommunityPlaceholderState();
}

class _CommunityPlaceholderState extends State<CommunityPlaceholder> {
  static const _samples = [
    _SampleQuestion(
      topic: 'FRIENDSHIPS',
      question:
          'My best friend tries to flirt with my girlfriend. Do I say something?',
      meta: '36 answers · from people who’ve been there',
    ),
    _SampleQuestion(
      topic: 'MOVING CITIES',
      question: 'Moved cities alone at 22. When did it stop feeling lonely?',
      meta: '52 answers',
    ),
    _SampleQuestion(
      topic: 'CAREER',
      question:
          'I earn well but hate my job. People who quit, what happened next?',
      meta: '41 answers',
    ),
    _SampleQuestion(
      topic: 'FAMILY',
      question: 'How did you tell your parents you’re dropping out?',
      meta: '27 answers',
    ),
  ];

  final _prefs = PreferenceStorageService();

  /// Whether the user asked to be notified when Community opens. False until they do; set from the
  /// login response and kept on this device.
  bool _notifyMe = false;
  bool _notifySubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadNotifyMe();
  }

  Future<void> _loadNotifyMe() async {
    try {
      final value = await _prefs.readBool(StorageKeys.communityNotifyMe);
      if (!mounted || value == null) return;
      setState(() => _notifyMe = value);
    } catch (_) {}
  }

  Future<void> _setNotifyMe() async {
    if (_notifyMe || _notifySubmitting) return;
    HapticFeedback.selectionClick();
    final userRemote = AppScope.of(context).userRemote;
    setState(() => _notifySubmitting = true);
    try {
      await userRemote.joinCommunityWaitlist();
      try {
        await _prefs.updateBool(StorageKeys.communityNotifyMe, true);
      } catch (_) {
        // Only the local copy is lost; the server has the request.
      }
      if (!mounted) return;
      setState(() => _notifyMe = true);
      AppToast.show('We’ll let you know when Community opens');
    } catch (error) {
      if (!mounted) return;
      AppToast.show(
        DioErrorMapper.map(
          error,
          fallback: 'Could not save your request. Please try again.',
        ).message,
      );
    } finally {
      if (mounted) setState(() => _notifySubmitting = false);
    }
  }

  Future<void> _askNow() async {
    final store = AppScope.of(context).personalityCards;
    final card = store.card;
    if (card == null) return;
    await openPersonalityAsk(context, card, store.traits);
  }

  Widget _earlyAccess(PersonalityCard card, List<PersonalityTrait> traits) {
    return switch (card.status) {
      PersonalityCardStatus.draft => _DraftEarlyAccess(
        card: card,
        traits: traits,
        onAskNow: _askNow,
      ),
      PersonalityCardStatus.collecting => _CollectingEarlyAccess(
        card: card,
        onAskNow: _askNow,
      ),
      PersonalityCardStatus.completed => _CompletedEarlyAccess(card: card),
    };
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).personalityCards;
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: store.refresh,
        // Rebuilds by itself whenever the personality card changes.
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final card = store.card;
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              children: [
                if (widget.showTitle) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Community',
                      style: TextStyle(
                        color: YakkuPalette.Ink,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.9,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                _NotifyCard(
                  notifying: _notifyMe,
                  busy: _notifySubmitting,
                  onNotify: _setNotifyMe,
                ),
                if (card != null) ...[
                  const SizedBox(height: 14),
                  _earlyAccess(card, store.traits),
                ],
                const SizedBox(height: 22),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'What people will ask here',
                    style: TextStyle(
                      color: YakkuPalette.Ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                for (final sample in _samples) ...[
                  _SampleCard(sample: sample),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The dark "Ask the community…" card: a locked question box and the notify
/// button.
class _NotifyCard extends StatelessWidget {
  const _NotifyCard({
    required this.notifying,
    required this.onNotify,
    this.busy = false,
  });

  /// The user already asked to be notified: the button shows that and stays off.
  final bool notifying;

  /// The request is being sent.
  final bool busy;
  final VoidCallback onNotify;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: YakkuPalette.Ink,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: YakkuPalette.Raspberry, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: YakkuPalette.Gold,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Text(
                    'COMING SOON',
                    style: TextStyle(
                      color: YakkuPalette.Ink,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Transform.rotate(
                angle: -0.07,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: YakkuPalette.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: const [
                      BoxShadow(
                        color: YakkuPalette.Raspberry,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    child: Text(
                      'No judgement.',
                      style: TextStyle(
                        fontFamily: 'Pacifico',
                        color: YakkuPalette.Raspberry,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Ask the community what you can’t ask your friends',
            style: TextStyle(
              color: YakkuPalette.white,
              fontSize: 24,
              height: 1.1,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 14),
          // A preview of the question box: locked until Community opens.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: YakkuPalette.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 15,
                  color: YakkuPalette.white.withValues(alpha: 0.55),
                ),
                const SizedBox(width: 10),
                Text(
                  'Ask the community…',
                  style: TextStyle(
                    color: YakkuPalette.white.withValues(alpha: 0.55),
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: (notifying || busy) ? null : onNotify,
              style: FilledButton.styleFrom(
                backgroundColor: YakkuPalette.Gold,
                disabledBackgroundColor: YakkuPalette.Gold.withValues(
                  alpha: 0.85,
                ),
                foregroundColor: YakkuPalette.Ink,
                disabledForegroundColor: YakkuPalette.Ink,
                shape: const StadiumBorder(),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (busy)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: YakkuPalette.Ink,
                      ),
                    )
                  else
                    Icon(
                      notifying
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_none_rounded,
                      size: 18,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    busy
                        ? 'Saving…'
                        : notifying
                        ? 'We’ll notify you'
                        : 'Notify me when it opens',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Draft: the user has not described themselves yet, so the card asks for 5
/// friends and shows the traits friends will pick from.
class _DraftEarlyAccess extends StatelessWidget {
  const _DraftEarlyAccess({
    required this.card,
    required this.traits,
    required this.onAskNow,
  });

  static const _visibleChips = 3;

  final PersonalityCard card;
  final List<PersonalityTrait> traits;
  final VoidCallback onAskNow;

  @override
  Widget build(BuildContext context) {
    final needed = card.requiredVotes;
    final shown = traits.take(_visibleChips).toList();
    final more = traits.length - shown.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: YakkuPalette.Raspberry,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: YakkuPalette.Ink, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: YakkuPalette.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Text(
                    'EARLY ACCESS',
                    style: TextStyle(
                      color: YakkuPalette.Raspberry,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${card.totalVotes} of $needed friends',
                style: TextStyle(
                  color: YakkuPalette.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Let $needed friends describe you to get early access',
            style: const TextStyle(
              color: YakkuPalette.white,
              fontSize: 23,
              height: 1.1,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          if (traits.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Friends pick 3 of these ${traits.length}.',
              style: TextStyle(
                color: YakkuPalette.white.withValues(alpha: 0.85),
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final trait in shown) _OutlineChip(label: trait.name),
                if (more > 0) _MoreChip(label: '+$more more'),
              ],
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: onAskNow,
              style: FilledButton.styleFrom(
                backgroundColor: YakkuPalette.white,
                foregroundColor: YakkuPalette.Ink,
                shape: const StadiumBorder(),
              ),
              child: const Text(
                'Ask now',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineChip extends StatelessWidget {
  const _OutlineChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: YakkuPalette.white.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: YakkuPalette.white,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MoreChip extends StatelessWidget {
  const _MoreChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: YakkuPalette.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: YakkuPalette.Raspberry,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Collecting: the slim white card with the progress towards early access.
class _CollectingEarlyAccess extends StatelessWidget {
  const _CollectingEarlyAccess({required this.card, required this.onAskNow});

  final PersonalityCard card;
  final VoidCallback onAskNow;

  @override
  Widget build(BuildContext context) {
    final needed = card.requiredVotes;
    final remaining = (needed - card.totalVotes).clamp(0, needed);

    return _SlimCard(
      done: card.totalVotes,
      needed: needed,
      counter: '${card.totalVotes} of $needed',
      note:
          '$remaining more ${remaining == 1 ? 'friend' : 'friends'} to '
          'describe you and you’re in.',
      button: 'Ask friends to describe me',
      onButton: onAskNow,
    );
  }
}

/// Completed: the user is in; there is nothing left to do.
class _CompletedEarlyAccess extends StatelessWidget {
  const _CompletedEarlyAccess({required this.card});

  final PersonalityCard card;

  @override
  Widget build(BuildContext context) {
    final needed = card.requiredVotes;
    return _SlimCard(
      done: needed,
      needed: needed,
      counter: '$needed of $needed',
      note: 'You’re in. We’ll tell you the moment Community opens.',
    );
  }
}

class _SlimCard extends StatelessWidget {
  const _SlimCard({
    required this.done,
    required this.needed,
    required this.counter,
    required this.note,
    this.button,
    this.onButton,
  });

  final int done;
  final int needed;
  final String counter;
  final String note;
  final String? button;
  final VoidCallback? onButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: YakkuPalette.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: YakkuPalette.roseBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Get early access',
                style: TextStyle(
                  color: YakkuPalette.Ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                counter,
                style: const TextStyle(
                  color: YakkuPalette.Raspberry,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (needed > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                for (var i = 0; i < needed; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      height: 7,
                      decoration: BoxDecoration(
                        color: i < done
                            ? YakkuPalette.Raspberry
                            : YakkuPalette.pinkWash.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 10),
          Text(
            note,
            style: const TextStyle(
              color: YakkuPalette.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          if (button != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: onButton,
                style: FilledButton.styleFrom(
                  backgroundColor: YakkuPalette.Raspberry,
                  foregroundColor: YakkuPalette.white,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  button!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SampleQuestion {
  const _SampleQuestion({
    required this.topic,
    required this.question,
    required this.meta,
  });

  final String topic;
  final String question;
  final String meta;
}

/// A question people will be asking once Community opens.
class _SampleCard extends StatelessWidget {
  const _SampleCard({required this.sample});

  final _SampleQuestion sample;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: YakkuPalette.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: YakkuPalette.roseBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sample.topic,
            style: const TextStyle(
              color: YakkuPalette.Ink,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            sample.question,
            style: const TextStyle(
              color: YakkuPalette.Ink,
              fontSize: 16.5,
              height: 1.2,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            sample.meta,
            style: const TextStyle(
              color: YakkuPalette.textSecondary,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}
