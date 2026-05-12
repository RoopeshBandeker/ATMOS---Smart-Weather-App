import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

String getWeatherAsset(String condition, String iconCode) {
  final c = condition.toLowerCase();

  if (c.contains('clear')) return 'assets/weather_assets/sunny_icon.svg';
  if (c.contains('partly') || c.contains('few')) return 'assets/weather_assets/partly_cloudy_icon.svg';
  if (c.contains('cloud')) return 'assets/weather_assets/cloudy_icon.svg';
  if (c.contains('light rain') || c.contains('drizzle')) return 'assets/weather_assets/light_rain_icon.svg';
  if (c.contains('moderate rain') || c.contains('rain')) return 'assets/weather_assets/moderate_rain_icon.svg';
  if (c.contains('heavy') || c.contains('shower')) return 'assets/weather_assets/heavy_rain_icon.svg';
  if (c.contains('thunder') || c.contains('storm')) return 'assets/weather_assets/thundestrom_icon.svg';
  if (c.contains('snow')) return 'assets/weather_assets/snow_icon.svg';
  if (c.contains('mist') || c.contains('haze') || c.contains('fog')) return 'assets/weather_assets/haze_icon.svg';
  if (c.contains('wind')) return 'assets/weather_assets/wind_icon.svg';

  return 'assets/weather_assets/sunny_icon.svg'; // fallback
}

Widget weatherIconWidget(String condition, String iconCode, {double? width, double? height, BoxFit fit = BoxFit.contain}) {
  final asset = getWeatherAsset(condition, iconCode);

  if (asset.toLowerCase().endsWith('.svg')) {
    return SvgPicture.asset(
      asset,
      width: width,
      height: height,
      fit: fit,
      placeholderBuilder: (context) => SizedBox(width: width ?? 24, height: height ?? 24),
    );
  }

  return Image.asset(
    asset,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (context, error, stackTrace) => SizedBox(width: width ?? 24, height: height ?? 24),
  );
}

class WeatherIconUtils {
  static IconData getWeatherIcon(String condition, String iconCode) {
    final isNight = iconCode.endsWith('n');

    switch (condition.toLowerCase()) {
      case 'clear':
        return isNight ? Icons.nights_stay : Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
      case 'drizzle':
        return Icons.cloud_queue;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'snow':
        return Icons.ac_unit;
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
      case 'sand':
      case 'ash':
      case 'squall':
      case 'tornado':
        return Icons.cloud_circle;
      default:
        return Icons.wb_sunny;
    }
  }

  static Color getWeatherColor(String condition, String iconCode) {
    final isNight = iconCode.endsWith('n');

    switch (condition.toLowerCase()) {
      case 'clear':
        return isNight ? const Color(0xFF0F3460) : const Color(0xFF87CEEB);
      case 'clouds':
        return const Color(0xFF5A7A8F);
      case 'rain':
      case 'drizzle':
        return const Color(0xFF38495F);
      case 'thunderstorm':
        return const Color(0xFF1A1A2E);
      case 'snow':
        return const Color(0xFFB0D4F1);
      case 'mist':
      case 'fog':
        return const Color(0xFF7A8A99);
      default:
        return const Color(0xFF0099F7);
    }
  }

  static bool isNight(String iconCode) => iconCode.endsWith('n');
}
