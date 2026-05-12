import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/api_key.dart';

/// Weather grid point data for map visualization
class WeatherGridPoint {
  final double latitude;
  final double longitude;
  final double temperature;
  final double windSpeed;
  final int windDirection;
  final int pressure;
  final int humidity;
  final String condition;
  final String icon;

  WeatherGridPoint({
    required this.latitude,
    required this.longitude,
    required this.temperature,
    required this.windSpeed,
    required this.windDirection,
    required this.pressure,
    required this.humidity,
    required this.condition,
    required this.icon,
  });
}

/// Service for fetching weather data for map overlays
class WeatherMapService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  /// Fetch weather data for a specific location with grid data
  Future<Map<String, dynamic>> getWeatherMapData({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/weather?lat=$latitude&lon=$longitude&appid=$openweatherApiKey&units=metric',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 429) {
        throw Exception('API rate limit exceeded');
      } else {
        throw Exception('Failed to fetch map weather data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching weather map data: $e');
      rethrow;
    }
  }

  /// Generate a grid of weather points for visualization
  /// width and height in degrees for the grid area
  Future<List<WeatherGridPoint>> getWeatherGrid({
    required double centerLat,
    required double centerLon,
    required double latRange,
    required double lonRange,
    int pointsPerSide = 5,
  }) async {
    List<WeatherGridPoint> points = [];

    final latStep = latRange / pointsPerSide;
    final lonStep = lonRange / pointsPerSide;

    for (int i = 0; i < pointsPerSide; i++) {
      for (int j = 0; j < pointsPerSide; j++) {
        final lat = centerLat - (latRange / 2) + (i * latStep);
        final lon = centerLon - (lonRange / 2) + (j * lonStep);

        try {
          final data = await getWeatherMapData(
            latitude: lat,
            longitude: lon,
          );

          final point = WeatherGridPoint(
            latitude: lat,
            longitude: lon,
            temperature: (data['main']['temp'] as num).toDouble(),
            windSpeed: (data['wind']['speed'] as num).toDouble(),
            windDirection: (data['wind']['deg'] as num? ?? 0).toInt(),
            pressure: (data['main']['pressure'] as num).toInt(),
            humidity: (data['main']['humidity'] as num).toInt(),
            condition: data['weather'][0]['main'] as String,
            icon: data['weather'][0]['icon'] as String,
          );

          points.add(point);

          // Add small delay to avoid rate limiting
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          debugPrint('Error fetching grid point at $lat,$lon: $e');
        }
      }
    }

    return points;
  }

  /// Get current weather with advanced parameters
  Future<Map<String, dynamic>> getWeatherWithAdvancedData({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/weather?lat=$latitude&lon=$longitude&appid=$openweatherApiKey&units=metric',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'temperature': data['main']['temp'],
          'feelsLike': data['main']['feels_like'],
          'pressure': data['main']['pressure'],
          'humidity': data['main']['humidity'],
          'windSpeed': data['wind']['speed'],
          'windDegree': data['wind']['deg'] ?? 0,
          'clouds': data['clouds']['all'],
          'visibility': data['visibility'],
          'condition': data['weather'][0]['main'],
          'description': data['weather'][0]['description'],
          'icon': data['weather'][0]['icon'],
          'lat': latitude,
          'lon': longitude,
        };
      } else {
        throw Exception('Failed to fetch advanced weather data');
      }
    } catch (e) {
      debugPrint('Error in getWeatherWithAdvancedData: $e');
      rethrow;
    }
  }
}
