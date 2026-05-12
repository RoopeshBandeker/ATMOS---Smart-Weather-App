import 'hourly_forecast.dart';

DateTime _locationDateTimeFromUnixSeconds(
  int unixSeconds,
  int timezoneOffsetSeconds,
) {
  return DateTime.fromMillisecondsSinceEpoch(
    (unixSeconds + timezoneOffsetSeconds) * 1000,
    isUtc: true,
  );
}

int _unixSecondsFromLocationDateTime(
  DateTime dateTime,
  int timezoneOffsetSeconds,
) {
  return dateTime
          .subtract(Duration(seconds: timezoneOffsetSeconds))
          .millisecondsSinceEpoch ~/
      1000;
}

class CurrentWeather {
  final String locationName;
  final double latitude;
  final double longitude;
  final DateTime dateTime;
  final int timezoneOffsetSeconds;
  final double temperature;
  final double feelsLike;
  final String condition;
  final String icon;
  final int humidity;
  final int pressure;
  final double windSpeed;
  final int windDegree;
  final int cloudiness;
  final DateTime sunrise;
  final DateTime sunset;
  final int aqi;
  final int visibility;

  CurrentWeather({
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.dateTime,
    required this.timezoneOffsetSeconds,
    required this.temperature,
    required this.feelsLike,
    required this.condition,
    required this.icon,
    required this.humidity,
    required this.pressure,
    required this.windSpeed,
    required this.windDegree,
    required this.cloudiness,
    required this.sunrise,
    required this.sunset,
    required this.aqi,
    required this.visibility,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    final timezoneOffsetSeconds = ((json['timezone'] ?? 0) as num).toInt();
    return CurrentWeather(
      locationName: json['name'] ?? 'Unknown',
      latitude: (json['coord']?['lat'] ?? 0).toDouble(),
      longitude: (json['coord']?['lon'] ?? 0).toDouble(),
      dateTime: _locationDateTimeFromUnixSeconds(
        (json['dt'] ?? 0) as int,
        timezoneOffsetSeconds,
      ),
      timezoneOffsetSeconds: timezoneOffsetSeconds,
      temperature: (json['main']?['temp'] ?? 0).toDouble(),
      feelsLike: (json['main']?['feels_like'] ?? 0).toDouble(),
      condition: json['weather']?[0]?['main'] ?? 'Unknown',
      icon: json['weather']?[0]?['icon'] ?? '01d',
      humidity: json['main']?['humidity'] ?? 0,
      pressure: json['main']?['pressure'] ?? 0,
      windSpeed: (json['wind']?['speed'] ?? 0).toDouble(),
      windDegree: json['wind']?['deg'] ?? 0,
      cloudiness: json['clouds']?['all'] ?? 0,
      sunrise: _locationDateTimeFromUnixSeconds(
        (json['sys']?['sunrise'] ?? 0) as int,
        timezoneOffsetSeconds,
      ),
      sunset: _locationDateTimeFromUnixSeconds(
        (json['sys']?['sunset'] ?? 0) as int,
        timezoneOffsetSeconds,
      ),
      aqi: json['aqi'] ?? 0,
      visibility: json['visibility'] ?? 10000,
    );
  }
}

class ForecastItem {
  final DateTime dateTime;
  final double temperature;
  final double tempMin;
  final double tempMax;
  final double pop;
  final String condition;
  final String icon;
  final int humidity;
  final double windSpeed;
  final int pressure;

  ForecastItem({
    required this.dateTime,
    required this.temperature,
    required this.tempMin,
    required this.tempMax,
    required this.pop,
    required this.condition,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
  });

  factory ForecastItem.fromJson(Map<String, dynamic> json) {
    final timezoneOffsetSeconds = ((json['timezone'] ?? 0) as num).toInt();
    return ForecastItem(
      dateTime: _locationDateTimeFromUnixSeconds(
        (json['dt'] ?? 0) as int,
        timezoneOffsetSeconds,
      ),
      temperature: (json['main']?['temp'] ?? 0).toDouble(),
      tempMin: (json['main']?['temp_min'] ?? 0).toDouble(),
      tempMax: (json['main']?['temp_max'] ?? 0).toDouble(),
      pop: (json['pop'] ?? 0).toDouble(),
      condition: json['weather']?[0]?['main'] ?? 'Unknown',
      icon: json['weather']?[0]?['icon'] ?? '01d',
      humidity: json['main']?['humidity'] ?? 0,
      windSpeed: (json['wind']?['speed'] ?? 0).toDouble(),
      pressure: json['main']?['pressure'] ?? 0,
    );
  }
}

class Forecast {
  final List<ForecastItem> items;

