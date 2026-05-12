import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../config/api_key.dart';
import '../models/hourly_forecast.dart';
import '../models/weather.dart';
import 'cache_service.dart';

class WeatherService {
  static const String _weatherPath = '/data/2.5/weather';
  static const String _forecastPath = '/data/2.5/forecast';
  static const String _airQualityPath = '/data/2.5/air_pollution';

  final CacheService _cacheService;

  WeatherService(this._cacheService);

  Uri _openWeatherUri(
    String path,
    Map<String, String> queryParameters,
  ) {
    return Uri.https(
      'api.openweathermap.org',
      path,
      <String, String>{
        ...queryParameters,
        'appid': openweatherApiKey,
      },
    );
  }

  Future<int> _fetchAqi({
    required double latitude,
    required double longitude,
  }) async {
    int aqi = 0;

    try {
      final aqiUri = _openWeatherUri(
        _airQualityPath,
        {
          'lat': latitude.toString(),
          'lon': longitude.toString(),
        },
      );
      final aqiResponse = await http.get(aqiUri).timeout(
        const Duration(seconds: 10),
      );
      if (aqiResponse.statusCode == 200) {
        final data = jsonDecode(aqiResponse.body) as Map<String, dynamic>;
        aqi = data['list']?[0]?['main']?['aqi'] ?? 0;
      }
    } catch (e) {
      debugPrint('AQI fetch failed: $e');
    }

    return aqi;
  }

  Future<WeatherData> getWeatherByCity(String cityName) async {
    if (cityName.isEmpty) {
      throw Exception('City name cannot be empty');
    }

    try {
      final cached = await _cacheService.getCachedWeather(cityName);
      if (cached != null) {
        return cached;
      }
    } catch (e) {
      debugPrint('Cache error: $e');
    }

    try {
      final currentUri = _openWeatherUri(
        _weatherPath,
        {
          'q': cityName,
          'units': 'metric',
        },
      );

      late http.Response currentResponse;
      try {
        currentResponse = await http.get(currentUri).timeout(
          const Duration(seconds: 10),
        );
      } on TimeoutException {
        throw Exception('Network request timeout. Please try again.');
      } on SocketException {
        throw Exception('No internet connection. Please check your connection.');
      }

      if (currentResponse.statusCode == 404) {
        throw Exception('City "$cityName" not found. Please check the spelling.');
      } else if (currentResponse.statusCode == 429) {
        throw Exception('Too many requests. Please wait before trying again.');
      } else if (currentResponse.statusCode != 200) {
        throw Exception(
          'Failed to load weather data (Error ${currentResponse.statusCode})',
        );
      }

      final currentJson = jsonDecode(currentResponse.body) as Map<String, dynamic>;

      if (!currentJson.containsKey('coord') ||
          currentJson['coord'] == null ||
          !currentJson['coord'].containsKey('lat') ||
          !currentJson['coord'].containsKey('lon')) {
        throw Exception('Invalid weather data received');
      }

      final double lat = (currentJson['coord']['lat'] as num).toDouble();
      final double lon = (currentJson['coord']['lon'] as num).toDouble();
      currentJson['aqi'] = await _fetchAqi(latitude: lat, longitude: lon);

      final forecastUri = _openWeatherUri(
        _forecastPath,
        {
          'lat': lat.toString(),
          'lon': lon.toString(),
          'units': 'metric',
        },
      );

      late http.Response forecastResponse;
      try {
        forecastResponse = await http.get(forecastUri).timeout(
          const Duration(seconds: 10),
        );
      } on TimeoutException {
        throw Exception('Forecast request timeout. Please try again.');
      } on SocketException {
        throw Exception('No internet connection.');
      }

      if (forecastResponse.statusCode != 200) {
        throw Exception('Failed to load forecast data');
      }

      final forecastJson =
          jsonDecode(forecastResponse.body) as Map<String, dynamic>;

      if (!forecastJson.containsKey('list')) {
        throw Exception('Invalid forecast data received');
      }

      final weatherData = WeatherData(
        current: CurrentWeather.fromJson(currentJson),
        forecast: Forecast.fromJson(forecastJson),
        hourlyForecast: HourlyForecast.listFromForecastJson(
          forecastJson,
          limit: 10,
        ),
        fetchedAt: DateTime.now(),
      );

      try {
        await _cacheService.cacheWeather(weatherData, location: cityName);
        await _cacheService.saveLastLocation(cityName);
      } catch (e) {
        debugPrint('Failed to cache: $e');
      }

      return weatherData;
    } catch (e) {
      rethrow;
    }
  }

