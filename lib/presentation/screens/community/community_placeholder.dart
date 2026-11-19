import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/storage/preference_storage_service.dart';
import 'package:yakku/core/storage/storage_keys.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/community/community_queued_question.dart';
import 'package:yakku/data/models/personality/personality_card.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/personality/personality_navigation.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';

/// What the Community tab shows while Community is not open yet: a "notify me"
/// card, the user's early-access card (it changes with their personality
/// card: draft, collecting, completed) and a preview of what people will ask.
/// When the personality card is completed, early-access is replaced by the
/// queue-question form and list (max 3).
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

  List<CommunityQueuedQuestion> _queued = const [];
  bool _queuedLoading = false;
  bool _queuedLoaded = false;
  bool _queuedLoadScheduled = false;
  bool _showForm = false;
  String? _editingId;
  bool _queueSubmitting = false;
  final _questionController = TextEditingController();
  final Set<String> _selectedTags = {};
  String? _lastCompletedShareCode;

  @override
  void initState() {
    super.initState();
    _loadNotifyMe();
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
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

  Future<void> _refreshAll() async {
    final store = AppScope.of(context).personalityCards;
    await store.refresh();
    if (!mounted) return;
    final card = store.card;
    if (card != null && card.isCompleted) {
      await _loadQueued(force: true);
    }
  }

  Future<void> _loadQueued({bool force = false}) async {
    if (_queuedLoading) return;
    if (_queuedLoaded && !force) return;
    setState(() {
      _queuedLoading = true;
      _queuedLoadScheduled = true;
    });
    try {
      final items =
          await AppScope.of(context).userRemote.listCommunityQueuedQuestions();
      if (!mounted) return;
      setState(() {
        _queued = items;
        _queuedLoaded = true;
        _queuedLoading = false;
        _queuedLoadScheduled = false;
        if (_editingId == null) {
          _showForm = items.isEmpty;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _queuedLoading = false;
        _queuedLoadScheduled = false;
      });
      AppToast.show(
        DioErrorMapper.map(
          error,
          fallback: 'Could not load queued questions.',
        ).message,
      );
    }
  }

  void _syncQueuedForCard(PersonalityCard? card) {
    if (card == null || !card.isCompleted) {
      if (_queuedLoaded ||
          _showForm ||
          _editingId != null ||
          _lastCompletedShareCode != null ||
          _queuedLoadScheduled) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final current = AppScope.of(context).personalityCards.card;
          if (current != null && current.isCompleted) return;
          setState(() {
            _queued = const [];
            _queuedLoaded = false;
            _queuedLoadScheduled = false;
            _showForm = false;
            _editingId = null;
            _questionController.clear();
            _selectedTags.clear();
            _lastCompletedShareCode = null;
          });
        });
      }
      return;
    }

    if (_lastCompletedShareCode != card.shareCode) {
      _lastCompletedShareCode = card.shareCode;
      _queuedLoaded = false;
      _queuedLoadScheduled = false;
    }

    if (_queuedLoaded || _queuedLoadScheduled || _queuedLoading) return;

    _queuedLoadScheduled = true;
    final shareCode = card.shareCode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final current = AppScope.of(context).personalityCards.card;
      if (current == null ||
          !current.isCompleted ||
          current.shareCode != shareCode) {
        _queuedLoadScheduled = false;
        return;
      }
      _loadQueued(force: true);
    });
  }

  void _openCreateForm() {
    setState(() {
      _editingId = null;
      _questionController.clear();
      _selectedTags.clear();
      _showForm = true;
    });
  }

  void _openEditForm(CommunityQueuedQuestion item) {
    setState(() {
      _editingId = item.id;
      _questionController.text = item.question;
      _selectedTags
        ..clear()
        ..addAll(item.tags);
      _showForm = true;
    });
  }

  void _closeForm() {
    setState(() {
      _editingId = null;
      _questionController.clear();
      _selectedTags.clear();
      _showForm = _queued.isEmpty;
    });
  }

  Future<void> _submitQueueForm() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      AppToast.show('Write a question first.');
      return;
    }
    if (_selectedTags.isEmpty) {
      AppToast.show('Pick at least one topic.');
      return;
    }
    if (_queueSubmitting) return;

    setState(() => _queueSubmitting = true);
    final remote = AppScope.of(context).userRemote;
    final tags = _selectedTags.toList();
    try {
      if (_editingId == null) {
        await remote.createCommunityQueuedQuestion(
          question: question,
          tags: tags,
        );
        AppToast.show('Question queued');
      } else {
        await remote.updateCommunityQueuedQuestion(
          id: _editingId!,
          question: question,
          tags: tags,
        );
        AppToast.show('Question updated');
      }
      if (!mounted) return;
      _editingId = null;
      _questionController.clear();
      _selectedTags.clear();
      _showForm = false;
      await _loadQueued(force: true);
    } catch (error) {
      if (!mounted) return;
      AppToast.show(
        DioErrorMapper.map(
          error,
          fallback: 'Could not save your question. Please try again.',
        ).message,
      );
    } finally {
      if (mounted) setState(() => _queueSubmitting = false);
    }
  }

  Future<void> _removeQueued(CommunityQueuedQuestion item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove queued question?'),
        content: Text(item.question),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await AppScope.of(context).userRemote.deleteCommunityQueuedQuestion(
        item.id,
      );
      if (!mounted) return;
      if (_editingId == item.id) {
        _editingId = null;
        _questionController.clear();
        _selectedTags.clear();
      }
      AppToast.show('Question removed');
      await _loadQueued(force: true);
    } catch (error) {
      if (!mounted) return;
      AppToast.show(
        DioErrorMapper.map(
          error,
          fallback: 'Could not remove your question.',
        ).message,
      );
    }
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
      PersonalityCardStatus.completed => _QueuedQuestionsBlock(
        items: _queued,
        loading: _queuedLoading && !_queuedLoaded,
        showForm: _showForm || _queued.isEmpty,
        editing: _editingId != null,
        questionController: _questionController,
        selectedTags: _selectedTags,
        submitting: _queueSubmitting,
        onToggleTag: (tag) {
          setState(() {
            if (_selectedTags.contains(tag)) {
              _selectedTags.remove(tag);
            } else {
              _selectedTags.add(tag);
            }
          });
        },
        onSubmit: _submitQueueForm,
        onCancelForm: _queued.isEmpty ? null : _closeForm,
        onQueueAnother: _queued.length < CommunityQueuedQuestion.maxPerUser
            ? _openCreateForm
            : null,
        onEdit: _openEditForm,
        onRemove: _removeQueued,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).personalityCards;
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _refreshAll,
        // Rebuilds by itself whenever the personality card changes.
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final card = store.card;
            _syncQueuedForCard(card);
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

