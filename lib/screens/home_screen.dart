import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';

import '../models/air_quality.dart';
import '../models/location_search_result.dart';
import '../models/settings.dart';
import '../models/weather.dart';
import '../models/uv.dart';
import '../providers/map_location_notifier.dart';
import '../services/air_quality_service.dart';
import '../services/cache_service.dart';
import '../services/uv_service.dart';
import '../services/weather_service.dart';
import '../utils/weather_icons.dart' as weather_icons;
import '../utils/converters.dart';
import '../widgets/map_preview_widget_interactive.dart';
import '../widgets/hourly_forecast_widget.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  final WeatherService weatherService;
  final VoidCallback onSettingsPressed;
  final AppSettings settings;
  final CacheService cacheService;
  final ValueNotifier<WeatherData?> weatherNotifier;
  final ValueNotifier<AirQualityIndex?> aqiNotifier;
  final ValueNotifier<UvIndex?> uvNotifier;
  final bool enableAutoLoad;

  const HomeScreen({
    required this.weatherService,
    required this.onSettingsPressed,
    required this.settings,
    required this.cacheService,
    required this.weatherNotifier,
    required this.aqiNotifier,
    required this.uvNotifier,
    this.enableAutoLoad = true,
    super.key,
  });

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  WeatherData? _weather;
  bool _isLoading = true;
  String? _error;
  late MapLocationNotifier _mapLocationNotifier;
  late AirQualityService _airQualityService;
  late UvService _uvService;

  @override
  void initState() {
    super.initState();
    _mapLocationNotifier = MapLocationNotifier(const LatLng(0, 0));
    _airQualityService = AirQualityService();
    _uvService = UvService();
    if (widget.enableAutoLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadWeather();
        }
      });
    } else {
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    _mapLocationNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadWeather() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final lastCity = widget.cacheService.getLastLocation();
      final weather = (lastCity != null && lastCity.isNotEmpty)
          ? await widget.weatherService.getWeatherByCity(lastCity)
          : await widget.weatherService.getCurrentLocationWeather();

      if (!mounted) return;
      setState(() {
        _weather = weather;
        _isLoading = false;
        _error = null;
      });
      widget.weatherNotifier.value = weather;

      _mapLocationNotifier.updateLocation(
        weather.current.latitude,
        weather.current.longitude,
      );

      _loadAqiForLocation(weather.current.latitude, weather.current.longitude);
      _loadUvForLocation(weather.current.latitude, weather.current.longitude);
    } catch (e) {
      if (!mounted) return;
      final errorMessage = _getErrorMessage(e.toString());
      setState(() {
        _error = errorMessage;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(label: 'Retry', onPressed: _loadWeather),
        ),
      );
    }
  }

  Future<void> searchLocation(LocationSearchResult location) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

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
        _error = null;
      });
      widget.weatherNotifier.value = weather;

      _mapLocationNotifier.updateLocation(
        weather.current.latitude,
        weather.current.longitude,
      );

      _loadAqiForLocation(weather.current.latitude, weather.current.longitude);
      _loadUvForLocation(weather.current.latitude, weather.current.longitude);
    } catch (e) {
      if (!mounted) return;
      final errorMessage = _getErrorMessage(e.toString());
      setState(() {
        _error = errorMessage;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _loadAqiForLocation(double lat, double lon) async {
    try {
      final aqi = await _airQualityService.getAirQuality(
        latitude: lat,
        longitude: lon,
      );
      if (!mounted) return;
      widget.aqiNotifier.value = aqi;
    } catch (e) {
      if (!mounted) return;
      widget.aqiNotifier.value = null;
    }
  }

  Future<void> _loadUvForLocation(double lat, double lon) async {
    try {
      final uv = await _uvService.getDailyUvIndex(
        latitude: lat,
        longitude: lon,
      );
      if (!mounted) return;
      widget.uvNotifier.value = uv;
    } catch (e) {
      if (!mounted) return;
      widget.uvNotifier.value = null;
    }
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    if (widget.weatherService.isRefreshOnCooldown()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait 30 seconds before refreshing again'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    await _loadWeather();
  }

  String _getErrorMessage(String error) {
    final normalizedError = error.toLowerCase();

    if (normalizedError.contains('location')) {
      return 'Unable to access your location. Please enable location permissions in settings.';
    } else if (normalizedError.contains('internet') ||
        normalizedError.contains('connection')) {
      return 'No internet connection. Please check your network.';
    } else if (normalizedError.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (normalizedError.contains('not found')) {
      return 'City not found. Please check the spelling.';
    } else if (normalizedError.contains('429') ||
        normalizedError.contains('too many')) {
      return 'Too many requests. Please wait a moment.';
    } else {
      return 'Unable to load weather. Please try again later.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.black87,
        title: null,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: const [],
      ),
      body: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top * 0.9,
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.black87),
              )
            : _error != null
                ? _buildErrorWidget()
                : _buildScrollableContent(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Weather-style icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15),
              ),
              child: const Icon(
                Icons.location_off_rounded,
                size: 50,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            // Title
            const Text(
              'Unable to find your location',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 10),

            // Subtitle
            Text(
              _error ?? 'Please enable location services or try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),

            const SizedBox(height: 28),

            // Retry button
            GestureDetector(
              onTap: _loadWeather,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.white,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, color: Colors.black, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Try Again',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollableContent() {
    if (_weather == null) return const SizedBox();

    final highLow = getTodayHighLowTemps();
    final tempUnit = widget.settings.temperatureUnit == TemperatureUnit.celsius
        ? '°C'
        : '°F';
    final currentTemp =
        widget.settings.temperatureUnit == TemperatureUnit.celsius
        ? _weather!.current.temperature
        : UnitConversionUtils.celsiusToFahrenheit(
            _weather!.current.temperature,
          );
    final rawHigh = highLow?['high'] ?? _weather!.current.temperature;
    final rawLow = highLow?['low'] ?? _weather!.current.temperature;
    final highTemp = widget.settings.temperatureUnit == TemperatureUnit.celsius
        ? rawHigh
        : UnitConversionUtils.celsiusToFahrenheit(rawHigh);
    final lowTemp = widget.settings.temperatureUnit == TemperatureUnit.celsius
        ? rawLow
        : UnitConversionUtils.celsiusToFahrenheit(rawLow);

    return RefreshIndicator(
      onRefresh: _refresh,
      color: Colors.black87,
      backgroundColor: Colors.white,
      child: ScrollConfiguration(
        behavior: const _NoOverscrollScrollBehavior(),
        child: ListView(
          physics: const _RefreshOnlyScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
          ),
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  _buildMapCard(),
                  const SizedBox(height: 30),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${highTemp.round()}$tempUnit',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      SvgPicture.asset(
                        'assets/home_screen_assets/arrow_up.svg',
                        width: 15,
                        height: 42,
                        colorFilter: const ColorFilter.mode(
                          Colors.black87,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Color.fromARGB(255, 242, 46, 32),
                            size: 22,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _weather!.current.locationName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${currentTemp.round()}',
                              style: const TextStyle(
                                fontSize: 120,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                                height: 1.0,
                              ),
                            ),
                            TextSpan(
                              text: tempUnit,
                              style: const TextStyle(
                                fontSize: 70,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          weather_icons.weatherIconWidget(
                            _weather!.current.condition,
                            _weather!.current.icon,
                            width: 32,
                            height: 32,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _weather!.current.condition,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      SvgPicture.asset(
                        'assets/home_screen_assets/arrow_down.svg',
                        width: 15,
                        height: 42,
                        colorFilter: const ColorFilter.mode(
                          Colors.black87,
                          BlendMode.srcIn,
                        ),
                      ),
                      Text(
                        '${lowTemp.round()}$tempUnit',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  HourlyForecastWidget(
                    hourlyForecast: _weather!.hourlyForecast,
                    settings: widget.settings,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapCard() {
    return SizedBox(
      width: 365,
      height: 200,
      child: MapPreviewWidget(
        locationNotifier: _mapLocationNotifier,
        settings: widget.settings,
        locationName: _weather?.current.locationName,
        timezoneOffsetSeconds: _weather?.current.timezoneOffsetSeconds,
        height: 200,
        initialZoom: 13,
        onMapTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MapScreen(
                settings: widget.settings,
                initialCenter: _mapLocationNotifier.value,
              ),
            ),
          );
        },
      ),
    );
  }

  Map<String, double>? getTodayHighLowTemps() {
    if (_weather == null || _weather!.forecast.items.isEmpty) {
      return null;
    }

    final weather = _weather!;
    final now = weather.current.dateTime;
    var relevantItems = weather.forecast.items.where((item) {
      return item.dateTime.year == now.year &&
          item.dateTime.month == now.month &&
          item.dateTime.day == now.day;
    }).toList();

    // Late in the day the 3-hour forecast can contain only one remaining slot
    // for "today", which makes the displayed high/low look incorrect. In that
    // case, fall back to the next 24 hours from the current location time.
    if (relevantItems.length < 2) {
      final cutoff = now.add(const Duration(hours: 24));
      relevantItems = weather.forecast.items.where((item) {
        return !item.dateTime.isBefore(now) && !item.dateTime.isAfter(cutoff);
      }).toList();
    }

    if (relevantItems.isEmpty) {
      return {
        'high': weather.current.temperature,
        'low': weather.current.temperature,
      };
    }

    final highCandidates = <double>[
      weather.current.temperature,
      ...relevantItems.map((item) => item.tempMax),
    ];
    final lowCandidates = <double>[
      weather.current.temperature,
      ...relevantItems.map((item) => item.tempMin),
    ];

    final high = highCandidates.reduce(
      (value, element) => value > element ? value : element,
    );
    final low = lowCandidates.reduce(
      (value, element) => value < element ? value : element,
    );

    return {'high': high, 'low': low};
  }
}

class _RefreshOnlyScrollPhysics extends ScrollPhysics {
  const _RefreshOnlyScrollPhysics({super.parent});

  @override
  _RefreshOnlyScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _RefreshOnlyScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    if (value != position.pixels) {
      return value - position.pixels;
    }

    return super.applyBoundaryConditions(position, value);
  }
}

class _NoOverscrollScrollBehavior extends ScrollBehavior {
  const _NoOverscrollScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
