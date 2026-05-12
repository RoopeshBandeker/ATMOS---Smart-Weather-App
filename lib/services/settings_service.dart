import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings.dart';

class SettingsService {
  static const String _settingsKey = 'app_settings';

  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get current settings
  AppSettings getSettings() {
    try {
      final stored = _prefs.getString(_settingsKey);
      if (stored == null) {
        return AppSettings();
      }
      final json = jsonDecode(stored) as Map<String, dynamic>;
      return AppSettings.fromJson(json);
    } catch (e) {
      return AppSettings();
    }
  }

  /// Save settings
  Future<void> saveSettings(AppSettings settings) async {
    try {
      final json = jsonEncode(settings.toJson());
      await _prefs.setString(_settingsKey, json);
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }
}
