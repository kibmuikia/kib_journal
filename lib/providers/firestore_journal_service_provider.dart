import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:kib_journal/core/errors/exceptions.dart';
import 'package:kib_journal/data/models/journal_entry.dart' show JournalEntry;
import 'package:kib_journal/di/setup.dart';
import 'package:kib_journal/firebase_services/firestore_journal_entries_service.dart';
import 'package:kib_utils/kib_utils.dart';

enum JournalStatus {
  initial,
  loading,
  loaded,
  error;

  bool get isInitial => this == JournalStatus.initial;
  bool get isLoading => this == JournalStatus.loading;
  bool get isLoaded => this == JournalStatus.loaded;
  bool get isError => this == JournalStatus.error;
}

class FirestoreJournalServiceProvider extends ChangeNotifier {
  late final FirestoreJournalEntriesService _journalEntriesService;

  FirestoreJournalServiceProvider() {
    _journalEntriesService = getIt<FirestoreJournalEntriesService>();
  }

  JournalStatus _status = JournalStatus.initial;
  List<JournalEntry> _journalEntries = [];
  String? _errorMessage;
  StreamSubscription<List<JournalEntry>>? _journalEntriesSubscription;

  JournalStatus get status => _status;
  List<JournalEntry> get journalEntries => _journalEntries;
  String? get errorMessage => _errorMessage;

  Future<void> init() async {
    if (!_status.isLoading) {
      await loadCurrentUserJournalEntries(refresh: true);
      // TODO: call _setupJournalEntriesStream
    }
  }

  Future<void> loadCurrentUserJournalEntries({bool refresh = false}) async {
    _status = JournalStatus.loading;
    _errorMessage = null;
    if (refresh) {
      _journalEntries = [];
    }
    notifyListeners();

    try {
      final result =
          await _journalEntriesService.getCurrentUserJournalEntries();
      switch (result) {
        case Success(value: final entries):
          _journalEntries = entries;
          if (refresh) {
            _journalEntries = entries;
          } else {
            _journalEntries =
                [..._journalEntries, ...entries]
                    .groupFoldBy((e) => e.id, (previous, element) => element)
                    .values
                    .toList();
          }
          _status = JournalStatus.loaded;
          break;
        case Failure(error: final Exception e):
          _status = JournalStatus.error;
          _errorMessage =
              e is UnauthorizedException
                  ? 'You are Unauthorized'
                  : e is ExceptionX
                  ? e.message
                  : e.toString();
          break;
      }
    } catch (err) {
      _status = JournalStatus.error;
      _errorMessage = err.toString();
    } finally {
      notifyListeners();
    }
  }

  // TODO: Set up real-time stream of journal entries, since firestore supports it

  Future<Result<JournalEntry, Exception>> createJournalEntry({
    required String title,
    required String content,
  }) async {
    _status = JournalStatus.loading;
    notifyListeners();

    final result = await _journalEntriesService.createJournalEntry(
      title: title,
      content: content,
    );
    switch (result) {
      case Success(value: final journalEntry):
        _journalEntries.add(journalEntry);
        _status = JournalStatus.loaded;
        notifyListeners();
        return success(journalEntry);
      case Failure(error: final Exception e):
        _status = JournalStatus.error;
        _errorMessage =
            e is UnauthorizedException
                ? 'You are Unauthorized'
                : e is ExceptionX
                ? e.message
                : e.toString();
        notifyListeners();
        return failure(e);
    }
  }

  Future<void> getAllJournalEntries() async {
    /* // TODO: activate if needed 
    _status = JournalStatus.loading;
    notifyListeners(); */

    final result = await _journalEntriesService.getAllJournalEntries();
    switch (result) {
      case Success(value: final entries):
        _status = JournalStatus.loaded;
        notifyListeners();
        break;
      case Failure(error: final Exception e):
        _status = JournalStatus.error;
        _errorMessage =
            e is UnauthorizedException
                ? 'You are Unauthorized'
                : e is ExceptionX
                ? e.message
                : e.toString();
        notifyListeners();
        break;
    }
  }

  Future<void> getJournalEntriesFromLast24Hours() async {
    /* // TODO: activate if needed 
    _status = JournalStatus.loading;
    notifyListeners(); */

    final result =
        await _journalEntriesService.getJournalEntriesFromLast24Hours();
    switch (result) {
      case Success(value: final entries):
        _status = JournalStatus.loaded;
        notifyListeners();
        break;
      case Failure(error: final Exception e):
        _status = JournalStatus.error;
        _errorMessage =
            e is UnauthorizedException
                ? 'You are Unauthorized'
                : e is ExceptionX
                ? e.message
                : e.toString();
        notifyListeners();
        break;
    }
  }

  Future<void> getAllUserJournalEntryTrackers() async {
    /* // TODO: activate if needed 
    _status = JournalStatus.loading;
    notifyListeners(); */

    final result =
        await _journalEntriesService.getAllUserJournalEntryTrackers();
    switch (result) {
      case Success(value: final trackers):
        _status = JournalStatus.loaded;
        notifyListeners();
        break;
      case Failure(error: final Exception e):
        _status = JournalStatus.error;
        _errorMessage =
            e is UnauthorizedException
                ? 'You are Unauthorized'
                : e is ExceptionX
                ? e.message
                : e.toString();
        notifyListeners();
        break;
    }
  }

  //
}
