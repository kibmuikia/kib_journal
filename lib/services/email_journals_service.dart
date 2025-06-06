import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:kib_debug_print/kib_debug_print.dart';
import 'package:kib_journal/core/errors/exceptions.dart';
import 'package:kib_journal/data/models/journal_entry.dart';
import 'package:kib_journal/data/models/user_journal_entry_tracker.dart';
import 'package:kib_journal/di/confidential.dart';
import 'package:kib_journal/di/setup.dart';
import 'package:kib_journal/firebase_options.dart';
import 'package:kib_journal/firebase_services/firebase_auth_service.dart';
import 'package:kib_journal/firebase_services/firestore_journal_entries_service.dart';
import 'package:kib_utils/kib_utils.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:workmanager/workmanager.dart';

class EmailJournalsService {
  static const String distributionTaskName = 'journal_distribution_task';
  static const String testTaskName = 'journal_test_task';

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

  Future<void> initialize({bool scheduleTask = true}) async {
    if (scheduleTask) {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );

      await scheduleTestTask();
      await scheduleDistributionTask();
    }
  }

  Future<void> scheduleTestTask() async {
    Workmanager().registerPeriodicTask(
      testTaskName,
      testTaskName,
      tag: '$testTaskName-${DateTime.now().millisecondsSinceEpoch}',
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(minutes: 1),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.exponential,
    );
  }

  Future<Result<Object?, Exception>> testTask() async {
    kprint.lg('testTask:start');
    await Future.delayed(const Duration(seconds: 2));
    kprint.lg('testTask:end');
    return const Success('Done');
  }

  Future<void> scheduleDistributionTask() async {
    final now = DateTime.now();

    final scheduledTime = DateTime(now.year, now.month, now.day, 12, 0, 0);
    // final scheduledTime = now.add(const Duration(minutes: 5));

    final initialDelay =
        scheduledTime.isAfter(now)
            ? scheduledTime.difference(now)
            : scheduledTime.add(const Duration(days: 1)).difference(now);
    kprint.lg(
      'scheduleDistributionTask: initialDelay[ ${initialDelay.inMinutes} minutes ], scheduledTime[ ${scheduledTime.toLocal().toString().split('.')[0]} ], now[ ${now.toLocal().toString().split('.')[0]} ]',
    );

    Workmanager()
        .registerPeriodicTask(
          distributionTaskName,
          distributionTaskName,
          tag: '$distributionTaskName-${now.millisecondsSinceEpoch}',
          frequency: const Duration(days: 1),
          // frequency: const Duration(minutes: 15),
          initialDelay: initialDelay,
          // initialDelay: const Duration(minutes: 1),
          constraints: Constraints(networkType: NetworkType.connected),
          existingWorkPolicy: ExistingWorkPolicy.replace,
          backoffPolicy: BackoffPolicy.exponential,
        )
        .then(
          (void k) => kprint.lg(
            'scheduleDistributionTask:registerPeriodicTask:then: fired',
          ),
        )
        .catchError(
          (err) => kprint.err(
            'scheduleDistributionTask:registerPeriodicTask:catchError: $err',
          ),
        );
  }

  Future<Result<void, Exception>> distributeJournalEntries() async {
    return await tryResultAsync(
      () async {
        kprint.lg('distributeJournalEntries:start');
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
                ..from = Address(
                  _appEmailAddress,
                  'Kib Journal App${_firestoreJournalService.currentUser?.email == null ? '' : ' - ${_firestoreJournalService.currentUser?.email}'}',
                )
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
            kprint.lg(
              'Email sent to ${user.userEmail} by ${_firestoreJournalService.currentUser?.email}',
            );
          } catch (e) {
            kprint.err('Error sending email to ${user.userEmail}: $e');
          }
        }
        kprint.lg('distributeJournalEntries:end');
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
void callbackDispatcher() async {
  Workmanager().executeTask((taskName, inputData) async {
    kprint.lg(
      'callbackDispatcher:taskName[ $taskName ]: inputData: ${inputData == null ? 'null' : 'Not-null'}',
    );
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final firebaseAuth = FirebaseAuth.instance;
      final firebaseAuthService = FirebaseAuthService(
        firebaseAuth: firebaseAuth,
      );
      final firestore = FirebaseFirestore.instance;
      final firestoreJournalService = FirestoreJournalEntriesService(
        firestore: firestore,
        auth: firebaseAuth,
      );
      final emailJournalsService = EmailJournalsService(
        journalService: firestoreJournalService,
        appEmailAddress: appEmailAddress,
        appEmailPassword: appEmailPassword,
      );
      await emailJournalsService.initialize(scheduleTask: false);

      if (taskName == EmailJournalsService.testTaskName) {
        kprint.lg('callbackDispatcher:taskName[ $taskName ]: start testTask');
        await emailJournalsService.testTask();
      }
      if (taskName == EmailJournalsService.distributionTaskName) {
        kprint.lg(
          'callbackDispatcher:taskName[ $taskName ]: start distributeJournalEntries',
        );
        await emailJournalsService.distributeJournalEntries();
      }
      return true;
    } catch (e) {
      kprint.err(
        'callbackDispatcher:taskName[ $taskName ]: Error-${e.runtimeType};\n$e',
      );
      return false;
    }
  });
}
