import 'package:kib_journal/core/preferences/base.dart' show BasePrefsAsync;

class AppPrefs {
  AppPrefs._();

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  /// Manager for general application preferences
  static late final AppPrefsAsyncManager app;

  static void init() {
    if (_initialized) {
      return;
    }

    try {
      app = AppPrefsAsyncManager()..init("AppAsyncPrefsManager");
      _initialized = true;
    } catch (e) {
      _initialized = false;
      throw StateError('Failed to initialize AppPrefs: $e');
    }
  }

  static Future<void> clearAll() async {
    if (!_initialized) return;
    await app.clear();
    _initialized = false;
  }
}

class AppPrefsAsyncManager extends BasePrefsAsync {
  static const _prefix = 'app_';
  static const _keyFirstLaunch = 'first_launch';
  static const _keyCurrentUserUid = 'current_user_uid';

  AppPrefsAsyncManager() : super(prefix: _prefix, allowList: {_keyFirstLaunch, _keyCurrentUserUid});

  // first_launch
  Future<bool?> isFirstLaunch() async => getValue<bool>(_keyFirstLaunch, true);
  Future<bool> setFirstLaunch(bool value) => setValue(_keyFirstLaunch, value);

  // current_user_uid
  Future<String?> getCurrentUserUid() async => getValue<String>(_keyCurrentUserUid, '');
  Future<bool> setCurrentUserUid(String value) => setValue(_keyCurrentUserUid, value);
}
