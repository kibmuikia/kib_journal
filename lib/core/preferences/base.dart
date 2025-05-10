import 'package:kib_debug_print/kib_debug_print.dart' show kprint;
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferencesAsync;

/// Abstract base class to enable management of preference managers
abstract class BasePrefs {
  /// The prefix for all keys in this preference manager
  final String prefix;

  /// Whether to handle keys without prefixes
  final bool allowUnprefixed;

  final Set<String>? allowList;

  const BasePrefs({
    required this.prefix,
    this.allowUnprefixed = false,
    this.allowList,
  });

  String getPrefixedKey(String key) => allowUnprefixed ? key : '$prefix$key';

  String removePrefixFromKey(String key) {
    if (allowUnprefixed || !key.startsWith(prefix)) return key;
    return key.substring(prefix.length);
  }

  bool isKeyAllowed(String key) {
    if (allowList == null) return true;
    return allowList!.contains(removePrefixFromKey(key));
  }
}

/// Base class for [async] preferences management
abstract class BasePrefsAsync extends BasePrefs {
  late final SharedPreferencesAsync _prefs;

  bool _initialized = false;

  BasePrefsAsync({
    required super.prefix,
    super.allowUnprefixed,
    super.allowList,
  });

  bool init(String managerName) {
    try {
      if (_initialized) {
        kprint.warn('BasePrefsAsync:$managerName: Already initialized');
        return true;
      }
      _prefs = SharedPreferencesAsync();
      _initialized = true;
      kprint.lg('BasePrefsAsync:$managerName:initialized', symbol: '💾');
      return _initialized;
    } on Exception catch (e) {
      kprint.err('BasePrefsAsync:$managerName:${e.runtimeType}:\n$e');
      _initialized = false;
      return _initialized;
    }
  }

  /// Throws [StateError] when not initialized and [throwOnError] is true
  bool checkInitialized({bool throwOnError = false}) {
    if (!_initialized && throwOnError) {
      throw StateError(
        'BasePrefsAsync not initialized. Call init() before using preferences.',
      );
    }
    return _initialized;
  }

  Future<T?> getValue<T>(String key, T defaultValue) async {
    try {
      if (!checkInitialized()) throw StateError('Preferences not initialized');
      if (key.isEmpty) throw StateError('Key cannot be empty');
      final fullKey = getPrefixedKey(key);
      if (!isKeyAllowed(fullKey)) throw StateError('Key, $key, not allowed');
      switch (T) {
        case const (int):
          return await _prefs.getInt(fullKey) as T? ?? defaultValue;
        case const (double):
          return await _prefs.getDouble(fullKey) as T? ?? defaultValue;
        case const (bool):
          return await _prefs.getBool(fullKey) as T? ?? defaultValue;
        case const (String):
          return await _prefs.getString(fullKey) as T? ?? defaultValue;
        case const (List<String>):
          return await _prefs.getStringList(fullKey) as T? ?? defaultValue;
        default:
          throw UnsupportedError('Type $T not supported by SharedPreferences');
      }
    } on Exception catch (e) {
      kprint.err('$prefix:getValue:[$key] $e');
      return null;
    }
  }

  Future<bool> setValue<T>(String key, T value) async {
    try {
      if (!checkInitialized()) return false;
      if (key.isEmpty) return false;
      final fullKey = getPrefixedKey(key);
      if (!isKeyAllowed(fullKey)) return false;

      switch (T) {
        case const (int):
          await _prefs.setInt(fullKey, value as int);
          return true;
        case const (double):
          await _prefs.setDouble(fullKey, value as double);
          return true;
        case const (bool):
          await _prefs.setBool(fullKey, value as bool);
          return true;
        case const (String):
          await _prefs.setString(fullKey, value as String);
          return true;
        case const (List<String>):
          await _prefs.setStringList(fullKey, value as List<String>);
          return true;
        default:
          throw UnsupportedError('Type $T not supported by SharedPreferences');
      }
    } on Exception catch (e) {
      kprint.err('BasePrefsAsync:setValue:[$key - $value] $e');
      return false;
    }
  }

  Future<bool> removeValue(String key) async {
    try {
      if (!checkInitialized()) return false;
      if (key.isEmpty) return false;
      final fullKey = getPrefixedKey(key);
      if (!isKeyAllowed(fullKey)) return false;
      await _prefs.remove(fullKey);
      return true;
    } on Exception catch (e) {
      kprint.err('BasePrefsAsync:removeValue:[$key] $e');
      return false;
    }
  }

  Future<bool> clear() async {
    try {
      if (!checkInitialized()) return false;
      await _prefs.clear();
      return true;
    } on Exception catch (e) {
      kprint.err('BasePrefsAsync:clear: $e');
      return false;
    }
  }
}
