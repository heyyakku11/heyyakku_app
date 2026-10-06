import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yakku/data/models/poll/draft_poll.dart';

class DraftPollStore extends ChangeNotifier {
  Isar? _isar;
  List<DraftPoll> _drafts = const [];

  List<DraftPoll> get drafts => List.unmodifiable(_drafts);

  bool get isReady => _isar != null && _isar!.isOpen;

  Future<void> open() async {
    if (isReady) return;
    final existing = Isar.getInstance('yakku_drafts');
    if (existing != null && existing.isOpen) {
      _isar = existing;
      await _reload();
      return;
    }
    final directory = await getApplicationDocumentsDirectory();
    try {
      _isar = await _openAt(directory.path);
    } on IsarError catch (error) {
      if (!error.toString().toLowerCase().contains('schema')) rethrow;
      await _deleteDatabase(directory.path);
      _isar = await _openAt(directory.path);
    }
    await _reload();
  }

  Future<Isar> _openAt(String directory) {
    return Isar.open(
      [DraftPollSchema],
      directory: directory,
      name: 'yakku_drafts',
      inspector: false,
    );
  }

  Future<void> _deleteDatabase(String directory) async {
    for (final name in ['yakku_drafts.isar', 'yakku_drafts.isar.lock']) {
      final file = File('$directory${Platform.pathSeparator}$name');
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<void> save({
    required String question,
    required List<String> options,
    required int expiryDays,
    required bool allowComments,
    List<String> categoryIds = const [],
  }) async {
    final isar = _requireOpen();
    final draft = DraftPoll()
      ..question = question.trim()
      ..options = options
          .map((option) => option.trim())
          .where((option) => option.isNotEmpty)
          .toList(growable: false)
      ..expiryDays = expiryDays
      ..allowComments = allowComments
      ..categoryIds = categoryIds
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toList(growable: false)
      ..updatedAt = DateTime.now();

    await isar.writeTxn(() => isar.draftPolls.put(draft));
    await _reload();
  }

  Future<void> clearAll() async {
    final isar = _requireOpen();
    await isar.writeTxn(() => isar.draftPolls.clear());
    await _reload();
  }

  Future<void> delete(int id) async {
    final isar = _requireOpen();
    await isar.writeTxn(() => isar.draftPolls.delete(id));
    await _reload();
  }

  /// Reads one draft and deletes it in the same write.
  Future<DraftPoll?> take(int id) async {
    final isar = _requireOpen();
    final removed = await isar.writeTxn(() async {
      final draft = await isar.draftPolls.get(id);
      if (draft == null) return null;
      final copy = DraftPoll()
        ..id = draft.id
        ..question = draft.question
        ..options = List<String>.from(draft.options)
        ..expiryDays = draft.expiryDays
        ..allowComments = draft.allowComments
        ..categoryIds = List<String>.from(draft.categoryIds)
        ..updatedAt = draft.updatedAt;
      await isar.draftPolls.delete(id);
      return copy;
    });
    if (removed != null) {
      await _reload();
    }
    return removed;
  }

  Future<void> close() async {
    final isar = _isar;
    _isar = null;
    _drafts = const [];
    if (isar != null && isar.isOpen) {
      await isar.close();
    }
  }

  Future<void> _reload() async {
    final isar = _requireOpen();
    final items = await isar.draftPolls.where().findAll();
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _drafts = List<DraftPoll>.unmodifiable(items);
    notifyListeners();
  }

  Isar _requireOpen() {
    final isar = _isar;
    if (isar == null || !isar.isOpen) {
      throw StateError('DraftPollStore is not open');
    }
    return isar;
  }
}
