class DailyScore {
  final DateTime date;
  final int score;
  final double averageTemperature;
  final double minTemperature;
  final double maxTemperature;
  final int averageHumidity;
  final double averageWindSpeed;
  final int aqi;
  final String condition;
  final String icon;

  const DailyScore({
    required this.date,
    required this.score,
    required this.averageTemperature,
    required this.minTemperature,
    required this.maxTemperature,
    required this.averageHumidity,
    required this.averageWindSpeed,
    required this.aqi,
    required this.condition,
    required this.icon,
  });
}