/// Completed personality: queue form and/or list of queued community questions.
class _QueuedQuestionsBlock extends StatelessWidget {
  const _QueuedQuestionsBlock({
    required this.items,
    required this.loading,
    required this.showForm,
    required this.editing,
    required this.questionController,
    required this.selectedTags,
    required this.submitting,
    required this.onToggleTag,
    required this.onSubmit,
    required this.onEdit,
    required this.onRemove,
    this.onCancelForm,
    this.onQueueAnother,
  });

  final List<CommunityQueuedQuestion> items;
  final bool loading;
  final bool showForm;
  final bool editing;
  final TextEditingController questionController;
  final Set<String> selectedTags;
  final bool submitting;
  final ValueChanged<String> onToggleTag;
  final VoidCallback onSubmit;
  final VoidCallback? onCancelForm;
  final VoidCallback? onQueueAnother;
  final ValueChanged<CommunityQueuedQuestion> onEdit;
  final ValueChanged<CommunityQueuedQuestion> onRemove;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (items.isNotEmpty) ...[
          for (final item in items) ...[
            _QueuedQuestionCard(
              item: item,
              onEdit: () => onEdit(item),
              onRemove: () => onRemove(item),
            ),
            const SizedBox(height: 12),
          ],
          if (onQueueAnother != null && !showForm) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onQueueAnother,
                style: TextButton.styleFrom(
                  foregroundColor: YakkuPalette.Raspberry,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '+ Queue another (up to ${CommunityQueuedQuestion.maxPerUser})',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
        if (showForm)
          _QueueQuestionForm(
            editing: editing,
            controller: questionController,
            selectedTags: selectedTags,
            submitting: submitting,
            onToggleTag: onToggleTag,
            onSubmit: onSubmit,
            onCancel: onCancelForm,
          ),
      ],
    );
  }
}

class _QueueQuestionForm extends StatelessWidget {
  const _QueueQuestionForm({
    required this.editing,
    required this.controller,
    required this.selectedTags,
    required this.submitting,
    required this.onToggleTag,
    required this.onSubmit,
    this.onCancel,
  });

