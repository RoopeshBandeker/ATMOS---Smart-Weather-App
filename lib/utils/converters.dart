import 'package:flutter/material.dart';

class WeatherIconUtils {
  static IconData getWeatherIcon(String condition, String iconCode) {
    final isNight = iconCode.endsWith('n');

    switch (condition.toLowerCase()) {
      case 'clear':
        return isNight ? Icons.nights_stay : Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
      case 'drizzle':
        return Icons.cloud_queue;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'snow':
        return Icons.ac_unit;
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
      case 'sand':
      case 'ash':
      case 'squall':
      case 'tornado':
        return Icons.cloud_circle;
      default:
        return Icons.wb_sunny;
    }
  }

  static Color getWeatherColor(String condition, String iconCode) {
    final isNight = iconCode.endsWith('n');

    switch (condition.toLowerCase()) {
      case 'clear':
        return isNight ? const Color(0xFF0F3460) : const Color(0xFF87CEEB);
      case 'clouds':
        return const Color(0xFF5A7A8F);
      case 'rain':
      case 'drizzle':
        return const Color(0xFF38495F);
      case 'thunderstorm':
        return const Color(0xFF1A1A2E);
      case 'snow':
        return const Color(0xFFB0D4F1);
      case 'mist':
      case 'fog':
        return const Color(0xFF7A8A99);
      default:
        return const Color(0xFF0099F7);
    }
  }

  static bool isNight(String iconCode) => iconCode.endsWith('n');
}

class UnitConversionUtils {
  /// Convert Celsius to Fahrenheit
  static double celsiusToFahrenheit(double celsius) {
    return (celsius * 9 / 5) + 32;
  }

  /// Convert m/s to km/h
  static double msToKmh(double ms) {
    return ms * 3.6;
  }

  /// Convert m/s to mph
  static double msToMph(double ms) {
    return ms * 2.237;
  }

  /// Convert m/s to knots
  static double msToKnots(double ms) {
    return ms * 1.944;
  }

  /// Format wind speed with unit
  static String formatWindSpeed(double ms, String unit) {
    double value = ms;
    String unitStr = 'm/s';

    if (unit == 'kmh') {
      value = msToKmh(ms);
      unitStr = 'km/h';
    } else if (unit == 'mph') {
      value = msToMph(ms);
      unitStr = 'mph';
    } else if (unit == 'knots') {
      value = msToKnots(ms);
      unitStr = 'kn';
    }

    return '${value.toStringAsFixed(1)} $unitStr';
  }

  /// Convert hPa to mbar (same value, different name)
  static double hpaToMbar(double hpa) => hpa;

  /// Convert hPa to mmHg
  static double hpaToMmhg(double hpa) {
    return hpa * 0.750062;
  }

  /// Convert hPa to inHg
  static double hpaToInhg(double hpa) {
    return hpa * 0.02953;
  }

  /// Format pressure with unit
  static String formatPressure(int hpa, String unit) {
    double value = hpa.toDouble();
    String unitStr = 'hPa';

    if (unit == 'mbar') {
      value = hpaToMbar(value);
      unitStr = 'mbar';
    } else if (unit == 'mmhg') {
      value = hpaToMmhg(value);
      unitStr = 'mmHg';
    } else if (unit == 'inhg') {
      value = hpaToInhg(value);
      unitStr = 'inHg';
    }

    return '${value.toStringAsFixed(2)} $unitStr';
  }
}
