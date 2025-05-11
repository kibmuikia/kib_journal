import 'dart:math';

import 'package:kib_debug_print/kib_debug_print.dart';
import 'package:kib_journal/core/errors/exceptions.dart';
import 'package:kib_journal/data/models/journal_entry.dart';
import 'package:kib_journal/data/models/user_journal_entry_tracker.dart';
import 'package:kib_journal/di/setup.dart';
import 'package:kib_journal/firebase_services/firestore_journal_entries_service.dart';
import 'package:kib_utils/kib_utils.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:workmanager/workmanager.dart';

class EmailJournalsService {
  static const String distributionTaskName = 'journal_distribution_task';

  final FirestoreJournalEntriesService _firestoreJournalService;
  final String _appEmailAddress;
  final String _appEmailPassword;

  EmailJournalsService({
    FirestoreJournalEntriesService? journalService,
    required String appEmailAddress,
    required String appEmailPassword,
  }) : _firestoreJournalService =
           journalService ?? getIt<FirestoreJournalEntriesService>(),
       _appEmailAddress = appEmailAddress,
       _appEmailPassword = appEmailPassword;

  Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher);
    await scheduleDistributionTask();
  }

  Future<void> scheduleDistributionTask() async {
    final now = DateTime.now();
    final scheduledTime = DateTime(now.year, now.month, now.day, 12, 0, 0);
    final initialDelay =
        scheduledTime.isAfter(now)
            ? scheduledTime.difference(now)
            : scheduledTime.add(const Duration(days: 1)).difference(now);
    await Workmanager().registerPeriodicTask(
      distributionTaskName,
      distributionTaskName,
      frequency: const Duration(days: 1),
      initialDelay: initialDelay,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  Future<Result<void, Exception>> distributeJournalEntries() async {
    return await tryResultAsync(
      () async {
        final usersResult =
            await _firestoreJournalService.getAllUsersWhoPostedInLast24Hours();
        if (usersResult.isFailure) {
          throw usersResult.errorOrNull!;
        }

        final List<UserJournalEntryTracker> users =
            usersResult.isSuccess
                ? usersResult.valueOrNull ?? <UserJournalEntryTracker>[]
                : <UserJournalEntryTracker>[];
        if (users.length < 2) {
          throw StateError('Not enough users to distribute journal entries');
        }

        final entriesResult =
            await _firestoreJournalService.getJournalEntriesFromLast24Hours();
        if (entriesResult.isFailure) {
          throw entriesResult.errorOrNull!;
        }

        final List<JournalEntry> entries =
            entriesResult.isSuccess
                ? entriesResult.valueOrNull ?? <JournalEntry>[]
                : <JournalEntry>[];
        if (entries.isEmpty) {
          throw StateError('No journal entries to distribute');
        }

        final entriesPerUser = <String, List<JournalEntry>>{};
        for (final entry in entries) {
          if (!entriesPerUser.containsKey(entry.userId)) {
            entriesPerUser[entry.userId] = [];
          }
          entriesPerUser[entry.userId]!.add(entry);
        }

        final random = Random();
        final smtpServer = gmail(_appEmailAddress, _appEmailPassword);

        for (final user in users) {
          if (user.userEmail.isEmpty) continue;

          final otherUsersEntries =
              entries.where((entry) => entry.userId != user.userId).toList();

          if (otherUsersEntries.isEmpty) continue;

          final randomEntry =
              otherUsersEntries[random.nextInt(otherUsersEntries.length)];

          final message =
              Message()
                ..from = Address(_appEmailAddress, 'Kib Journal App')
                ..recipients.add(user.userEmail)
                ..subject = 'Your Daily Journal Surprise'
                ..html = '''
            <h2>Here's a journal entry from another user</h2>
            <h3>${randomEntry.title}</h3>
            <p>${randomEntry.content}</p>
            <p><i>Written on ${randomEntry.createdAt.toLocal().toString().split('.')[0]}</i></p>
          ''';

          try {
            await send(message, smtpServer);
          } catch (e) {
            kprint.err('Error sending email to ${user.userEmail}: $e');
          }
        }

        //
      },
      (err) {
        return err is Exception
            ? err
            : ExceptionX(
              error: err,
              message:
                  'Error, ${err.runtimeType}, encountered while distributing journal entries',
              errorType: err.runtimeType,
              stackTrace: StackTrace.current,
            );
      },
    );
  }

  //
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == EmailJournalsService.distributionTaskName) {
      // Get the service from the service locator
      final service = getIt<EmailJournalsService>();
      await service.distributeJournalEntries();
    }
    return true;
  });
}
