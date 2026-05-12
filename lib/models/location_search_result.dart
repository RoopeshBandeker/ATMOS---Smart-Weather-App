class LocationSearchResult {
  final String cityName;
  final String countryCode;
  final String? state;
  final double latitude;
  final double longitude;

  const LocationSearchResult({
    required this.cityName,
    required this.countryCode,
    required this.latitude,
    required this.longitude,
    this.state,
  });

  factory LocationSearchResult.fromJson(Map<String, dynamic> json) {
    return LocationSearchResult(
      cityName: json['name'] as String? ?? 'Unknown',
      countryCode: json['country'] as String? ?? '',
      state: json['state'] as String?,
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lon'] as num).toDouble(),
    );
  }

  String get displayName {
    final parts = <String>[
      cityName,
      if (state != null && state!.trim().isNotEmpty) state!.trim(),
      if (countryCode.trim().isNotEmpty) countryCode.trim(),
    ];
    return parts.join(', ');
  }
}
