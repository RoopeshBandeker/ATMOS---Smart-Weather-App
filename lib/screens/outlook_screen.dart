import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;

import '../models/location_search_result.dart';
import '../models/settings.dart';
import '../models/weather.dart';
import '../services/cache_service.dart';
import '../services/weather_service.dart';
import '../utils/converters.dart';
import '../utils/weather_score.dart';
import '../utils/weather_icons.dart' as weather_icons;

class OutlookScreen extends StatefulWidget {
  final WeatherService weatherService;
  final CacheService cacheService;
  final AppSettings settings;
  final bool enableAutoLoad;

  const OutlookScreen({
    required this.weatherService,
    required this.cacheService,
    required this.settings,
    this.enableAutoLoad = true,
    super.key,
  });

  @override
  State<OutlookScreen> createState() => OutlookScreenState();
}

class OutlookScreenState extends State<OutlookScreen> {
  WeatherData? _weather;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.enableAutoLoad) {
      refreshWeather();
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> refreshWeather() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final lastCity = widget.cacheService.getLastLocation();
      final weather = (lastCity != null && lastCity.isNotEmpty)
          ? await widget.weatherService.getWeatherByCity(lastCity)
          : await widget.weatherService.getCurrentLocationWeather();

      if (!mounted) return;
      setState(() {
        _weather = weather;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> refreshForLocation(LocationSearchResult location) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final weather = await widget.weatherService.getWeatherByCoordinates(
        location.latitude,
        location.longitude,
      );

      if (!mounted) return;
      await widget.cacheService.saveLastLocation(location.cityName);
      setState(() {
        _weather = weather;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: null,
      body: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top * 0.5,
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_weather == null) {
      return const Center(
        child: Text('Outlook data unavailable'),
      );
    }

    final dailyForecast = _extractDailyForecast(_weather!.forecast.items);

    // FIX: guard against empty forecast list
    if (dailyForecast.isEmpty) {
      return const Center(
        child: Text('No forecast data available'),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: dailyForecast.length,
          itemBuilder: (context, index) {
            final entry = dailyForecast[index];
            final isToday = index == 0;
            final label = DateFormat('EEEE').format(entry.dateTime);

            return _ExpandableDailyCard(
              item: entry,
              settings: widget.settings,
              label: label,
              isToday: isToday,
              aqi: _weather!.current.aqi,
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  List<_DailyAggregate> _extractDailyForecast(List<ForecastItem> items) {
    // FIX: guard against empty items list
    if (items.isEmpty) return [];

    final Map<String, List<ForecastItem>> byDay = {};
    for (final item in items) {
      final key = DateFormat('yyyy-MM-dd').format(item.dateTime);
      byDay.putIfAbsent(key, () => []).add(item);
    }

    final result = <_DailyAggregate>[];
    final orderedEntries = byDay.entries.toList()
      ..sort(
          (a, b) => a.value.first.dateTime.compareTo(b.value.first.dateTime));
    for (final entry in orderedEntries) {
      if (result.length >= 5) break;
      // FIX: skip any day bucket that somehow ended up empty
      if (entry.value.isEmpty) continue;
      result.add(_DailyAggregate.fromItems(entry.value));
    }
    return result;
  }
}

// ─── Daily Aggregate ─────────────────────────────────────────────────────────

class _DailyAggregate {
  final DateTime dateTime;
  final double tempMax;
  final double tempMin;
  final double tempAvg;
  final double avgHumidity;
  final double avgWindSpeed;
  final double maxPop;
  final String condition;
  final String icon;

  const _DailyAggregate({
    required this.dateTime,
    required this.tempMax,
    required this.tempMin,
    required this.tempAvg,
    required this.avgHumidity,
    required this.avgWindSpeed,
    required this.maxPop,
    required this.condition,
    required this.icon,
  });

  factory _DailyAggregate.fromItems(List<ForecastItem> items) {
    // FIX: replaced assert() with a proper guard — assert() crashes in debug mode
    if (items.isEmpty) {
      return _DailyAggregate(
        dateTime: DateTime.now(),
        tempMax: 0,
        tempMin: 0,
        tempAvg: 0,
        avgHumidity: 0,
        avgWindSpeed: 0,
        maxPop: 0,
        condition: '',
        icon: '',
      );
    }

    final temps = items.map((e) => e.tempMax).toList()
      ..addAll(items.map((e) => e.tempMin));
    final maxTemp = items.map((e) => e.tempMax).reduce(math.max);
    final minTemp = items.map((e) => e.tempMin).reduce(math.min);
    final avgTemp = temps.reduce((a, b) => a + b) / temps.length;
    final avgHum = items
            .map((e) => e.humidity.toDouble())
            .reduce((a, b) => a + b) /
        items.length;
    final avgWind =
        items.map((e) => e.windSpeed).reduce((a, b) => a + b) / items.length;
    final maxPop = items.map((e) => e.pop).reduce(math.max);

    final midday = items.firstWhere(
      (e) => e.dateTime.hour >= 11 && e.dateTime.hour <= 14,
      orElse: () => items[items.length ~/ 2],
    );

    return _DailyAggregate(
      dateTime: items.first.dateTime,
      tempMax: maxTemp,
      tempMin: minTemp,
      tempAvg: avgTemp,
      avgHumidity: avgHum,
      avgWindSpeed: avgWind,
      maxPop: maxPop,
      condition: midday.condition,
      icon: midday.icon,
    );
  }
}

// ─── Score helpers ────────────────────────────────────────────────────────────

String _scoreLabel(int score) {
  if (score >= 80) return 'Great';
  if (score >= 60) return 'Moderate';
  if (score >= 40) return 'Poor';
  return 'Bad';
}

Color _scoreColor(int score) {
  if (score >= 80) return const Color(0xFF34C759);
  if (score >= 60) return const Color(0xFFFFCC00);
  if (score >= 40) return const Color(0xFFFF9500);
  return const Color(0xFFFF3B30);
}

int _displayAqiValue(int aqi) {
  switch (aqi) {
    case 1: return 18;
    case 2: return 34;
    case 3: return 51;
    case 4: return 76;
    case 5: return 95;
    default: return 51;
  }
}

// ─── Expandable Card ──────────────────────────────────────────────────────────

class _ExpandableDailyCard extends StatefulWidget {
  final _DailyAggregate item;
  final AppSettings settings;
  final String label;
  final bool isToday;
  final int aqi;

  const _ExpandableDailyCard({
    required this.item,
    required this.settings,
    required this.label,
    required this.isToday,
    required this.aqi,
  });

  @override
  State<_ExpandableDailyCard> createState() => _ExpandableDailyCardState();
}

class _ExpandableDailyCardState extends State<_ExpandableDailyCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnim;
  late Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    _expandAnim =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _rotateAnim = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  int _dayScore() {
    return WeatherScoreCalculator.calculateValue(
      temperature: widget.item.tempAvg,
      humidity: widget.item.avgHumidity.round(),
      windSpeed: widget.item.avgWindSpeed,
      aqi: widget.aqi,
      condition: widget.item.condition,
    );
  }

  double _displayTemp(double celsius) {
    return widget.settings.temperatureUnit == TemperatureUnit.celsius
        ? celsius
        : UnitConversionUtils.celsiusToFahrenheit(celsius);
  }

  String _displayWindSpeed(double windSpeedMs) {
    return UnitConversionUtils.formatWindSpeed(
      windSpeedMs,
      widget.settings.windSpeedUnit.toString().split('.').last,
    );
  }

  String get _unit =>
      widget.settings.temperatureUnit == TemperatureUnit.celsius ? '°C' : '°F';

  @override
  Widget build(BuildContext context) {
    final score = _dayScore();
    final scoreCol = _scoreColor(score);
    final scoreIconBg = scoreCol.withValues(alpha: 0.13);
    final scoreLbl = _scoreLabel(score);
    final avgTemp = _displayTemp(widget.item.tempAvg);
    final maxTemp = _displayTemp(widget.item.tempMax);
    final minTemp = _displayTemp(widget.item.tempMin);
    final dateStr = DateFormat('d/M/yyyy').format(widget.item.dateTime);
    final pop = (widget.item.maxPop * 100).round();
    final displayedAqi = _displayAqiValue(widget.aqi);
    final displayedWindSpeed = _displayWindSpeed(widget.item.avgWindSpeed);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: widget.isToday
                ? scoreCol.withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: widget.isToday ? 20 : 12,
            spreadRadius: widget.isToday ? 1 : 0,
            offset: const Offset(0, 4),
          ),
        ],
        border: widget.isToday
            ? Border.all(color: scoreCol.withValues(alpha: 0.35), width: 1.5)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _toggle,
            splashColor: scoreCol.withValues(alpha: 0.07),
            highlightColor: scoreCol.withValues(alpha: 0.03),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Collapsed row ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 16, 18, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Weather icon in rounded square
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: scoreIconBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: weather_icons.weatherIconWidget(
                            widget.item.condition,
                            widget.item.icon,
                            width: 36,
                            height: 36,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Day name + date + temp + badge
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.label,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1A1A),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateStr,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF9A9AA0),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  '${avgTemp.toStringAsFixed(0)} $_unit',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2A2A2A),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: scoreCol,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    scoreLbl,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      _CArcRing(score: score, color: scoreCol, size: 68),
                    ],
                  ),
                ),

                // ── Chevron ──
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: RotationTransition(
                    turns: _rotateAnim,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey.shade400,
                      size: 22,
                    ),
                  ),
                ),

                // ── Expanded details ──
                SizeTransition(
                  sizeFactor: _expandAnim,
                  axisAlignment: -1,
                  child: _ExpandedDetails(
                    minTemp: minTemp,
                    maxTemp: maxTemp,
                    humidity: widget.item.avgHumidity,
                    windSpeedLabel: displayedWindSpeed,
                    aqi: displayedAqi,
                    pop: pop,
                    condition: widget.item.condition,
                    unit: _unit,
                    accentColor: scoreCol,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── C-Arc Ring ───────────────────────────────────────────────────────────────

class _CArcRing extends StatelessWidget {
  final int score;
  final Color color;
  final double size;

  const _CArcRing({
    required this.score,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CArcPainter(
          color: color,
          strokeWidth: 6.0,
          progress: (score / 100).clamp(0.0, 1.0),
        ),
        child: Center(
          child: Text(
            '$score',
            style: TextStyle(
              fontSize: size * 0.30,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _CArcPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double progress;

  const _CArcPainter({
    required this.color,
    required this.strokeWidth,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // FIX: removed unused sweepAngle variable
    const startAngle = 5 * math.pi / 4; // 225°

    canvas.drawArc(
      rect,
      startAngle - (3 * math.pi / 4),
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_CArcPainter old) =>
      old.color != color || old.progress != progress;
}

// ─── Expanded Details Panel ───────────────────────────────────────────────────

class _ExpandedDetails extends StatelessWidget {
  final double minTemp;
  final double maxTemp;
  final double humidity;
  final String windSpeedLabel;
  final int aqi;
  final int pop;
  final String condition;
  final String unit;
  final Color accentColor;

  const _ExpandedDetails({
    required this.minTemp,
    required this.maxTemp,
    required this.humidity,
    required this.windSpeedLabel,
    required this.aqi,
    required this.pop,
    required this.condition,
    required this.unit,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        border: Border(
          top: BorderSide(
            color: accentColor.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _DetailTile(
                  icon: Icons.thermostat_outlined,
                  label: 'Min / Max',
                  value:
                      '${minTemp.toStringAsFixed(1)} / ${maxTemp.toStringAsFixed(1)}$unit',
                  accentColor: accentColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DetailTile(
                  icon: Icons.water_drop_outlined,
                  label: 'Avg Humidity',
                  value: '${humidity.round()}%',
                  accentColor: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DetailTile(
                  icon: Icons.air_outlined,
                  label: 'Wind Speed',
                  value: windSpeedLabel,
                  accentColor: accentColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DetailTile(
                  icon: Icons.blur_on_outlined,
                  label: 'AQI Index',
                  value: '$aqi',
                  accentColor: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DetailTile(
                  svgAsset: 'assets/outlook_screen_assets/chancerain.svg',
                  label: 'Chance of Rain',
                  value: '$pop%',
                  accentColor: accentColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DetailTile(
                  icon: Icons.wb_cloudy_outlined,
                  label: 'Condition',
                  value: condition,
                  accentColor: accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Detail Tile ─────────────────────────────────────────────────────────────

class _DetailTile extends StatelessWidget {
  final IconData? icon;
  final String? svgAsset;
  final String label;
  final String value;
  final Color accentColor;

  const _DetailTile({
    this.icon,
    this.svgAsset,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (svgAsset != null)
            SvgPicture.asset(
              svgAsset!,
              width: 18,
              height: 18,
              colorFilter: ColorFilter.mode(accentColor, BlendMode.srcIn),
            )
          else
            Icon(icon, size: 18, color: accentColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8A8A8E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}