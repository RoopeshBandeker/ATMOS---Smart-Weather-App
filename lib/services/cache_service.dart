import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather.dart';

class CacheService {
  static const String _cacheKeyPrefix = 'weather_cache:';
  static const String _lastFetchTimeKey = 'last_fetch_time';
  static const String _lastLocationKey = 'last_location';
  static const int _cacheDurationMinutes = 15;
  static const int _refreshCooldownSeconds = 30;

  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get cached weather data
  String _keyForLocation(String location) {
    return '$_cacheKeyPrefix${location.toLowerCase().trim().replaceAll(" ", "_")}';
  }

  Future<WeatherData?> getCachedWeather(String location) async {
    try {
      final key = _keyForLocation(location);
      final cached = _prefs.getString(key);
      if (cached == null) return null;

      final json = jsonDecode(cached) as Map<String, dynamic>;
      final data = WeatherData.fromJson(json);

      if (data.isCacheValid(_cacheDurationMinutes)) {
        return data;
      }
    } catch (e) {
      debugPrint('Error reading cache: $e');
    }
    return null;
  }

  /// Save weather data to cache
  /// Cache weather for a specific location (uses `data.current.locationName` if `location` is null)
  Future<void> cacheWeather(WeatherData data, {String? location}) async {
    try {
      final locKey = (location ?? data.current.locationName);
      final key = _keyForLocation(locKey);
      final json = jsonEncode(data.toJson());
      await _prefs.setString(key, json);
      await _prefs.setInt(_lastFetchTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error caching weather: $e');
    }
  }

  /// Get last fetch time
  DateTime? getLastFetchTime() {
    final timestamp = _prefs.getInt(_lastFetchTimeKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Check if refresh is on cooldown
  bool isRefreshOnCooldown() {
    final lastFetch = getLastFetchTime();
    if (lastFetch == null) return false;
    return DateTime.now().difference(lastFetch).inSeconds < _refreshCooldownSeconds;
  }

  /// Save last searched location
  Future<void> saveLastLocation(String location) async {
    await _prefs.setString(_lastLocationKey, location);
  }

  /// Get last searched location
  String? getLastLocation() {
    return _prefs.getString(_lastLocationKey);
  }

  /// Clear all cache
  Future<void> clearCache() async {
    // Remove any keys created for cached weather entries
    final keys = _prefs.getKeys();
    for (final k in keys) {
      if (k.startsWith(_cacheKeyPrefix)) {
        await _prefs.remove(k);
      }
    }
    await _prefs.remove(_lastFetchTimeKey);
  }
}
