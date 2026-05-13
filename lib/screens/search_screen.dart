import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/location_search_result.dart';
import '../models/weather.dart';
import '../services/geocoding_service.dart';
import '../utils/time_of_day_theme.dart';

class SearchScreen extends StatefulWidget {
  final GeocodingService geocodingService;
  final ValueListenable<WeatherData?>? weatherNotifier;

  const SearchScreen({
    required this.geocodingService,
    this.weatherNotifier,
    super.key,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _searchIconAsset =
      'assets/search_screen_assets/search_location_icon.svg';
  static const _locationIconAsset =
      'assets/search_screen_assets/map_markar_icon.svg';
  static const _noLocationIconAsset =
      'assets/search_screen_assets/map_marker_cross.svg';
  late final TextEditingController _controller;
  late DateTime _currentDateTime;
  Timer? _debounce;
  Timer? _backgroundTimer;
  List<LocationSearchResult> _suggestions = const [];
  bool _isLoading = false;
  String? _error;
  String _activeQuery = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _currentDateTime = _getDisplayDateTime();
    widget.weatherNotifier?.addListener(_handleWeatherChanged);
    _backgroundTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() {
        _currentDateTime = _getDisplayDateTime();
      });
    });
  }

  @override
  void didUpdateWidget(covariant SearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weatherNotifier != widget.weatherNotifier) {
      oldWidget.weatherNotifier?.removeListener(_handleWeatherChanged);
      widget.weatherNotifier?.addListener(_handleWeatherChanged);
      _currentDateTime = _getDisplayDateTime();
    }
  }

  @override
  void dispose() {
    widget.weatherNotifier?.removeListener(_handleWeatherChanged);
    _debounce?.cancel();
    _backgroundTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _handleWeatherChanged() {
    if (!mounted) return;
    setState(() {
      _currentDateTime = _getDisplayDateTime();
    });
  }

  DateTime _getDisplayDateTime() {
    final weather = widget.weatherNotifier?.value;
    if (weather == null) {
      return DateTime.now();
    }

    final elapsedSinceFetch = DateTime.now().difference(weather.fetchedAt);
    return weather.current.dateTime.add(elapsedSinceFetch);
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();

    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _suggestions = const [];
        _isLoading = false;
        _error = null;
        _activeQuery = '';
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () {
      _loadSuggestions(query);
    });
  }

  Future<void> _loadSuggestions(String query) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _activeQuery = query;
    });

    try {
      final results = await widget.geocodingService.searchLocations(query);
      if (!mounted || _activeQuery != query) return;

      setState(() {
        _suggestions = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || _activeQuery != query) return;

      setState(() {
        _suggestions = const [];
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _selectLocation(LocationSearchResult location) {
    Navigator.of(context).pop(location);
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = getAtmosSkyGradient(_currentDateTime);
    final searchBarTheme = _getSearchBarTheme(_currentDateTime);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: null,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: gradientColors,
            stops: const [0.0, 0.2, 0.4, 0.7],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top * 0.9,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildSearchBar(searchBarTheme),
                const SizedBox(height: 10),
                Expanded(child: _buildSuggestions()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(_SearchBarTheme theme) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 340;
            final barHeight = compact ? 54.0 : 60.0;
            final iconWidth = (constraints.maxWidth * 0.18).clamp(54.0, 70.0);
            final textPadding = compact ? 12.0 : 16.0;
            final textSize = compact ? 16.0 : 18.0;

            return SizedBox(
              width: double.infinity,
              height: barHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.outerBackground,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.symmetric(horizontal: textPadding),
                        child: TextField(
                          controller: _controller,
                          autofocus: true,
                          maxLines: 1,
                          textAlignVertical: TextAlignVertical.center,
                          textInputAction: TextInputAction.search,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: textSize,
                            fontWeight: FontWeight.w400,
                            color: Colors.black87,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search ...',
                            hintStyle: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: textSize,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFFABB7C2),
                            ),
                            border: InputBorder.none,
                            isCollapsed: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: _onQueryChanged,
                          onSubmitted: _onQueryChanged,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: iconWidth,
                      child: Center(
                        child: SvgPicture.asset(
                          _searchIconAsset,
                          width: 24,
                          height: 24,
                          colorFilter: ColorFilter.mode(
                            theme.iconColor,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  _SearchBarTheme _getSearchBarTheme(DateTime time) {
    switch (getAtmosTimePhase(time)) {
      case AtmosTimePhase.morning:
        return const _SearchBarTheme(
          outerBackground: Color(0xFFDEF4FF),
          iconColor: Color(0xFF40C2FF),
        );
      case AtmosTimePhase.afternoon:
        return const _SearchBarTheme(
          outerBackground: Color(0xFFFFF0DE),
          iconColor: Color(0xFFFF792D),
        );
      case AtmosTimePhase.night:
        return const _SearchBarTheme(
          outerBackground: Color(0xFFF4F0FF),
          iconColor: Color(0xFFA38DE0),
        );
    }
  }

  Widget _buildSuggestions() {
    final searchBarTheme = _getSearchBarTheme(_currentDateTime);

    if (_controller.text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF40C2FF)),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Inter'),
          ),
        ),
      );
    }

    if (_suggestions.isEmpty) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 323),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: searchBarTheme.outerBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      _noLocationIconAsset,
                      width: 28,
                      height: 28,
                      colorFilter: ColorFilter.mode(
                        searchBarTheme.iconColor,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No matching locations found',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: _suggestions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return _buildLocationCard(
          suggestion,
          _getSearchBarTheme(_currentDateTime),
        );
      },
    );
  }

  Widget _buildLocationCard(
    LocationSearchResult suggestion,
    _SearchBarTheme theme,
  ) {
    return GestureDetector(
      onTap: () => _selectLocation(suggestion),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 323),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              SvgPicture.asset(
                _locationIconAsset,
                width: 26,
                height: 26,
                colorFilter: ColorFilter.mode(theme.iconColor, BlendMode.srcIn),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion.cityName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        height: 1.2,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      suggestion.displayName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        height: 1.23,
                        color: Color(0xFF4A4A4A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBarTheme {
  final Color outerBackground;
  final Color iconColor;

  const _SearchBarTheme({
    required this.outerBackground,
    required this.iconColor,
  });
}
