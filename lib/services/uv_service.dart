import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/uv.dart';

class UvService {
  Future<UvIndex> getDailyUvIndex({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https(
      'api.open-meteo.com',
      '/v1/forecast',
      <String, String>{
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'daily': 'uv_index_max',
        'timezone': 'auto',
      },
    );

    late http.Response response;
    try {
      response = await http.get(uri).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw Exception('UV request timed out. Please try again.');
    } on SocketException {
      throw Exception('Unable to load UV index. Check your internet connection.');
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to load UV index (${response.statusCode}).');
    }

    final json = jsonDecode(response.body);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid UV response format.');
    }

    return UvIndex.fromJson(json);
  }
}
