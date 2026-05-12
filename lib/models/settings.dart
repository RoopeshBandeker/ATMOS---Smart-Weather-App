enum TemperatureUnit { celsius, fahrenheit }

enum WindSpeedUnit { ms, kmh, mph, knots }

enum PressureUnit { hpa, mbar, mmhg, inhg }

enum TimeFormatUnit { twelveHour, twentyFourHour }

T _parseEnumValue<T>(
  List<T> values,
  Object? rawValue,
  T fallback,
) {
  if (rawValue == null) {
    return fallback;
  }

  final rawString = rawValue.toString();
  for (final value in values) {
    if (value.toString() == rawString) {
      return value;
    }
  }

  return fallback;
}

class AppSettings {
  TemperatureUnit temperatureUnit;
  WindSpeedUnit windSpeedUnit;
  PressureUnit pressureUnit;
  TimeFormatUnit? timeFormat;

  AppSettings({
    this.temperatureUnit = TemperatureUnit.celsius,
    this.windSpeedUnit = WindSpeedUnit.ms,
    this.pressureUnit = PressureUnit.hpa,
    this.timeFormat = TimeFormatUnit.twelveHour,
  });

  TimeFormatUnit get resolvedTimeFormat =>
      timeFormat ?? TimeFormatUnit.twelveHour;

  Map<String, String> toJson() => {
    'temperatureUnit': temperatureUnit.toString(),
    'windSpeedUnit': windSpeedUnit.toString(),
    'pressureUnit': pressureUnit.toString(),
    'timeFormat': resolvedTimeFormat.toString(),
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      temperatureUnit: _parseEnumValue(
        TemperatureUnit.values,
        json['temperatureUnit'],
        TemperatureUnit.celsius,
      ),
      windSpeedUnit: _parseEnumValue(
        WindSpeedUnit.values,
        json['windSpeedUnit'],
        WindSpeedUnit.ms,
      ),
      pressureUnit: _parseEnumValue(
        PressureUnit.values,
        json['pressureUnit'],
        PressureUnit.hpa,
      ),
      timeFormat: _parseEnumValue(
        TimeFormatUnit.values,
        json['timeFormat'],
        TimeFormatUnit.twelveHour,
      ),
    );
  }
}
