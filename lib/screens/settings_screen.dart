import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/settings.dart';
import '../models/weather.dart';
import '../services/settings_service.dart';
import '../utils/time_of_day_theme.dart';

class SettingsScreen extends StatefulWidget {
  final AppSettings initialSettings;
  final ValueChanged<AppSettings> onSettingsChanged;
  final SettingsService settingsService;
  final ValueListenable<WeatherData?>? weatherNotifier;
  final bool showDoneButton;

  const SettingsScreen({
    required this.initialSettings,
    required this.onSettingsChanged,
    required this.settingsService,
    this.weatherNotifier,
    this.showDoneButton = true,
    super.key,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _settings;
  late DateTime _currentDateTime;
  Timer? _timer;

  // Time format: 0 = 12 Hour, 1 = 24 Hour
  int _timeFormatIndex = 0;

  @override
  void initState() {
    super.initState();
    _settings = _copySettings(widget.initialSettings);
    _timeFormatIndex =
        _settings.resolvedTimeFormat == TimeFormatUnit.twentyFourHour ? 1 : 0;
    _currentDateTime = _getDisplayDateTime();
    widget.weatherNotifier?.addListener(_handleWeatherChanged);
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() {
        _currentDateTime = _getDisplayDateTime();
      });
    });
  }

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weatherNotifier != widget.weatherNotifier) {
      oldWidget.weatherNotifier?.removeListener(_handleWeatherChanged);
      widget.weatherNotifier?.addListener(_handleWeatherChanged);
      _currentDateTime = _getDisplayDateTime();
    }
    final oldS = oldWidget.initialSettings;
    final newS = widget.initialSettings;
    if (oldS.temperatureUnit != newS.temperatureUnit ||
        oldS.windSpeedUnit != newS.windSpeedUnit ||
        oldS.pressureUnit != newS.pressureUnit ||
        oldS.resolvedTimeFormat != newS.resolvedTimeFormat) {
      setState(() {
        _settings = _copySettings(newS);
        _timeFormatIndex =
            _settings.resolvedTimeFormat == TimeFormatUnit.twentyFourHour
            ? 1
            : 0;
      });
    }
  }

  @override
  void dispose() {
    widget.weatherNotifier?.removeListener(_handleWeatherChanged);
    _timer?.cancel();
    super.dispose();
  }

  AppSettings _copySettings(AppSettings s) {
    return AppSettings(
      temperatureUnit: s.temperatureUnit,
      windSpeedUnit: s.windSpeedUnit,
      pressureUnit: s.pressureUnit,
      timeFormat: s.resolvedTimeFormat,
    );
  }

  Future<void> _updateSettings() async {
    await widget.settingsService.saveSettings(_settings);
    widget.onSettingsChanged(_settings);
  }

  void _handleWeatherChanged() {
    if (!mounted) return;
    setState(() {
      _currentDateTime = _getDisplayDateTime();
    });
  }

  DateTime _getDisplayDateTime() {
    final timezoneOffsetSeconds =
        widget.weatherNotifier?.value?.current.timezoneOffsetSeconds;
    if (timezoneOffsetSeconds == null) {
      return DateTime.now();
    }
    return DateTime.now().toUtc().add(Duration(seconds: timezoneOffsetSeconds));
  }

  @override
  Widget build(BuildContext context) {
    final pageTheme = getSettingsPageTheme(_currentDateTime);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          16,
          42,
          16,
          MediaQuery.of(context).padding.bottom + 120,
        ),
        children: [
          // ── Time Unit (2 wide buttons) ─────────────────────
          _SettingsCard(
            iconAsset: 'assets/settings_screen_assets/time_icon.svg',
            theme: pageTheme,
            title: 'Time Unit',
            child: _WideButtons(
              theme: pageTheme,
              options: const ['12 Hour', '24 Hour'],
              selectedIndex: _timeFormatIndex,
              onSelected: (i) async {
                setState(() {
                  _timeFormatIndex = i;
                  _settings.timeFormat = i == 0
                      ? TimeFormatUnit.twelveHour
                      : TimeFormatUnit.twentyFourHour;
                });
                await _updateSettings();
              },
            ),
          ),

          const SizedBox(height: 16),

          // ── Temperature Unit (2 wide buttons) ─────────────
          _SettingsCard(
            iconAsset: 'assets/settings_screen_assets/temperature_icon.svg',
            theme: pageTheme,
            title: 'Temperature Unit',
            child: _WideButtons(
              options: const ['Fahrenheit  °F', 'Celsius  °C'],
              theme: pageTheme,
              selectedIndex:
                  _settings.temperatureUnit == TemperatureUnit.fahrenheit
                  ? 0
                  : 1,
              onSelected: (i) async {
                setState(() {
                  _settings.temperatureUnit = i == 0
                      ? TemperatureUnit.fahrenheit
                      : TemperatureUnit.celsius;
                });
                await _updateSettings();
              },
            ),
          ),

          const SizedBox(height: 16),

          // ── Wind Speed Unit (4 small buttons) ─────────────
          _SettingsCard(
            iconAsset: 'assets/settings_screen_assets/wind_speed_icon.svg',
            theme: pageTheme,
            title: 'Wind Speed Unit',
            child: _SmallButtons(
              theme: pageTheme,
              options: const ['m/s', 'km/h', 'mph', 'knots'],
              selectedIndex: WindSpeedUnit.values.indexOf(
                _settings.windSpeedUnit,
              ),
              onSelected: (i) async {
                setState(() {
                  _settings.windSpeedUnit = WindSpeedUnit.values[i];
                });
                await _updateSettings();
              },
            ),
          ),

          const SizedBox(height: 16),

          // ── Pressure Unit (4 small buttons) ───────────────
          _SettingsCard(
            iconAsset: 'assets/settings_screen_assets/pressure_icon.svg',
            theme: pageTheme,
            title: 'Pressure Unit',
            child: _SmallButtons(
              theme: pageTheme,
              options: const ['hpa', 'mbar', 'mmHg', 'inHg'],
              selectedIndex: PressureUnit.values.indexOf(
                _settings.pressureUnit,
              ),
              onSelected: (i) async {
                setState(() {
                  _settings.pressureUnit = PressureUnit.values[i];
                });
                await _updateSettings();
              },
            ),
          ),

          if (widget.showDoneButton) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(_settings),
                icon: const Icon(Icons.check),
                label: const Text('Done'),
                style: FilledButton.styleFrom(
                  backgroundColor: pageTheme.selectedButton,
                  foregroundColor: pageTheme.selectedButtonText,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CARD SHELL
//  bg: #EEFCFF · radius 15 · shadow 0px 2px 5px rgba(0,0,0,0.25)
// ─────────────────────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final String iconAsset;
  final SettingsPageTheme theme;
  final String title;
  final Widget child;

  const _SettingsCard({
    required this.iconAsset,
    required this.theme,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                iconAsset,
                width: 18,
                height: 18,
                colorFilter: const ColorFilter.mode(
                  Colors.black,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: theme.titleText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  WIDE BUTTONS — 2-option cards (Time, Temperature)
//  Each fills half the row · height 48 · radius 10 · fontSize 15
// ─────────────────────────────────────────────────────────────
class _WideButtons extends StatelessWidget {
  final SettingsPageTheme theme;
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _WideButtons({
    required this.theme,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(options.length, (index) {
        final isSelected = index == selectedIndex;
        final isLast = index == options.length - 1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 9),
            child: GestureDetector(
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeInOut,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.selectedButton
                      : theme.unselectedButtonBackground,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      options[index],
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? theme.selectedButtonText
                            : theme.unselectedButtonText,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SMALL BUTTONS — 4-option cards (Wind, Pressure)
//  width 68 · height 48 · radius 10 · spacing 9px · fontSize 15
//  Wrap (left-aligned) matches Figma positions 31→108→185→262
// ─────────────────────────────────────────────────────────────
class _SmallButtons extends StatelessWidget {
  final SettingsPageTheme theme;
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _SmallButtons({
    required this.theme,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const spacing = 9.0;

    return Row(
      children: List.generate(options.length, (index) {
        final isSelected = index == selectedIndex;
        final isLast = index == options.length - 1;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : spacing),
            child: GestureDetector(
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeInOut,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.selectedButton
                      : theme.unselectedButtonBackground,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      options[index],
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? theme.selectedButtonText
                            : theme.unselectedButtonText,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
