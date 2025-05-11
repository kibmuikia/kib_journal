import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kib_journal/core/errors/exceptions.dart';
import 'package:kib_journal/data/models/journal_entry.dart';
import 'package:kib_utils/kib_utils.dart';

class FirestoreJournalEntriesService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  late final CollectionReference<Map<String, dynamic>> _journalEntries;

  FirestoreJournalEntriesService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance {
    _journalEntries = _firestore.collection('journal_entries');
  }

  String? get _userId => _auth.currentUser?.uid;

  void _checkAuth() {
    if (_userId == null) {
      throw UnauthorizedException('user id is null');
    }
  }

  Exception _handleFirestoreError(dynamic err, String messagePrefix) {
    if (err is FirebaseException) {
      return ExceptionX(
        message: '$messagePrefix: ${err.message ?? err.code}',
        errorType: err.runtimeType,
        error: err,
        stackTrace: StackTrace.current,
      );
    }

    return err is Exception
        ? err
        : ExceptionX(
          message: '$messagePrefix: ${err.toString()}',
          errorType: err.runtimeType,
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
          userId: _userId!,
          title: title,
          content: content,
          createdAt: now,
          updatedAt: now,
        );

        final DocumentReference<Map<String, dynamic>> docRef =
            await _journalEntries.add(journalEntry.toJson());

        // Fetch the created document to get the ID
        final docSnapshot = await docRef.get();
        return JournalEntry.fromFirestore(docSnapshot);
      },
      (dynamic err) =>
          _handleFirestoreError(err, 'Error creating journal entry'),
    );
  }

  Future<Result<List<JournalEntry>, Exception>> getJournalEntries({bool descending = true}) async {
    return await tryResultAsync<List<JournalEntry>, Exception>(
      () async {
        _checkAuth();

        final querySnapshot = await _journalEntries
            .where('userId', isEqualTo: _userId)
            .orderBy('createdAt', descending: descending)
            .get();

        return querySnapshot.docs.map(JournalEntry.fromFirestore).toList();
      },
      (dynamic err) =>
          _handleFirestoreError(err, 'Error getting journal entries'),
    );
  }

  //
}