  Forecast({required this.items});

  factory Forecast.fromJson(Map<String, dynamic> json) {
    final timezoneOffsetSeconds =
        ((json['city']?['timezone'] ?? json['timezone'] ?? 0) as num).toInt();
    final list =
        (json['list'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(
              (item) => ForecastItem.fromJson({
                ...item,
                'timezone': timezoneOffsetSeconds,
              }),
            )
            .toList() ??
        [];
    return Forecast(items: list);
  }
}

class WeatherData {
  final CurrentWeather current;
  final Forecast forecast;
  final List<HourlyForecast> hourlyForecast;
  final DateTime fetchedAt;

  WeatherData({
    required this.current,
    required this.forecast,
    required this.hourlyForecast,
    required this.fetchedAt,
  });

  bool isCacheValid(int cacheDurationMinutes) {
    return DateTime.now().difference(fetchedAt).inMinutes <
        cacheDurationMinutes;
  }

  Map<String, dynamic> toJson() => {
    'current': {
      'name': current.locationName,
      'dt': _unixSecondsFromLocationDateTime(
        current.dateTime,
        current.timezoneOffsetSeconds,
      ),
      'timezone': current.timezoneOffsetSeconds,
      'coord': {'lat': current.latitude, 'lon': current.longitude},
      'main': {
        'temp': current.temperature,
        'feels_like': current.feelsLike,
        'humidity': current.humidity,
        'pressure': current.pressure,
      },
      'weather': [
        {'main': current.condition, 'icon': current.icon},
      ],
      'wind': {'speed': current.windSpeed, 'deg': current.windDegree},
      'clouds': {'all': current.cloudiness},
      'sys': {
        'sunrise': _unixSecondsFromLocationDateTime(
          current.sunrise,
          current.timezoneOffsetSeconds,
        ),
        'sunset': _unixSecondsFromLocationDateTime(
          current.sunset,
          current.timezoneOffsetSeconds,
        ),
      },
      'visibility': current.visibility,
      'aqi': current.aqi,
    },
    'list': forecast.items
        .map(
          (item) => {
            'dt': _unixSecondsFromLocationDateTime(
              item.dateTime,
              current.timezoneOffsetSeconds,
            ),
            'main': {
              'temp': item.temperature,
              'temp_min': item.tempMin,
              'temp_max': item.tempMax,
              'humidity': item.humidity,
              'pressure': item.pressure,
            },
            'pop': item.pop,
            'weather': [
              {'main': item.condition, 'icon': item.icon},
            ],
            'wind': {'speed': item.windSpeed},
          },
        )
        .toList(),
    'city': {'timezone': current.timezoneOffsetSeconds},
    'hourlyForecast': hourlyForecast
        .map(
          (item) => {
            'dt': _unixSecondsFromLocationDateTime(
              item.dateTime,
              current.timezoneOffsetSeconds,
            ),
            'main': {'temp': item.temperature},
            'weather': [
              {'icon': item.icon, 'main': item.condition},
            ],
          },
        )
        .toList(),
    'fetchedAt': fetchedAt.toIso8601String(),
  };

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final forecast = Forecast.fromJson(json);
    final hourlyForecastJson = json['hourlyForecast'];
    final timezoneOffsetSeconds =
        ((json['city']?['timezone'] ?? json['current']?['timezone'] ?? 0)
                as num)
            .toInt();

    return WeatherData(
      current: CurrentWeather.fromJson(json['current'] ?? {}),
      forecast: forecast,
      hourlyForecast: hourlyForecastJson is List
          ? hourlyForecastJson
                .whereType<Map<String, dynamic>>()
                .map(
                  (item) => HourlyForecast.fromJson({
                    ...item,
                    'timezone': timezoneOffsetSeconds,
                  }),
                )
                .toList()
          : HourlyForecast.listFromForecastJson(json, limit: 10),
      fetchedAt: DateTime.parse(
        json['fetchedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
