import 'package:flutter/material.dart';

import '../models/hourly_forecast.dart';
import '../models/settings.dart';
import '../utils/time_formatters.dart';
import '../utils/converters.dart';
import '../utils/weather_icons.dart' as weather_icons;

class HourlyForecastWidget extends StatelessWidget {
  final List<HourlyForecast> hourlyForecast;
  final AppSettings settings;

  const HourlyForecastWidget({
    required this.hourlyForecast,
    required this.settings,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (hourlyForecast.isEmpty) {
      return const SizedBox.shrink();
    }

    const horizontalPadding = 16.0;
    const itemSpacing = 10.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final calculatedWidth =
        (screenWidth - (horizontalPadding * 2) - (itemSpacing * 3)) / 4;
    final itemWidth = calculatedWidth.clamp(70.0, 80.0);

    return SizedBox(
      height: 132,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: hourlyForecast.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: itemSpacing),
        itemBuilder: (context, index) {
          final forecast = hourlyForecast[index];
          return SizedBox(
            width: itemWidth,
            child: _HourlyForecastItem(forecast: forecast, settings: settings),
          );
        },
      ),
    );
  }
}

class _HourlyForecastItem extends StatelessWidget {
  final HourlyForecast forecast;
  final AppSettings settings;

  const _HourlyForecastItem({required this.forecast, required this.settings});

  @override
  Widget build(BuildContext context) {
    final temp = settings.temperatureUnit == TemperatureUnit.celsius
        ? forecast.temperature
        : UnitConversionUtils.celsiusToFahrenheit(forecast.temperature);
    final unit = settings.temperatureUnit == TemperatureUnit.celsius
        ? '°C'
        : '°F';
    final formattedTime = formatHourLabel(forecast.dateTime, settings);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            formattedTime,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          weather_icons.weatherIconWidget(
            forecast.condition,
            forecast.icon,
            width: 24,
            height: 24,
          ),
          const SizedBox(height: 8),
          Text(
            '${temp.round()}$unit',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
