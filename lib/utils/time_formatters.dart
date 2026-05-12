import 'package:intl/intl.dart';

import '../models/settings.dart';

String formatTimeWithSettings(
  DateTime dateTime,
  AppSettings settings, {
  required String twelveHourPattern,
  required String twentyFourHourPattern,
  bool lowercase = false,
}) {
  final pattern = settings.resolvedTimeFormat == TimeFormatUnit.twentyFourHour
      ? twentyFourHourPattern
      : twelveHourPattern;
  final formatted = DateFormat(pattern).format(dateTime);
  return lowercase ? formatted.toLowerCase() : formatted;
}

String formatTimeOfDay(DateTime dateTime, AppSettings settings) {
  return formatTimeWithSettings(
    dateTime,
    settings,
    twelveHourPattern: 'h:mm a',
    twentyFourHourPattern: 'HH:mm',
  );
}

String formatHourLabel(DateTime dateTime, AppSettings settings) {
  return formatTimeWithSettings(
    dateTime,
    settings,
    twelveHourPattern: 'ha',
    twentyFourHourPattern: 'HH',
    lowercase: settings.resolvedTimeFormat == TimeFormatUnit.twelveHour,
  );
}

String formatHourLabelSpaced(DateTime dateTime, AppSettings settings) {
  return formatTimeWithSettings(
    dateTime,
    settings,
    twelveHourPattern: 'h a',
    twentyFourHourPattern: 'HH',
  );
}

String formatSunTime(DateTime dateTime, AppSettings settings) {
  return formatTimeWithSettings(
    dateTime,
    settings,
    twelveHourPattern: 'h:mm',
    twentyFourHourPattern: 'HH:mm',
  );
}

String formatMeridiem(DateTime dateTime, AppSettings settings) {
  if (settings.resolvedTimeFormat == TimeFormatUnit.twentyFourHour) {
    return '';
  }
  return DateFormat('a').format(dateTime);
}
