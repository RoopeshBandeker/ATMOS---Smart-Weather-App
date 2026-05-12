import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_key.dart';
import '../models/air_quality.dart';

/// Service responsible solely for fetching Air Quality Index (AQI)
/// data from OpenWeather's Air Pollution API.
class AirQualityService {
  static const String _baseUrl =
      'https://api.openweathermap.org/data/2.5/air_pollution';

  /// Fetch AQI data for the given coordinates.
  ///
  /// Throws [Exception] with a user‑friendly message on failure.
  Future<AirQualityIndex> getAirQuality({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl?lat=$latitude&lon=$longitude&appid=$openweatherApiKey',
      );

      late http.Response response;
      try {
        response = await http.get(uri).timeout(
          const Duration(seconds: 10),
        );
      } on TimeoutException {
        throw Exception('AQI request timed out. Please try again.');
      } on SocketException {
        throw Exception('Unable to load AQI. Check your internet connection.');
      }

      if (response.statusCode == 429) {
        throw Exception('Too many AQI requests. Please wait a moment.');
      } else if (response.statusCode != 200) {
        throw Exception(
          'Failed to load air quality data (Error ${response.statusCode}).',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return AirQualityIndex.fromJson(
        json,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e, stack) {
      debugPrint('AirQualityService error: $e\n$stack');
      rethrow;
    }
  }
}

