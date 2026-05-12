import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/air_quality.dart';
import '../models/settings.dart';
import '../models/uv.dart';
import '../models/weather.dart';
import '../models/hourly_forecast.dart';
import '../utils/converters.dart';
import '../utils/time_formatters.dart';

class ForecastScreen extends StatelessWidget {
  final ValueNotifier<WeatherData?> weatherNotifier;
  final ValueNotifier<AirQualityIndex?> aqiNotifier;
  final ValueNotifier<UvIndex?> uvNotifier;
  final AppSettings settings;

  const ForecastScreen({
    required this.weatherNotifier,
    required this.aqiNotifier,
    required this.uvNotifier,
    required this.settings,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: null,
      body: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top * 0.9,
        ),
        child: AnimatedBuilder(
        animation: Listenable.merge([weatherNotifier, aqiNotifier, uvNotifier]),
        builder: (context, child) {
          final weatherData = weatherNotifier.value;
          final aqi = aqiNotifier.value;
          final uv = uvNotifier.value;

          if (weatherData == null) {
            return const Center(
              child: Text('Forecast data will appear once weather loads.'),
            );
          }

          final safeUv = (uv?.max ?? 0).toInt();

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              16, // left padding
              10, // top padding
              16, // right padding
              24, // bottom padding
            ),
            children: [
              // TOP: Sun card (left) + UV + AQI stacked (right)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    // Controls width ratio of Sunrise/Sunset card
                    flex: 1,
                    child: _buildSunCard(context, weatherData.current),
                  ),
                  // Controls spacing between left and right card sections
                  const SizedBox(width: 12),
                  Expanded(
                    // Controls width ratio of UV + AQI card column
                    flex: 1,
                    child: Column(
                      children: [
                        _buildUVCard(safeUv),
                        // Controls spacing between UV and AQI cards
                        const SizedBox(height: 12),
                        _buildAQICard(context, aqi),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // HUMIDITY + PRESSURE
              Row(
                children: [
                  Expanded(child: _buildHumidityCard(context, weatherData.current)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildPressureCard(context, weatherData.current)),
                ],
              ),

              const SizedBox(height: 12),

              // TEMPERATURE GRAPH
              _buildTemperatureGraphCard(context, weatherData.hourlyForecast),

              const SizedBox(height: 10),

              // WIND CARD
              _buildWindCard(context, weatherData.current),
            ],
          );
        },
       ),
     ));
  }

   // DASHBOARD BUILDER METHODS

   Widget _buildSunCard(BuildContext context, CurrentWeather current) {
     final sunriseTime = formatSunTime(current.sunrise, settings);
     final sunrisePeriod = formatMeridiem(current.sunrise, settings);
     final sunsetTime = formatSunTime(current.sunset, settings);
     final sunsetPeriod = formatMeridiem(current.sunset, settings);

     return Container(
      // Controls Sun card height (makes it taller vertically)
      height: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          // Controls rounded corners of the Sun card
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 24,
              spreadRadius: -4,
              offset: const Offset(0, 12),
            ),
          ],
        ),
       // Controls internal spacing inside the Sun card
       padding: const EdgeInsets.all(16),
        child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Text(
             'SUNRISE',
             style: Theme.of(context).textTheme.labelSmall?.copyWith(
               color: const Color(0xFF9CA3AF),
               fontWeight: FontWeight.w700,
               letterSpacing: 1.25,
               fontSize: 11,
             ),
           ),
           const SizedBox(height: 15),
           Row(
             crossAxisAlignment: CrossAxisAlignment.center,
             children: [
               SvgPicture.asset(
                 'assets/forecast_screen_assets/sunrise.svg',
                 width: 72,
                 height: 72,
                 fit: BoxFit.contain,
               ),
               const SizedBox(width: 10),
               Expanded(
                 child: Align(
                   alignment: Alignment.centerRight,
                   child: _SunEventTime(
                     time: sunriseTime,
                     meridiem: sunrisePeriod,
                     alignment: CrossAxisAlignment.end,
                   ),
                 ),
               ),
             ],
           ),
           const SizedBox(height: 15),
           Container(
             height: 1,
             color: const Color(0xFF1F2937).withValues(alpha: 0.14),
           ),
           const SizedBox(height: 15),
           Text(
             'SUNSET',
             style: Theme.of(context).textTheme.labelSmall?.copyWith(
               color: const Color(0xFF9CA3AF),
               fontWeight: FontWeight.w700,
               letterSpacing: 1.25,
               fontSize: 11,
             ),
           ),
           const SizedBox(height: 15),
           Row(
             crossAxisAlignment: CrossAxisAlignment.center,
             children: [
               Expanded(
                 child: _SunEventTime(
                   time: sunsetTime,
                   meridiem: sunsetPeriod,
                   alignment: CrossAxisAlignment.start,
                 ),
               ),
               const SizedBox(width: 10),
               SvgPicture.asset(
                 'assets/forecast_screen_assets/sunset.svg',
                 width: 72,
                 height: 72,
                 fit: BoxFit.contain,
               ),
             ],
           ),
         ],
       ),
     );
    }

    Widget _buildUVCard(int uv) {
      return _UvIndexCard(uv: uv);
    }

    Widget _buildAQICard(BuildContext context, AirQualityIndex? aqi) {
     final displayValue = _displayAqiValue(aqi);
     final subtitle = aqi?.category ?? 'Moderate';
     final progress = (displayValue / 100).clamp(0.0, 1.0);

     return Container(
        // Controls AQI card square height
         height: 135,
         decoration: BoxDecoration(
           color: Colors.white,
           // Controls rounded corners of the AQI card
           borderRadius: BorderRadius.circular(24),
           boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 24,
              spreadRadius: -4,
              offset: const Offset(0, 12),
            ),
           ],
         ),
         // Controls internal spacing inside the AQI card
         padding: const EdgeInsets.all(16),
         child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AQI',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFF9CA3AF),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.25,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$displayValue',
              style: const TextStyle(
                fontSize: 34,
                height: 0.95,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111111),
                letterSpacing: -1.3,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final indicatorLeft =
                    (constraints.maxWidth - 14) * progress;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF34C759),
                            Color(0xFFFFD60A),
                            Color(0xFFFF9F0A),
                            Color(0xFFFF453A),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: indicatorLeft,
                      top: -3,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFD1D5DB),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.16),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      );
     }

    int _displayAqiValue(AirQualityIndex? aqi) {
     switch (aqi?.aqi ?? 3) {
       case 1:
         return 18;
       case 2:
         return 34;
       case 3:
         return 51;
       case 4:
         return 76;
       case 5:
         return 95;
       default:
         return 51;
     }
    }
    

