import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:kib_journal/core/errors/exceptions.dart' show ExceptionX;
import 'package:kib_journal/firebase_options.dart' show DefaultFirebaseOptions;
import 'package:kib_utils/kib_utils.dart';

class FirebaseHelper {
  static final FirebaseHelper _instance = FirebaseHelper._internal();

  factory FirebaseHelper() => _instance;

  FirebaseHelper._internal();

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized || Firebase.apps.isNotEmpty;

  static Future<Result<bool, Exception>> initialize() async {
    return await tryResultAsync<bool, Exception>(
      () async {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        _isInitialized = true;
        return true;
      },
      (err) =>
          err is Exception
              ? err
              : ExceptionX(
                message:
                    "Error, ${err.runtimeType}, encountered while initializing Firebase",
                errorType: err.runtimeType,
                error: err,
                stackTrace: StackTrace.current,
              ),
    );
  }
}
