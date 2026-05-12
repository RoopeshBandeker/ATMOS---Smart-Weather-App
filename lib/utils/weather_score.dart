import 'package:flutter/material.dart';

import '../models/daily_score.dart';
import '../models/weather.dart';

class WeatherScore {
  final int value;

  const WeatherScore(this.value);

  String get label {
    if (value >= 80) return 'Great';
    if (value >= 50) return 'Moderate';
    return 'Poor';
  }

  Color get color {
    if (value >= 80) return Colors.green;
    if (value >= 50) return Colors.amber;
    return Colors.red;
  }
}

class WeatherScoreCalculator {
  static WeatherScore calculate({
    required double temperature,
    required int humidity,
    required double windSpeed,
    required int aqi,
    required String condition,
  }) {
    var score = 100.0;

    if (temperature < 10) {
      score -= (10 - temperature) * 2.4;
    } else if (temperature > 30) {
      score -= (temperature - 30) * 2.8;
    }

    if (humidity > 60) {
      score -= (humidity - 60) * 0.45;
    } else if (humidity < 25) {
      score -= (25 - humidity) * 0.3;
    }

    if (windSpeed > 8) {
      score -= (windSpeed - 8) * 2.2;
    }

    switch (aqi) {
      case 2:
        score -= 6;
        break;
      case 3:
        score -= 15;
        break;
      case 4:
        score -= 28;
        break;
      case 5:
        score -= 40;
        break;
      default:
        break;
    }

    final normalizedCondition = condition.toLowerCase();
    if (normalizedCondition.contains('storm') ||
        normalizedCondition.contains('thunder')) {
      score -= 28;
    } else if (normalizedCondition.contains('rain') ||
        normalizedCondition.contains('drizzle')) {
      score -= 16;
    } else if (normalizedCondition.contains('snow')) {
      score -= 14;
    } else if (normalizedCondition.contains('mist') ||
        normalizedCondition.contains('fog') ||
        normalizedCondition.contains('haze')) {
      score -= 10;
    } else if (normalizedCondition.contains('cloud')) {
      score -= 4;
    }

    return WeatherScore(score.clamp(0, 100).round());
  }

  static int calculateValue({
    required double temperature,
    required int humidity,
    required double windSpeed,
    required int aqi,
    required String condition,
  }) {
    return calculate(
      temperature: temperature,
      humidity: humidity,
      windSpeed: windSpeed,
      aqi: aqi,
      condition: condition,
    ).value;
  }
}

class DailyScoreCalculator {
  static List<DailyScore> fromForecast(
    List<ForecastItem> items, {
    required int aqi,
  }) {
    final grouped = <DateTime, List<ForecastItem>>{};

    for (final item in items) {
      final dayKey = DateTime(
        item.dateTime.year,
        item.dateTime.month,
        item.dateTime.day,
      );
      grouped.putIfAbsent(dayKey, () => <ForecastItem>[]).add(item);
    }

    final sortedDays = grouped.keys.toList()..sort();

    return sortedDays.take(5).map((day) {
      final dayItems = grouped[day]!;
      final averageTemperature =
          dayItems.map((e) => e.temperature).reduce((a, b) => a + b) /
          dayItems.length;
      final minTemperature =
          dayItems.map((e) => e.tempMin).reduce((a, b) => a < b ? a : b);
      final maxTemperature =
          dayItems.map((e) => e.tempMax).reduce((a, b) => a > b ? a : b);
      final averageHumidity = (dayItems
                  .map((e) => e.humidity.toDouble())
                  .reduce((a, b) => a + b) /
              dayItems.length)
          .round();
      final averageWindSpeed =
          dayItems.map((e) => e.windSpeed).reduce((a, b) => a + b) /
          dayItems.length;

      final conditionCounts = <String, int>{};
      final iconCounts = <String, int>{};
      for (final entry in dayItems) {
        conditionCounts.update(entry.condition, (value) => value + 1,
            ifAbsent: () => 1);
        iconCounts.update(entry.icon, (value) => value + 1, ifAbsent: () => 1);
      }

      final dominantCondition = conditionCounts.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
      final dominantIcon = iconCounts.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;

      final score = WeatherScoreCalculator.calculateValue(
        temperature: averageTemperature,
        humidity: averageHumidity,
        windSpeed: averageWindSpeed,
        aqi: aqi,
        condition: dominantCondition,
      );

      return DailyScore(
        date: day,
        score: score,
        averageTemperature: averageTemperature,
        minTemperature: minTemperature,
        maxTemperature: maxTemperature,
        averageHumidity: averageHumidity,
        averageWindSpeed: averageWindSpeed,
        aqi: aqi,
        condition: dominantCondition,
        icon: dominantIcon,
      );
    }).toList();
  }
}