  final bool editing;
  final TextEditingController controller;
  final Set<String> selectedTags;
  final bool submitting;
  final ValueChanged<String> onToggleTag;
  final VoidCallback onSubmit;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: YakkuPalette.pillPink,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: YakkuPalette.Ink, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'ASK THE COMMUNITY',
                style: TextStyle(
                  color: YakkuPalette.Raspberry,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: YakkuPalette.Gold,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Text(
                    'Goes live on day one',
                    style: TextStyle(
                      color: YakkuPalette.Ink,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            editing
                ? 'Edit your question for the community'
                : 'Queue a question for the community',
            style: const TextStyle(
              color: YakkuPalette.Ink,
              fontSize: 26,
              height: 1.12,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ask what you can’t ask your friends. It goes live the moment Community opens. Strangers see your traits, never your name.',
            style: TextStyle(
              color: YakkuPalette.bodyInk,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            maxLength: CommunityQueuedQuestion.questionMaxLength,
            maxLines: 4,
            minLines: 3,
            style: const TextStyle(
              color: YakkuPalette.Ink,
              fontSize: 15,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: 'What do you want to ask people beyond your circle?',
              hintStyle: const TextStyle(
                color: YakkuPalette.placeholder,
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: YakkuPalette.white,
              contentPadding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: YakkuPalette.Ink, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: YakkuPalette.Ink, width: 1.6),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: YakkuPalette.Ink, width: 1.2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Topic',
            style: TextStyle(
              color: YakkuPalette.Ink,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in CommunityQueuedQuestionCategories.all)
                _TopicPill(
                  label: CommunityQueuedQuestionCategories.label(tag),
                  selected: selectedTags.contains(tag),
                  onTap: () => onToggleTag(tag),
                ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: submitting ? null : onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: YakkuPalette.Raspberry,
                foregroundColor: YakkuPalette.white,
                disabledBackgroundColor: YakkuPalette.Raspberry.withValues(
                  alpha: 0.45,
                ),
                shape: const StadiumBorder(),
              ),
              child: Text(
                submitting
                    ? 'Saving…'
                    : editing
                        ? 'Save changes'
                        : 'Queue my question',
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          if (onCancel != null) ...[
            const SizedBox(height: 6),
            Center(
              child: TextButton(
                onPressed: submitting ? null : onCancel,
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: YakkuPalette.Ink,
                    fontWeight: FontWeight.w700,
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

class _TopicPill extends StatelessWidget {
  const _TopicPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? YakkuPalette.Ink : YakkuPalette.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: selected
                ? null
                : Border.all(color: YakkuPalette.Ink.withValues(alpha: 0.18)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? YakkuPalette.white : YakkuPalette.Ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _QueuedQuestionCard extends StatelessWidget {
  const _QueuedQuestionCard({
    required this.item,
    required this.onEdit,
    required this.onRemove,
  });

  final CommunityQueuedQuestion item;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final traitLabel = item.personalityTraits
        .map((trait) => trait.name)
        .where((name) => name.trim().isNotEmpty)
        .join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: YakkuPalette.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: YakkuPalette.Ink, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'YOUR QUEUED QUESTION',
                  style: TextStyle(
                    color: YakkuPalette.Raspberry,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.45,
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: YakkuPalette.accentGreen,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: YakkuPalette.forestGreen,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Queued',
                        style: TextStyle(
                          color: YakkuPalette.forestGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            item.question,
            style: const TextStyle(
              color: YakkuPalette.Ink,
              fontSize: 22,
              height: 1.18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.55,
            ),
          ),
          if (item.tags.isNotEmpty || traitLabel.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in item.tags)
                  _Chip(
                    label: CommunityQueuedQuestionCategories.label(tag),
                    background: YakkuPalette.Ink,
                    foreground: YakkuPalette.white,
                  ),
                if (traitLabel.isNotEmpty)
                  _Chip(
                    label: traitLabel,
                    background: YakkuPalette.accentPurple,
                    foreground: YakkuPalette.purpleInk,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          const Text(
            'Goes live the day Community opens. We’ll tell you when the first answer comes in.',
            style: TextStyle(
              color: YakkuPalette.textSecondary,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: YakkuPalette.Ink,
                    side: const BorderSide(color: YakkuPalette.Ink, width: 1.3),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Edit',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onRemove,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: YakkuPalette.Ink,
                    side: const BorderSide(color: YakkuPalette.Ink, width: 1.3),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Remove',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          label,
          style: TextStyle(
            color: foreground,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
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
