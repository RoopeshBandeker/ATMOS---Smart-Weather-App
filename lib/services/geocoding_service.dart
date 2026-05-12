import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_key.dart';
import '../models/location_search_result.dart';

class GeocodingService {
  static const String _baseUrl =
      'https://api.openweathermap.org/geo/1.0/direct';

  Future<List<LocationSearchResult>> searchLocations(
    String query, {
    int limit = 5,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return const [];
    }

    final apiLimit = limit * 3;
    final uri = Uri.parse(
      '$_baseUrl?q=${Uri.encodeQueryComponent(trimmedQuery)}&limit=$apiLimit&appid=$openweatherApiKey',
    );

    late http.Response response;
    try {
      response = await http.get(uri).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw Exception('Search request timed out. Please try again.');
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load location suggestions (Error ${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('Invalid search response received');
    }

    final results = decoded
        .whereType<Map<String, dynamic>>()
        .map(LocationSearchResult.fromJson)
        .toList();

    final seen = <String>{};
    final uniqueResults = <LocationSearchResult>[];

    for (final result in results) {
      final key = [
        result.cityName.trim().toLowerCase(),
        result.state?.trim().toLowerCase() ?? '',
        result.countryCode.trim().toLowerCase(),
      ].join('|');

      if (seen.add(key)) {
        uniqueResults.add(result);
      }

      if (uniqueResults.length >= limit) {
        break;
      }
    }

    return uniqueResults;
  }
}
