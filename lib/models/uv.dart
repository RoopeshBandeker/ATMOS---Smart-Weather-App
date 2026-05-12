import 'package:flutter/material.dart';

class UvIndex {
  final double max;
  final DateTime? date;

  const UvIndex({
    required this.max,
    this.date,
  });

  factory UvIndex.fromJson(Map<String, dynamic> json) {
    final daily = json['daily'];
    if (daily is! Map<String, dynamic>) {
      throw const FormatException('Invalid UV response: missing daily data.');
    }

    final values = daily['uv_index_max'];
    if (values is! List || values.isEmpty || values.first is! num) {
      throw const FormatException('Invalid UV response: missing uv_index_max.');
    }

    final dates = daily['time'];
    DateTime? parsedDate;
    if (dates is List && dates.isNotEmpty && dates.first is String) {
      parsedDate = DateTime.tryParse(dates.first as String);
    }

    return UvIndex(
      max: (values.first as num).toDouble(),
      date: parsedDate,
    );
  }

  String get category {
    if (max <= 2) return 'Low';
    if (max <= 5) return 'Moderate';
    if (max <= 7) return 'High';
    if (max <= 10) return 'Very High';
    return 'Extreme';
  }

  Color get color {
    if (max <= 2) return Colors.green;
    if (max <= 5) return Colors.yellow.shade700;
    if (max <= 7) return Colors.orange;
    if (max <= 10) return Colors.red;
    return Colors.purple;
  }
}