Widget _buildHumidityCard(BuildContext context, CurrentWeather current) {
  final humidityLabel = _humidityDescriptor(current.humidity);

  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          blurRadius: 24,
          spreadRadius: -4,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'HUMIDITY',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFF9CA3AF),
            fontWeight: FontWeight.w700,
            letterSpacing: 1.25,
            fontSize: 11,
          ),
        ),

        const SizedBox(height: 10),

        Padding(
          // Controls horizontal shift of humidity value to the right
          padding: const EdgeInsets.only(left: 7),

          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${current.humidity}',
                      style: const TextStyle(
                        fontSize: 36,
                        height: 0.95,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111111),
                        letterSpacing: -1.3,
                      ),
                    ),
                    const TextSpan(
                      text: '%',
                      style: TextStyle(
                        fontSize: 22,
                        height: 1.0,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),

              // Controls spacing between % and descriptor
              const SizedBox(width: 10),

              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  humidityLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const ui.Color.fromARGB(255, 83, 88, 99),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

String _humidityDescriptor(int humidity) {
  if (humidity < 35) return 'Low';
  if (humidity <= 60) return 'Moderate';
  if (humidity <= 75) return 'Humid';
  return 'Very Humid';
}
     Widget _buildPressureCard(BuildContext context, CurrentWeather current) {
     final unit = settings.pressureUnit.toString().split('.').last;
     return Container(
       decoration: BoxDecoration(
         color: Colors.white.withValues(alpha:0.9),
         borderRadius: BorderRadius.circular(20),
         boxShadow: [
           BoxShadow(
             color: Colors.black.withValues(alpha:0.15),
             blurRadius: 10,
             offset: const Offset(0, 4),
           ),
         ],
       ),
       padding: const EdgeInsets.all(12),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Text('PRESSURE', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
           const SizedBox(height: 8),
           FittedBox(
             fit: BoxFit.scaleDown,
             alignment: Alignment.centerLeft,
             child: Text(UnitConversionUtils.formatPressure(current.pressure, unit), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black)),
           ),
         ],
       ),
     );
    }
