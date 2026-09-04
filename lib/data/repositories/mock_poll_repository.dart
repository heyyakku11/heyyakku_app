import 'package:flutter/foundation.dart';
import 'package:yakku/core/constants/app_limits.dart';
import 'package:yakku/data/datasources/mock_poll_local_datasource.dart';
import 'package:yakku/domain/entities/anonymous_user.dart';
import 'package:yakku/domain/entities/poll.dart';
import 'package:yakku/domain/entities/poll_option.dart';
import 'package:yakku/domain/enums/poll_duration.dart';
import 'package:yakku/domain/enums/poll_status.dart';
import 'package:yakku/domain/repositories/poll_repository.dart';

class MockPollRepository extends ChangeNotifier implements PollRepository {
  MockPollRepository({MockPollLocalDataSource? dataSource})
    : _data = dataSource ?? MockPollLocalDataSource();

  final MockPollLocalDataSource _data;
  int _id = 100;

  String _nextId(String prefix) => '$prefix-${_id++}';

  @override
  List<Poll> getFeed({String query = ''}) {
    final normalized = query.trim().toLowerCase();
    final items = List<Poll>.from(_data.polls)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (normalized.isEmpty) return items;
    return items
        .where((poll) => poll.question.toLowerCase().contains(normalized))
        .toList();
  }

  @override
  List<Poll> getMyPolls() {
    return _data.polls
        .where((poll) => poll.creatorId == MockPollLocalDataSource.currentUserId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Poll? getPoll(String id) {
    for (final poll in _data.polls) {
      if (poll.id == id) return poll;
    }
    return null;
  }

  @override
  AnonymousUser getCurrentUser() => _data.currentUser;

  @override
  void vote(String pollId, String optionId) {
    final index = _data.polls.indexWhere((poll) => poll.id == pollId);
    if (index < 0) return;
    final poll = _data.polls[index];
    final selected = Set<String>.from(poll.selectedOptionIds);

    if (poll.allowMultipleAnswers) {
      if (selected.contains(optionId)) {
        selected.remove(optionId);
      } else {
        selected.add(optionId);
      }
    } else {
      if (selected.contains(optionId) && selected.length == 1) {
        selected.clear();
      } else {
        selected
          ..clear()
          ..add(optionId);
      }
    }

    final updatedOptions = [
      for (final option in poll.options)
        option.copyWith(
          voteCount: _adjustedCount(
            option: option,
            previous: poll.selectedOptionIds,
            next: selected,
          ),
        ),
    ];

    _data.polls[index] = poll.copyWith(
      options: updatedOptions,
      selectedOptionIds: selected,
    );

    notifyListeners();
  }

  @override
  void voteSomethingElse(String pollId, String optionId, String customText) {
    vote(pollId, optionId);
    final trimmed = customText.trim();
    if (trimmed.isEmpty) return;
    final index = _data.polls.indexWhere((poll) => poll.id == pollId);
    if (index < 0) return;
    final poll = _data.polls[index];
    _data.polls[index] = poll.copyWith(
      options: [
        for (final option in poll.options)
          option.id == optionId && option.isSomethingElse
              ? option.copyWith(text: trimmed)
              : option,
      ],
    );
    notifyListeners();
  }

  int _adjustedCount({
    required PollOption option,
    required Set<String> previous,
    required Set<String> next,
  }) {
    var count = option.voteCount;
    final wasSelected = previous.contains(option.id);
    final isSelected = next.contains(option.id);
    if (!wasSelected && isSelected) count += 1;
    if (wasSelected && !isSelected) count = count > 0 ? count - 1 : 0;
    return count;
  }

  @override
  void createPoll({
    required String question,
    required List<String> options,
    required bool isAnonymous,
    required bool allowMultipleAnswers,
    required PollDuration duration,
  }) {
    final id = _nextId('poll');
    final now = DateTime.now();
    final poll = Poll(
      id: id,
      creatorId: MockPollLocalDataSource.currentUserId,
      question: question.trim(),
      createdAt: now,
      expiresAt: now.add(duration.duration),
      status: PollStatus.active,
      isAnonymous: isAnonymous,
      allowMultipleAnswers: allowMultipleAnswers,
      options: [
        for (var i = 0; i < options.length; i++)
          PollOption(
            id: _nextId('opt'),
            pollId: id,
            text: options[i].trim(),
            position: i,
          ),
        PollOption(
          id: _nextId('opt'),
          pollId: id,
          text: AppLimits.somethingElseLabel,
          position: options.length,
          isSomethingElse: true,
        ),
      ],
    );
    _data.polls.insert(0, poll);
    final user = _data.currentUser;
    _data.currentUser = user.copyWith(questionsCount: user.questionsCount + 1);
    notifyListeners();
  }

  @override
  void updateProfile({String? displayName}) {
    if (displayName == null) return;
    _data.currentUser = _data.currentUser.copyWith(
      displayName: displayName.trim().isEmpty
          ? 'Anonymous User'
          : displayName.trim(),
    );
    notifyListeners();
  }
}
