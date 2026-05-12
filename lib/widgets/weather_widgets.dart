import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weather.dart';
import '../utils/converters.dart';
import '../models/settings.dart';
import '../utils/weather_icons.dart' as weather_icons;

class CurrentWeatherCard extends StatelessWidget {
  final CurrentWeather weather;
  final AppSettings settings;
  final String? highLowText;

  const CurrentWeatherCard({
    required this.weather,
    required this.settings,
    this.highLowText,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final temp = settings.temperatureUnit == TemperatureUnit.celsius
        ? weather.temperature
        : UnitConversionUtils.celsiusToFahrenheit(weather.temperature);
    final feelsLike = settings.temperatureUnit == TemperatureUnit.celsius
        ? weather.feelsLike
        : UnitConversionUtils.celsiusToFahrenheit(weather.feelsLike);
    final unit = settings.temperatureUnit == TemperatureUnit.celsius ? '°C' : '°F';

    return Column(
      children: [
        Text(
          weather.locationName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        weather_icons.weatherIconWidget(
          weather.condition,
          weather.icon,
          width: 80,
          height: 80,
        ),
        const SizedBox(height: 16),
        Text(
          '${temp.toStringAsFixed(1)}$unit',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (highLowText != null) ...[
          const SizedBox(height: 8),
          Text(
            highLowText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          'Feels like ${feelsLike.toStringAsFixed(1)}$unit',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          weather.condition.toUpperCase(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white70,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class WeatherInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const WeatherInfoCard({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(side: BorderSide.none),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white70, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ForecastCard extends StatelessWidget {
  final ForecastItem forecast;
  final AppSettings settings;

  const ForecastCard({
    required this.forecast,
    required this.settings,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final temp = settings.temperatureUnit == TemperatureUnit.celsius
        ? forecast.temperature
        : UnitConversionUtils.celsiusToFahrenheit(forecast.temperature);
    final unit = settings.temperatureUnit == TemperatureUnit.celsius ? '°C' : '°F';

    return Card(
      color: Colors.white.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(side: BorderSide.none),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('MMM dd').format(forecast.dateTime),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            weather_icons.weatherIconWidget(
              forecast.condition,
              forecast.icon,
              width: 32,
              height: 32,
            ),
            const SizedBox(height: 8),
            Text(
              '${temp.toStringAsFixed(0)}$unit',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              forecast.condition,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