Widget _buildTemperatureGraphCard(
  BuildContext context,
  List<HourlyForecast> hourlyForecast,
) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(25),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          blurRadius: 24,
          spreadRadius: -4,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TEMPERATURE GRAPH',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 180, // increased from 110
          child: _buildTemperatureChart(context, hourlyForecast),
        ),
      ],
    ),
  );
}

Widget _buildWindCard(BuildContext context, CurrentWeather current) {
  final windUnit = settings.windSpeedUnit.toString().split('.').last;
  final formattedWindSpeed = UnitConversionUtils.formatWindSpeed(
    current.windSpeed,
    windUnit,
  );
  final windSpeedParts = formattedWindSpeed.split(' ');
  final windSpeedValue = windSpeedParts.first;
  final windSpeedUnitLabel =
      windSpeedParts.length > 1 ? windSpeedParts.sublist(1).join(' ') : '';
  final directionShort = _formatDirectionShort(current.windDegree);
  final directionLabel = _formatDirectionName(current.windDegree);

  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(23),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 4.3,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    padding: const EdgeInsets.fromLTRB(15, 12, 12, 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [

              // ── WIND label ─────────────────────────
              const Text(
                'WIND',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 10),

              // ── Speed value + unit/label row ────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    windSpeedValue,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                      color: Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(width: 17),
                  Text(
                    '$windSpeedUnitLabel\nSpeed',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ── Divider ─────────────────────────────
              Container(
                height: 1.5,
                width: 147,
                color: const Color(0xFF000000).withValues(alpha: 0.15),
              ),

              const SizedBox(height: 8),

              // ── Direction name + label row ──────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    directionLabel,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.17,
                      color: Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Direction',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _WindCompass(
          directionShort: directionShort,
          directionDegrees: current.windDegree.toDouble(),
          size: 110,
        ),
      ],
    ),
  );
}
String _formatDirectionShort(int deg) {
  const arrows = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
  final index = (((deg % 360) + 360) % 360 + 22.5) ~/ 45 % 8;
  return arrows[index];
}

