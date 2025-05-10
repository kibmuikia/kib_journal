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

  AppPrefsAsyncManager() : super(prefix: _prefix, allowList: {_keyFirstLaunch});

  Future<bool?> isFirstLaunch() async => getValue<bool>(_keyFirstLaunch, true);
  Future<bool> setFirstLaunch(bool value) => setValue(_keyFirstLaunch, value);
}
