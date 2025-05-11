import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kib_debug_print/kib_debug_print.dart' show kprint;
import 'package:kib_journal/core/errors/exceptions.dart';
import 'package:kib_journal/data/models/journal_entry.dart';
import 'package:kib_journal/data/models/user_journal_entry_tracker.dart';
import 'package:kib_utils/kib_utils.dart';
import 'package:uuid/uuid.dart';

class FirestoreJournalEntriesService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final uuid = const Uuid();

  late final CollectionReference<Map<String, dynamic>> _journalEntriesRef;
  late final CollectionReference<Map<String, dynamic>>
  _userJournalEntryTrackersRef;

  FirestoreJournalEntriesService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance {
    _journalEntriesRef = _firestore.collection('journal_entries');
    _userJournalEntryTrackersRef = _firestore.collection(
      'user_journal_entry_trackers',
    );
  }

  String? get _userId => _auth.currentUser?.uid;

  void _checkAuth() {
    if (_userId == null) {
      throw UnauthorizedException('user id is null');
    }
  }

  Exception _handleFirestoreError(dynamic err, String messagePrefix) {
    final type = err.runtimeType;
    kprint.err('_handleFirestoreError:$type: $messagePrefix: $err');
    if (err is FirebaseException) {
      return ExceptionX(
        message: '$messagePrefix: ${err.message ?? err.code}',
        errorType: type,
        error: err,
        stackTrace: StackTrace.current,
      );
    }

    return err is Exception
        ? err
        : ExceptionX(
          message: '$messagePrefix: ${err.toString()}',
          errorType: type,
          error: err,
          stackTrace: StackTrace.current,
        );
  }

  Future<Result<JournalEntry, Exception>> createJournalEntry({
    required String title,
    required String content,
  }) async {
    return await tryResultAsync<JournalEntry, Exception>(
      () async {
        _checkAuth();

        if (title.isEmpty || content.isEmpty) {
          throw StateError('Title and content cannot be empty');
        }

        final now = DateTime.now();
        final journalEntry = JournalEntry(
          id: uuid.v4(),
          userId: _userId!,
          title: title,
          content: content,
          createdAt: now,
          updatedAt: now,
        );

        final DocumentReference<Map<String, dynamic>> docRef =
            await _journalEntriesRef.add(journalEntry.toMapForFirestore());

        final docSnapshot = await docRef.get();

        final updateTrackerResult =
            await updateUserJournalEntryTrackerAfterPosting();
        if (updateTrackerResult.isFailure) {
          kprint.err(
            'createJournalEntry: Error updating user journal entry tracker: ${updateTrackerResult.errorOrNull}',
          );
        }

        return JournalEntry.fromFirestore(docSnapshot);
      },
      (dynamic err) =>
          _handleFirestoreError(err, 'Error creating journal entry'),
    );
  }

  Future<Result<void, Exception>>
  updateUserJournalEntryTrackerAfterPosting() async {
    return await tryResultAsync<void, Exception>(
      () async {
        _checkAuth();

        final docRef = _userJournalEntryTrackersRef.doc(_userId!);
        final docSnapshot = await docRef.get();
        final nowTimestamp = Timestamp.fromDate(DateTime.now());
        if (docSnapshot.exists) {
          await docRef.update({
            'lastPostedAt': nowTimestamp,
            'updatedAt': nowTimestamp,
          });
        } else {
          await docRef.set({
            'userId': _userId,
            'userEmail': _auth.currentUser?.email,
            'lastPostedAt': nowTimestamp,
            'createdAt': nowTimestamp,
            'updatedAt': nowTimestamp,
          });
        }
      },
      (dynamic err) => _handleFirestoreError(
        err,
        'Error updating user journal entry tracker',
      ),
    );
  }

  Future<Result<List<JournalEntry>, Exception>> getCurrentUserJournalEntries({
    bool descending = true,
  }) async {
    return await tryResultAsync<List<JournalEntry>, Exception>(
      () async {
        _checkAuth();

        final querySnapshot =
            await _journalEntriesRef
                .where('userId', isEqualTo: _userId)
                .orderBy('createdAt', descending: descending)
                .get();

        final entries =
            querySnapshot.docs.map(JournalEntry.fromFirestore).toList();
        kprint.lg(
          'getCurrentUserJournalEntries: ${entries.length}:\n ${entries.map((e) => '${e.userId}-[${e.title}]').join(', ')}',
        );
        return entries;
      },
      (dynamic err) =>
          _handleFirestoreError(err, 'Error getting journal entries'),
    );
  }

  Future<Result<List<JournalEntry>, Exception>> getAllJournalEntries({
    bool descending = true,
  }) async {
    return await tryResultAsync<List<JournalEntry>, Exception>(
      () async {
        _checkAuth();
        final querySnapshot =
            await _journalEntriesRef
                .orderBy('createdAt', descending: descending)
                .get();
        final List<JournalEntry> entries =
            querySnapshot.docs.map(JournalEntry.fromFirestore).toList();
        kprint.lg(
          'getAllJournalEntries: ${entries.length}:\n ${entries.map((e) => '${e.userId}-[${e.title}]').join(', ')}',
        );
        return entries;
      },
      (dynamic err) =>
          _handleFirestoreError(err, 'Error getting journal entries'),
    );
  }

  Future<Result<List<JournalEntry>, Exception>>
  getJournalEntriesFromLast24Hours({bool descending = true}) async {
    return await tryResultAsync<List<JournalEntry>, Exception>(
      () async {
        _checkAuth();
        final now = DateTime.now();
        final last24Hours = now.subtract(const Duration(hours: 24));
        final querySnapshot =
            await _journalEntriesRef
                .where(
                  'createdAt',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(last24Hours),
                )
                .orderBy('createdAt', descending: descending)
                .get();
        final List<JournalEntry> entries =
            querySnapshot.docs.map(JournalEntry.fromFirestore).toList();
        kprint.lg(
          'getJournalEntriesFromLast24Hours: ${entries.length}:\n ${entries.map((e) => '${e.userId}-[${e.title}]').join(', ')}',
        );
        return entries;
      },
      (dynamic err) =>
          _handleFirestoreError(err, 'Error getting journal entries'),
    );
  }

  Future<Result<JournalEntry, Exception>> getJournalEntryById(
    String journalEntryId,
  ) async {
    return await tryResultAsync<JournalEntry, Exception>(
      () async {
        if (journalEntryId.isEmpty) {
          throw StateError('ID cannot be empty');
        }
        _checkAuth();

        final docSnapshot = await _journalEntriesRef.doc(journalEntryId).get();

        if (!docSnapshot.exists) {
          throw NotFoundException('Journal, $journalEntryId, not found');
        }

        return JournalEntry.fromFirestore(docSnapshot);
      },
      (dynamic err) =>
          _handleFirestoreError(err, 'Error getting journal entry'),
    );
  }

  Future<Result<bool, Exception>> deleteJournalEntry(
    String journalEntryId,
  ) async {
    return await tryResultAsync<bool, Exception>(
      () async {
        if (journalEntryId.isEmpty) {
          throw StateError('ID cannot be empty');
        }
        _checkAuth();

        final getResult = await getJournalEntryById(journalEntryId);

        switch (getResult) {
          case Success(value: final _):
            await _journalEntriesRef.doc(journalEntryId).delete();
            return true;
          case Failure(error: final error):
            throw error;
        }
      },
      (dynamic err) =>
          _handleFirestoreError(err, 'Error deleting journal entry'),
    );
  }

  Future<Result<List<UserJournalEntryTracker>, Exception>>
  getAllUserJournalEntryTrackers({bool descending = true}) async {
    return await tryResultAsync<List<UserJournalEntryTracker>, Exception>(
      () async {
        final querySnapshot =
            await _userJournalEntryTrackersRef
                .orderBy('lastPostedAt', descending: descending)
                .get();
        final List<UserJournalEntryTracker> userJournalEntryTrackers =
            querySnapshot.docs
                .map(UserJournalEntryTracker.fromFirestore)
                .toList();
        kprint.lg(
          'getAllUserJournalEntryTrackers: ${userJournalEntryTrackers.length}:\n ${userJournalEntryTrackers.map((e) => '${e.userId}-[${e.lastPostedAt}]').join(', ')}',
        );
        return userJournalEntryTrackers;
      },
      (dynamic err) => _handleFirestoreError(
        err,
        'Error getting user journal entry trackers',
      ),
    );
  }

  Future<Result<List<UserJournalEntryTracker>, Exception>>
  getAllUsersWhoPostedInLast24Hours({bool descending = true}) async {
    return await tryResultAsync<List<UserJournalEntryTracker>, Exception>(
      () async {
        final now = DateTime.now();
        final last24Hours = now.subtract(const Duration(hours: 24));
        final querySnapshot =
            await _userJournalEntryTrackersRef
                .where(
                  'lastPostedAt',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(last24Hours),
                )
                .orderBy('lastPostedAt', descending: descending)
                .get();
        final List<UserJournalEntryTracker> userJournalEntryTrackers =
            querySnapshot.docs
                .map(UserJournalEntryTracker.fromFirestore)
                .toList();
        kprint.lg(
          'getAllUsersWhoPostedInLast24Hours: ${userJournalEntryTrackers.length}:\n ${userJournalEntryTrackers.map((e) => '${e.userId}-[${e.lastPostedAt}]').join(', ')}',
        );
        return userJournalEntryTrackers;
      },
      (dynamic err) => _handleFirestoreError(
        err,
        'Error getting users who posted in the last 24 hours',
      ),
    );
  }

  //
}