String _formatDirectionName(int deg) {
  const directions = [
    'North',
    'North-East',
    'East',
    'South-East',
    'South',
    'South-West',
    'West',
    'North-West',
  ];
  final index = (((deg % 360) + 360) % 360 + 22.5) ~/ 45 % 8;
  return directions[index];
}
Widget _buildTemperatureChart(
  BuildContext context,
  List<HourlyForecast> hourlyForecast,
) {
  final sampledItems = hourlyForecast.take(10).toList();
  final chartTemps = sampledItems.isEmpty
      ? [0.0, 0.0, 0.0, 0.0, 0.0]
      : sampledItems.map((item) {
          return settings.temperatureUnit == TemperatureUnit.celsius
              ? item.temperature
              : UnitConversionUtils.celsiusToFahrenheit(item.temperature);
        }).toList();
  final count = chartTemps.length;
  final minTemp = chartTemps.reduce((a, b) => a < b ? a : b);
  final maxTemp = chartTemps.reduce((a, b) => a > b ? a : b);
  final padding = ((maxTemp - minTemp).abs() * 0.35).clamp(2.0, 6.0);
  final minY = minTemp - padding;
  final maxY = maxTemp + padding;

  final labels = sampledItems.isEmpty
      ? List.generate(count, (i) => '')
      : sampledItems
          .map((item) => formatHourLabel(item.dateTime, settings))
          .toList();
  return IgnorePointer(
    child: LineChart(
      LineChartData(
        minX: 0,
        maxX: (count - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineTouchData: const LineTouchData(enabled: false),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: false,
          drawVerticalLine: true,
          verticalInterval: 1,
          getDrawingVerticalLine: (value) => const FlLine(
            color: Color(0xFFB1B1B1),
            strokeWidth: 0.5,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index < 0 || index >= labels.length) {
                  return const SizedBox.shrink();
                }
                return SizedBox(
                  height: 36,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      labels[index],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2E2E30),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            curveSmoothness: 0.35,
            color: const Color(0xFF6473FF),
            barWidth: 2.0,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF9AA5FF).withValues(alpha: 0.45),
                  const Color(0xFFBEC6FF).withValues(alpha: 0.25),
                  const Color(0xFFFFFFFF).withValues(alpha: 0.0),
                ],
              ),
            ),
            spots: List.generate(
              count,
              (i) => FlSpot(i.toDouble(), chartTemps[i]),
            ),
          ),
        ],
      ),
    ),
  );
}
}
class _UvIndexCard extends StatelessWidget {
  final int uv; // 0–11

  const _UvIndexCard({required this.uv});

  String _getLevel() {
    if (uv <= 2) return 'Low';
    if (uv <= 5) return 'Mid';
    if (uv <= 7) return 'High';
    if (uv <= 10) return 'Very High';
    return 'Extreme';
  }

  String _getAdvice() {
    if (uv <= 2) return 'No protection needed.';
    if (uv <= 5) return 'Some protection required.';
    if (uv <= 7) return 'Protection essential.';
    if (uv <= 10) return 'Extra protection needed.';
    return 'Stay indoors if possible.';
  }

