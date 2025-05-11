import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseFirestore;
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:get_it/get_it.dart' show GetIt;
import 'package:kib_journal/config/firebase_config/config.dart'
    show FirebaseHelper;
import 'package:kib_journal/config/routes/router_config.dart'
    show AppNavigation;
import 'package:kib_journal/core/errors/exceptions.dart' show ExceptionX;
import 'package:kib_journal/core/preferences/shared_preferences_manager.dart'
    show AppPrefsAsyncManager, AppPrefs;
import 'package:kib_journal/firebase_services/firebase_auth_service.dart'
    show FirebaseAuthService;
import 'package:kib_journal/firebase_services/firestore_journal_entries_service.dart'
    show FirestoreJournalEntriesService;
import 'package:kib_utils/kib_utils.dart';

// Global GetIt instance
final getIt = GetIt.instance;

/// Setup all service dependencies
Future<Result<bool, Exception>> setupServiceLocator() async {
  return await tryResultAsync<bool, Exception>(
    () async {
      _setupAppPrefs();
      await _setupFirebaseServices();
      _setupAppNavigation();

      return true;
    },
    (err) =>
        err is Exception
            ? err
            : ExceptionX(
              message:
                  "Error, ${err.runtimeType}, encountered while setting up services",
              errorType: err.runtimeType,
              error: err,
              stackTrace: StackTrace.current,
            ),
  );
}

/// Setup Kib Journal Shared-Preferences
void _setupAppPrefs() {
  AppPrefs.init();

  if (!getIt.isRegistered<AppPrefsAsyncManager>()) {
    getIt.registerSingleton<AppPrefsAsyncManager>(AppPrefs.app);
  }
}

// Setup app navigation
void _setupAppNavigation() {
  if (!AppPrefs.isInitialized) {
    AppPrefs.init();
  }

  if (!getIt.isRegistered<AppNavigation>()) {
    if (!AppNavigation.isInitialized) {
      AppNavigation.init(prefsManager: AppPrefs.app);
    }
    getIt.registerSingleton<AppNavigation>(AppNavigation.instance);
  }
}

Future<Result<bool, Exception>>
_setupFirebaseServices() async => tryResultAsync(
  () async {
    final firebaseInitResult = await FirebaseHelper.initialize();
    if (firebaseInitResult.isFailure) {
      throw firebaseInitResult.errorOrNull!;
    }
    if (!getIt.isRegistered<FirebaseHelper>()) {
      getIt.registerSingleton<FirebaseHelper>(FirebaseHelper());
    }

    if (!getIt.isRegistered<FirebaseAuth>()) {
      getIt.registerSingleton<FirebaseAuth>(FirebaseAuth.instance);
    }

    if (!getIt.isRegistered<FirebaseAuthService>()) {
      getIt.registerSingleton<FirebaseAuthService>(
        FirebaseAuthService(firebaseAuth: getIt<FirebaseAuth>()),
      );
    }

    if (!getIt.isRegistered<FirebaseFirestore>()) {
      getIt.registerSingleton<FirebaseFirestore>(FirebaseFirestore.instance);
    }

    if (!getIt.isRegistered<FirestoreJournalEntriesService>()) {
      getIt.registerSingleton<FirestoreJournalEntriesService>(
        FirestoreJournalEntriesService(
          firestore: getIt<FirebaseFirestore>(),
          auth: getIt<FirebaseAuth>(),
        ),
      );
    }

    return true;
  },
  (err) =>
      err is Exception
          ? err
          : ExceptionX(
            message:
                'Error, ${err.runtimeType}, encountered while setting up Firebase services',
            errorType: err.runtimeType,
            error: err,
            stackTrace: StackTrace.current,
          ),
);
