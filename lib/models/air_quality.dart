import 'package:flutter/material.dart';

/// Domain model for air quality data returned by
/// OpenWeatherMap's Air Pollution API.
///
/// Docs:
/// https://api.openweathermap.org/data/2.5/air_pollution
class AirQualityIndex {
  /// AQI value on OpenWeather's 1–5 scale.
  final int aqi;

  /// Particulate matter (µg/m³)
  final double pm2_5;
  final double pm10;

  /// Gaseous pollutants (µg/m³)
  final double co;
  final double no;
  final double no2;
  final double o3;
  final double so2;
  final double nh3;

  /// Coordinates used for this measurement.
  final double latitude;
  final double longitude;

  AirQualityIndex({
    required this.aqi,
    required this.pm2_5,
    required this.pm10,
    required this.co,
    required this.no,
    required this.no2,
    required this.o3,
    required this.so2,
    required this.nh3,
    required this.latitude,
    required this.longitude,
  });

  factory AirQualityIndex.fromJson(
    Map<String, dynamic> json, {
    required double latitude,
    required double longitude,
  }) {
    final list = (json['list'] as List?) ?? [];
    if (list.isEmpty) {
      return AirQualityIndex(
        aqi: 0,
        pm2_5: 0,
        pm10: 0,
        co: 0,
        no: 0,
        no2: 0,
        o3: 0,
        so2: 0,
        nh3: 0,
        latitude: latitude,
        longitude: longitude,
      );
    }

    final main = (list[0] as Map<String, dynamic>)['main'] as Map<String, dynamic>? ?? {};
    final components =
        (list[0] as Map<String, dynamic>)['components'] as Map<String, dynamic>? ?? {};

    double toDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    return AirQualityIndex(
      aqi: (main['aqi'] as int?) ?? 0,
      pm2_5: toDouble(components['pm2_5']),
      pm10: toDouble(components['pm10']),
      co: toDouble(components['co']),
      no: toDouble(components['no']),
      no2: toDouble(components['no2']),
      o3: toDouble(components['o3']),
      so2: toDouble(components['so2']),
      nh3: toDouble(components['nh3']),
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Human‑readable category for the AQI value.
  String get category {
    switch (aqi) {
      case 1:
        return 'Good';
      case 2:
        return 'Fair';
      case 3:
        return 'Moderate';
      case 4:
        return 'Poor';
      case 5:
        return 'Very Poor';
      default:
        return 'No data';
    }
  }

  /// Color coding for AQI:
  /// 1 = Green, 2 = Light Green, 3 = Yellow, 4 = Orange, 5 = Red.
  Color get color {
    switch (aqi) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.yellow.shade700;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