  @override
  Widget build(BuildContext context) {
    final uvValue = uv.clamp(0, 11);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.only(left: 11, top: 8, right: 11, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Label ───────────────────────────────────
          const Text(
            'UV INDEX',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 10,
              height: 1.5,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 4),

          // ── Value + Level inline ─────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$uvValue',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 48,
                  height: 1.0,
                  color: Color(0xFF000000),
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  _getLevel(),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    fontSize: 18,
                    height: 1.56,
                    color: Color(0xFF000000),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // ── Gradient bar + indicator ─────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              const double barHeight = 4;
              const double indicatorSize = 14;
              final double barWidth = constraints.maxWidth;
              final double indicatorLeft =
                  ((uvValue / 11) * (barWidth - indicatorSize))
                      .clamp(0.0, barWidth - indicatorSize);

              return SizedBox(
                width: barWidth,
                height: indicatorSize,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Gradient bar
                    Positioned(
                      top: (indicatorSize - barHeight) / 2,
                      left: 0,
                      width: barWidth,
                      child: Container(
                        height: barHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF2A1AD8),
                              Color(0xFF4E26E2),
                              Color(0xFF7231EC),
                              Color(0xFF953DF5),
                              Color(0xFFAB4DFA),
                              Color(0xFFE552FF),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Indicator dot
                    Positioned(
                      left: indicatorLeft,
                      top: 0,
                      child: Container(
                        width: indicatorSize,
                        height: indicatorSize,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFC3C3C3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 1.2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 6),

          // ── Advice text ──────────────────────────────
          Text(
            _getAdvice(),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              fontSize: 11,
              height: 1.5,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class TemperatureTrendChart extends StatelessWidget {
  final List<HourlyForecast> items;
  final AppSettings settings;

  const TemperatureTrendChart({
    super.key,
    required this.items,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox(
        height: 160,
        child: Center(child: Text('No temperature data available')),
      );
    }

    final hourly = items.take(10).toList();
    final minTemp = hourly.map((e) => e.temperature).reduce((a, b) => a < b ? a : b);
    final maxTemp = hourly.map((e) => e.temperature).reduce((a, b) => a > b ? a : b);
    final range = (maxTemp - minTemp).clamp(1, double.infinity);

    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: hourly.map((item) {
          final temperature = settings.temperatureUnit == TemperatureUnit.celsius
              ? item.temperature
              : UnitConversionUtils.celsiusToFahrenheit(item.temperature);
          final normalized = ((temperature - minTemp) / range).clamp(0.0, 1.0);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${temperature.toStringAsFixed(0)}°',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 100 * normalized + 24,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatHourLabel(item.dateTime, settings),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SunEventTime extends StatelessWidget {
  final String time;
  final String meridiem;
  final CrossAxisAlignment alignment;

  const _SunEventTime({
    required this.time,
    required this.meridiem,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          time,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 34,
            height: 0.95,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111111),
            letterSpacing: -1.2,
          ),
        ),
        if (meridiem.isNotEmpty) ...[
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              meridiem,
              style: const TextStyle(
                fontSize: 20,
                height: 1.0,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111111),
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _WindCompass extends StatelessWidget {
  final String directionShort;
  final double directionDegrees;
  final double size;

  const _WindCompass({
    required this.directionShort,
    required this.directionDegrees,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    // The asset points north-east by default, so offset it by 45deg.
    final needleAngle = (directionDegrees - 45) * math.pi / 180;
    final needleSize = size * 0.9;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: const _WindCompassPainter(),
          ),
          Center(
            child: Transform.rotate(
              angle: needleAngle,
              child: SvgPicture.asset(
                'assets/forecast_screen_assets/windarrow.svg',
                width: needleSize,
                height: needleSize,
              ),
            ),
          ),
          Container(
            width: size * 0.42,
            height: size * 0.42,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  spreadRadius: -2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              directionShort,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111111),
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WindCompassPainter extends CustomPainter {
  const _WindCompassPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width * 0.47;
    final innerRadius = size.width * 0.30;

    // === Dotted outer ring ===
    final dotPaint = Paint()..color = const Color(0xFF444444);
    const dotCount = 40;
    for (var i = 0; i < dotCount; i++) {
      final angle = (i / dotCount) * 2 * math.pi - (math.pi / 2);
      final point = Offset(
        center.dx + math.cos(angle) * outerRadius,
        center.dy + math.sin(angle) * outerRadius,
      );
      canvas.drawCircle(point, 1.2, dotPaint);
    }

    // === Inner guide rings ===
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFFE5E7EB);
    canvas.drawCircle(center, outerRadius - 8, ringPaint);
    canvas.drawCircle(center, innerRadius + 10, ringPaint);

    // === Cardinal direction labels: N, E, S, W ===
    const cardinalLabels = ['N', 'E', 'S', 'W'];
    const cardinalAngles = [
      -math.pi / 2, // N (top)
      0.0, // E (right)
      math.pi / 2, // S (bottom)
      math.pi, // W (left)
    ];
    final labelRadius = outerRadius - 13;
    for (var i = 0; i < cardinalLabels.length; i++) {
      final angle = cardinalAngles[i];
      final pos = Offset(
        center.dx + 7 + math.cos(angle) * labelRadius,
        center.dy + math.sin(angle) * labelRadius,
      );
      _paintLabel(canvas, cardinalLabels[i], pos);
    }
  }

  void _paintLabel(Canvas canvas, String text, Offset pos) {
    final paragraphBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
      ),
    )
      ..pushStyle(
        ui.TextStyle(
          color: const Color(0xFF000000),
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      )
      ..addText(text);

    final paragraph = paragraphBuilder.build()
      ..layout(const ui.ParagraphConstraints(width: 20));

    canvas.drawParagraph(
      paragraph,
      pos - Offset(paragraph.width / 2, paragraph.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _WindCompassPainter oldDelegate) {
    return false;
  }
}
