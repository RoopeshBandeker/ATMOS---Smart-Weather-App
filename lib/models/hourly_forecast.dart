class HourlyForecast {
  final DateTime dateTime;
  final double temperature;
  final String icon;
  final String condition;

  const HourlyForecast({
    required this.dateTime,
    required this.temperature,
    required this.icon,
    required this.condition,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    final timezoneOffsetSeconds = (json['timezone'] ?? 0) as int;
    return HourlyForecast(
      dateTime: DateTime.fromMillisecondsSinceEpoch(
        (((json['dt'] ?? 0) as int) + timezoneOffsetSeconds) * 1000,
        isUtc: true,
      ),
      temperature: (json['main']?['temp'] ?? 0).toDouble(),
      icon: json['weather']?[0]?['icon'] ?? '01d',
      condition: json['weather']?[0]?['main'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toJson() => {
    'dt': dateTime.millisecondsSinceEpoch ~/ 1000,
    'main': {'temp': temperature},
    'weather': [
      {'icon': icon, 'main': condition},
    ],
  };

  static List<HourlyForecast> listFromForecastJson(
    Map<String, dynamic> json, {
    int limit = 10,
  }) {
    final list = (json['list'] as List?) ?? [];
    final timezoneOffsetSeconds =
        (json['city']?['timezone'] ?? json['timezone'] ?? 0) as int;
    return list
        .take(limit)
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => HourlyForecast.fromJson({
            ...item,
            'timezone': timezoneOffsetSeconds,
          }),
        )
        .toList();
  }
}
