import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Unified storage helper that combines FlutterSecureStorage with
/// SharedPreferences fallback for reliable persistence across desktop/mobile OSs.
class AppStorage {
  static const _storage = FlutterSecureStorage(
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.unlocked,
      usesDataProtectionKeychain: false,
    ),
  );

  static Future<void> write(String key, String? value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value != null) {
        await prefs.setString(key, value);
      } else {
        await prefs.remove(key);
      }
    } catch (e) {
      debugPrint('AppStorage prefs write warning: $e');
    }

    try {
      await _storage.delete(key: key);
      if (value != null) {
        await _storage.write(key: key, value: value);
      }
    } catch (e) {
      debugPrint('AppStorage secure_storage write warning: $e');
    }
  }

  static Future<String?> read(String key) async {
    String? val;
    try {
      val = await _storage.read(key: key);
    } catch (e) {
      debugPrint('AppStorage secure_storage read warning: $e');
    }

    if (val != null && val.isNotEmpty) {
      return val;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      debugPrint('AppStorage prefs read warning: $e');
    }
    return null;
  }

  static Future<void> delete(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {}

    try {
      await _storage.delete(key: key);
    } catch (e) {
      debugPrint('AppStorage secure_storage delete warning: $e');
    }
  }
}
