import 'package:flutter/material.dart';
import '../models/hourly_forecast.dart';
import '../models/settings.dart';
import '../utils/converters.dart';
import '../utils/time_formatters.dart';
import '../utils/weather_icons.dart' as weather_icons;

class HourlyForecastList extends StatelessWidget {
  final List<HourlyForecast> items;
  final bool isLoading;
  final AppSettings settings;

  const HourlyForecastList({
    required this.items,
    required this.isLoading,
    required this.settings,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 136,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (items.isEmpty) {
      return const SizedBox(
        height: 136,
        child: Center(
          child: Text('Hourly forecast not available'),
        ),
      );
    }

    final unit =
        settings.temperatureUnit == TemperatureUnit.celsius ? 'C' : 'F';

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final temperature = settings.temperatureUnit == TemperatureUnit.celsius
              ? item.temperature
              : UnitConversionUtils.celsiusToFahrenheit(item.temperature);

          return Padding(
            padding: EdgeInsets.only(right: index == items.length - 1 ? 0 : 10),
            child: Container(
              width: 92,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatHourLabelSpaced(item.dateTime, settings),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  weather_icons.weatherIconWidget(
                    item.condition,
                    item.icon,
                    width: 28,
                    height: 28,
                  ),
                  Text(
                    '${temperature.toStringAsFixed(0)}$unit',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