  Future<WeatherData> getWeatherByCoordinates(
    double latitude,
    double longitude,
  ) async {
    if (latitude == 0.0 && longitude == 0.0) {
      throw Exception('Invalid coordinates');
    }

    try {
      final currentUri = _openWeatherUri(
        _weatherPath,
        {
          'lat': latitude.toString(),
          'lon': longitude.toString(),
          'units': 'metric',
        },
      );

      late http.Response currentResponse;
      try {
        currentResponse = await http.get(currentUri).timeout(
          const Duration(seconds: 10),
        );
      } on TimeoutException {
        throw Exception('Location weather request timeout');
      } on SocketException {
        throw Exception('No internet connection');
      }

      if (currentResponse.statusCode != 200) {
        throw Exception('Failed to load weather data');
      }

      final currentJson = jsonDecode(currentResponse.body) as Map<String, dynamic>;

      if (!currentJson.containsKey('coord')) {
        throw Exception('Invalid location data');
      }

      currentJson['aqi'] = await _fetchAqi(
        latitude: latitude,
        longitude: longitude,
      );

      final forecastUri = _openWeatherUri(
        _forecastPath,
        {
          'lat': latitude.toString(),
          'lon': longitude.toString(),
          'units': 'metric',
        },
      );

      late http.Response forecastResponse;
      try {
        forecastResponse = await http.get(forecastUri).timeout(
          const Duration(seconds: 10),
        );
      } on TimeoutException {
        throw Exception('Forecast request timeout');
      } on SocketException {
        throw Exception('No internet connection');
      }

      if (forecastResponse.statusCode != 200) {
        throw Exception('Failed to load forecast data');
      }

      final forecastJson =
          jsonDecode(forecastResponse.body) as Map<String, dynamic>;

      final weatherData = WeatherData(
        current: CurrentWeather.fromJson(currentJson),
        forecast: Forecast.fromJson(forecastJson),
        hourlyForecast: HourlyForecast.listFromForecastJson(
          forecastJson,
          limit: 10,
        ),
        fetchedAt: DateTime.now(),
      );

      try {
        await _cacheService.cacheWeather(weatherData);
      } catch (e) {
        debugPrint('Cache error: $e');
      }

      return weatherData;
    } catch (e) {
      rethrow;
    }
  }

  Future<WeatherData> getCurrentLocationWeather() async {
    try {
      LocationPermission permission;
      try {
        permission = await Geolocator.checkPermission();
      } catch (e) {
        debugPrint('Permission check failed: $e');
        return await getWeatherByCity('London');
      }

      if (permission == LocationPermission.denied) {
        try {
          permission = await Geolocator.requestPermission();
        } catch (e) {
          debugPrint('Permission request failed: $e');
          return await getWeatherByCity('London');
        }

        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          debugPrint('Location permission denied');
          return await getWeatherByCity('London');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permanently denied');
        return await getWeatherByCity('London');
      }

      late Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 15),
          ),
        ).timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            debugPrint('Location timeout');
            throw TimeoutException('Location request timeout', Duration.zero);
          },
        );
      } on TimeoutException {
        debugPrint('Location timeout, using fallback');
        final lastLocation = _cacheService.getLastLocation();
        if (lastLocation != null && lastLocation.isNotEmpty) {
          return await getWeatherByCity(lastLocation);
        }
        return await getWeatherByCity('London');
      } catch (e) {
        debugPrint('Location error: $e');
        return await getWeatherByCity('London');
      }

      try {
        return await getWeatherByCoordinates(position.latitude, position.longitude);
      } catch (e) {
        debugPrint('Failed to get weather by coordinates: $e');
        return await getWeatherByCity('London');
      }
    } catch (e) {
      debugPrint('Unexpected error in getCurrentLocationWeather: $e');
      try {
        return await getWeatherByCity('London');
      } catch (_) {
        rethrow;
      }
    }
  }

  bool isRefreshOnCooldown() {
    return _cacheService.isRefreshOnCooldown();
  }
}
