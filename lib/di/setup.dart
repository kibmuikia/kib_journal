import 'package:get_it/get_it.dart' show GetIt;
import 'package:kib_journal/core/errors/exceptions.dart' show ExceptionX;
import 'package:kib_journal/core/preferences/shared_preferences_manager.dart'
    show AppPrefsAsyncManager, AppPrefs;
import 'package:kib_utils/kib_utils.dart';

// Global GetIt instance
final getIt = GetIt.instance;

/// Setup all service dependencies
Future<Result<bool, Exception>> setupServiceLocator() async {
  return await tryResultAsync<bool, Exception>(
    () async {
      _setupAppPrefs();

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
