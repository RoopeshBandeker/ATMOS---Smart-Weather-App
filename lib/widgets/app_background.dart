import 'dart:async';

import 'package:flutter/material.dart';

import '../models/weather.dart';
import '../utils/time_of_day_theme.dart';

class AppBackground extends StatefulWidget {
  final Widget child;
  final WeatherData? weather;

  const AppBackground({
    required this.child,
    required this.weather,
    super.key,
  });

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground> {
  late DateTime _currentDateTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentDateTime = _getDisplayDateTime();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() {
        _currentDateTime = _getDisplayDateTime();
      });
    });
  }

  @override
  void didUpdateWidget(covariant AppBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weather?.current.timezoneOffsetSeconds !=
            widget.weather?.current.timezoneOffsetSeconds ||
        oldWidget.weather?.current.locationName !=
            widget.weather?.current.locationName) {
      setState(() {
        _currentDateTime = _getDisplayDateTime();
      });
    }
  }

  DateTime _getDisplayDateTime() {
    final timezoneOffsetSeconds = widget.weather?.current.timezoneOffsetSeconds;

    if (timezoneOffsetSeconds == null) {
      return DateTime.now();
    }

    return DateTime.now().toUtc().add(Duration(seconds: timezoneOffsetSeconds));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.weather != null
        ? getAtmosSkyGradient(_currentDateTime)
        : [
            const Color(0xFF6EC6FF),
            const Color(0xFFFFFFFF),
          ];
    final stops = colors.length == 4
        ? const [0.0, 0.2, 0.4, 0.7]
        : const [0.0, 1.0];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      constraints: const BoxConstraints.expand(),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: colors,
          stops: stops,
        ),
      ),
      child: widget.child,
    );
  }
}
