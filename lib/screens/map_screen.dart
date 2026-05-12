import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../config/api_key.dart';
import '../models/settings.dart';
import '../services/weather_map_service.dart';

class MapScreen extends StatefulWidget {
  final AppSettings settings;
  final LatLng? initialCenter;

  const MapScreen({
    required this.settings,
    this.initialCenter,
    super.key,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng _defaultIndiaCenter = LatLng(20.5937, 78.9629);
  static final LatLngBounds _worldBounds = LatLngBounds(
    const LatLng(-85, -180),
    const LatLng(85, 180),
  );
  static const double _initialZoom = 6.5;
  static const double _focusedZoom = 7;
  static const int _nonRotatingInteractionFlags =
      InteractiveFlag.all & ~InteractiveFlag.rotate;

  final MapController _mapController = MapController();
  final ValueNotifier<String> _currentLayerNotifier =
      ValueNotifier<String>('clouds_new');
  final ValueNotifier<bool> _legendCollapsedNotifier =
      ValueNotifier<bool>(false);
  final ValueNotifier<_WindField?> _windFieldNotifier =
      ValueNotifier<_WindField?>(null);
  final WeatherMapService _weatherMapService = WeatherMapService();
  final ValueNotifier<bool> _isLoadingLocationNotifier =
      ValueNotifier<bool>(true);
  final ValueNotifier<String?> _locationMessageNotifier =
      ValueNotifier<String?>(null);

  LatLng _currentCenter = _defaultIndiaCenter;
  Timer? _windRefreshDebounceTimer;
  int _windRequestToken = 0;

  static const List<_WeatherOverlayLayer> _layers = [
    _WeatherOverlayLayer(
      id: 'clouds_new',
      label: 'Clouds',
      icon: Icons.cloud,
    ),
    _WeatherOverlayLayer(
      id: 'precipitation_new',
      label: 'Rain',
      icon: Icons.grain,
    ),
    _WeatherOverlayLayer(
      id: 'temp_new',
      label: 'Temperature',
      icon: Icons.thermostat,
    ),
    _WeatherOverlayLayer(
      id: 'wind_new',
      label: 'Wind',
      icon: Icons.air,
    ),
    _WeatherOverlayLayer(
      id: 'pressure_new',
      label: 'Pressure',
      icon: Icons.compress,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _configureTileImageCache();
    debugPrint(
      'OpenWeatherMap API key: '
      '${openweatherApiKey.isEmpty ? 'EMPTY' : '${openweatherApiKey.substring(0, openweatherApiKey.length < 6 ? openweatherApiKey.length : 6)}...'}',
    );
    debugPrint('Base tile test URL: $_baseTileDebugUrl');
    debugPrint('Overlay test URL: ${_overlayDebugUrl('clouds_new')}');
    _initializeMapCenter();
  }

  bool get _hasValidApiKey => openweatherApiKey.trim().isNotEmpty;

  String get _baseTileDebugUrl =>
      'https://a.basemaps.cartocdn.com/dark_all/5/10/12.png';

  void _configureTileImageCache() {
    final imageCache = PaintingBinding.instance.imageCache;
    if (imageCache.maximumSize < 600) {
      imageCache.maximumSize = 600;
    }
    if (imageCache.maximumSizeBytes < 160 << 20) {
      imageCache.maximumSizeBytes = 160 << 20;
    }
  }

  String _overlayDebugUrl(String layer) {
    return 'https://tile.openweathermap.org/map/$layer/5/10/12.png?appid=$openweatherApiKey';
  }

  Future<void> _initializeMapCenter() async {
    if (widget.initialCenter != null) {
      _currentCenter = widget.initialCenter!;
      _isLoadingLocationNotifier.value = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(_currentCenter, _focusedZoom);
        _mapController.rotate(0.0);
      });
      _loadWindFieldFor(_currentCenter);
      return;
    }

    try {
      final permission = await _ensureLocationPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _isLoadingLocationNotifier.value = false;
        _locationMessageNotifier.value = 'Using India as the default map center.';
        _scheduleWindRefresh(_defaultIndiaCenter, immediate: true);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      final userCenter = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      _currentCenter = userCenter;
      _isLoadingLocationNotifier.value = false;
      _locationMessageNotifier.value = null;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(userCenter, _focusedZoom);
        _mapController.rotate(0.0);
      });
      _loadWindFieldFor(userCenter);
    } catch (_) {
      if (!mounted) return;
      _isLoadingLocationNotifier.value = false;
      _locationMessageNotifier.value =
          'Could not get your location. Showing India instead.';
      _currentCenter = _defaultIndiaCenter;
      _loadWindFieldFor(_defaultIndiaCenter);
    }
  }

  Future<LocationPermission> _ensureLocationPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  void _centerOnCurrentArea() {
    _mapController.move(_currentCenter, _focusedZoom);
    _mapController.rotate(0.0);
    _loadWindFieldFor(_currentCenter);
  }

  void _scheduleWindRefresh(
    LatLng center, {
    bool immediate = false,
  }) {
    _windRefreshDebounceTimer?.cancel();
    if (immediate) {
      _loadWindFieldFor(center);
      return;
    }

    _windRefreshDebounceTimer = Timer(
      const Duration(milliseconds: 400),
      () => _loadWindFieldFor(center),
    );
  }

  Future<void> _loadWindFieldFor(LatLng center) async {
    final requestToken = ++_windRequestToken;
    debugPrint(
      'Fetching wind for lat=${center.latitude.toStringAsFixed(4)}, '
      'lon=${center.longitude.toStringAsFixed(4)}',
    );
    try {
      final data = await _weatherMapService.getWeatherWithAdvancedData(
        latitude: center.latitude,
        longitude: center.longitude,
      );

      if (!mounted || requestToken != _windRequestToken) {
        return;
      }

      final speed = (data['windSpeed'] as num?)?.toDouble() ?? 0;
      final direction = (data['windDegree'] as num?)?.toDouble() ?? 0;
      debugPrint(
        'Wind updated for lat=${center.latitude.toStringAsFixed(4)}, '
        'lon=${center.longitude.toStringAsFixed(4)} '
        'speed=${speed.toStringAsFixed(1)}m/s direction=${direction.toStringAsFixed(1)}deg',
      );
      _windFieldNotifier.value = _WindField(
        speed: speed,
        directionDegrees: direction,
      );
    } catch (e) {
      if (!mounted || requestToken != _windRequestToken) {
        return;
      }
      debugPrint('Wind overlay data fetch failed: $e');
      _windFieldNotifier.value = const _WindField(
        speed: 4,
        directionDegrees: 0,
      );
    }
  }

  void _switchLayer(String layerId) {
    if (_currentLayerNotifier.value == layerId) {
      return;
    }

    _currentLayerNotifier.value = layerId;
    if (layerId == 'wind_new') {
      _scheduleWindRefresh(_currentCenter, immediate: true);
    }
    debugPrint(
      'Switched overlay to $layerId: ${_overlayDebugUrl(layerId)}',
    );
  }

  @override
  void dispose() {
    _windRefreshDebounceTimer?.cancel();
    _currentLayerNotifier.dispose();
    _legendCollapsedNotifier.dispose();
    _windFieldNotifier.dispose();
    _isLoadingLocationNotifier.dispose();
    _locationMessageNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: _initialZoom,
              initialRotation: 0.0,
              minZoom: 4,
              maxZoom: 10,
              cameraConstraint: CameraConstraint.containCenter(
                bounds: _worldBounds,
              ),
              interactionOptions: const InteractionOptions(
                flags: _nonRotatingInteractionFlags,
              ),
              onTap: (_, point) {
                _currentCenter = point;
                _loadWindFieldFor(point);
              },
              onPositionChanged: (camera, hasGesture) {
                final center = camera.center;

                _currentCenter = center;
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.atmos',
                tileDimension: 256,
                keepBuffer: 1,
                maxZoom: 10,
                maxNativeZoom: 10,
              ),
              if (_hasValidApiKey)
                _WeatherOverlay(
                  currentLayerNotifier: _currentLayerNotifier,
                )
              else
                const SizedBox.shrink(),
            ],
          ),
          Positioned.fill(
            child: _WindOverlayHost(
              currentLayerNotifier: _currentLayerNotifier,
              windFieldNotifier: _windFieldNotifier,
            ),
          ),
          if (!_hasValidApiKey)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade700.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'OpenWeatherMap tiles are disabled because the API key is empty. Add a valid key in api_key.dart.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Row(
                    children: [
                      _TopMapButton(
                        icon: Icons.arrow_back,
                        tooltip: 'Back',
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.58),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Weather Map',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              ValueListenableBuilder<String>(
                                valueListenable: _currentLayerNotifier,
                                builder: (context, currentLayer, _) {
                                  return Text(
                                    _labelForLayer(currentLayer),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _TopMapButton(
                        icon: Icons.my_location,
                        tooltip: 'Center map',
                        onTap: _centerOnCurrentArea,
                      ),
                    ],
                  ),
                ),
                ValueListenableBuilder<String?>(
                  valueListenable: _locationMessageNotifier,
                  builder: (context, locationMessage, _) {
                    if (locationMessage == null) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          locationMessage,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  child: _LayerControlBar(
                    layers: _layers,
                    currentLayerNotifier: _currentLayerNotifier,
                    onLayerSelected: _switchLayer,
                  ),
                ),
              ],
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _isLoadingLocationNotifier,
            builder: (context, isLoadingLocation, _) {
              if (!isLoadingLocation) {
                return const SizedBox.shrink();
              }

              return Container(
                color: Colors.black.withValues(alpha: 0.15),
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Finding your location...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Positioned(
            right: 12,
            bottom: 96,
            child: SafeArea(
              child: RepaintBoundary(
                child: _WeatherLegend(
                  currentLayerNotifier: _currentLayerNotifier,
                  collapsedNotifier: _legendCollapsedNotifier,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _labelForLayer(String id) {
    return _layers.firstWhere((layer) => layer.id == id).label;
  }
}

class _WeatherOverlayLayer {
  final String id;
  final String label;
  final IconData icon;

  const _WeatherOverlayLayer({
    required this.id,
    required this.label,
    required this.icon,
  });
}

class _WeatherOverlay extends StatelessWidget {
  final ValueNotifier<String> currentLayerNotifier;

  const _WeatherOverlay({
    required this.currentLayerNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: currentLayerNotifier,
      builder: (context, currentLayer, _) {
        return Opacity(
          opacity: 0.88,
          child: TileLayer(
            key: ValueKey(currentLayer),
            urlTemplate:
                'https://tile.openweathermap.org/map/$currentLayer/{z}/{x}/{y}.png?appid=$openweatherApiKey',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.atmos',
            tileDimension: 256,
            keepBuffer: 1,
            maxZoom: 10,
            maxNativeZoom: 10,
          ),
        );
      },
    );
  }
}

class _TopMapButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _TopMapButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.58),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _LayerControlBar extends StatelessWidget {
  final List<_WeatherOverlayLayer> layers;
  final ValueNotifier<String> currentLayerNotifier;
  final ValueChanged<String> onLayerSelected;

  const _LayerControlBar({
    required this.layers,
    required this.currentLayerNotifier,
    required this.onLayerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ValueListenableBuilder<String>(
        valueListenable: currentLayerNotifier,
        builder: (context, currentLayer, _) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: layers.map((layer) {
                final isActive = currentLayer == layer.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ElevatedButton.icon(
                    onPressed: () => onLayerSelected(layer.id),
                    icon: Icon(layer.icon, size: 18),
                    label: Text(layer.label),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive ? Colors.blue : Colors.black54,
                      foregroundColor: Colors.white,
                      elevation: isActive ? 2 : 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

class _WeatherLegend extends StatelessWidget {
  final ValueNotifier<String> currentLayerNotifier;
  final ValueNotifier<bool> collapsedNotifier;

  const _WeatherLegend({
    required this.currentLayerNotifier,
    required this.collapsedNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: currentLayerNotifier,
      builder: (context, currentLayer, _) {
        final config = _LegendConfig.forLayer(currentLayer);
        if (config == null) {
          return const SizedBox.shrink();
        }

        return ValueListenableBuilder<bool>(
          valueListenable: collapsedNotifier,
          builder: (context, isCollapsed, _) {
            return GestureDetector(
              onTap: () => collapsedNotifier.value = !isCollapsed,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: isCollapsed
                      ? Row(
                          key: ValueKey('collapsed_${config.title}'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              config.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.tune,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        )
                      : Column(
                          key: ValueKey('expanded_${config.title}'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  config.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.expand_more,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 20,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: config.colors,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 150,
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: config.labels
                                        .reversed
                                        .map(
                                          (label) => Text(
                                            '${label.value}${config.unit}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _LegendLabel {
  final String value;

  const _LegendLabel(this.value);
}

class _LegendConfig {
  final String title;
  final String unit;
  final List<Color> colors;
  final List<_LegendLabel> labels;

  const _LegendConfig({
    required this.title,
    required this.unit,
    required this.colors,
    required this.labels,
  });

  static _LegendConfig? forLayer(String layer) {
    switch (layer) {
      case 'precipitation_new':
        return const _LegendConfig(
          title: 'Rain',
          unit: ' mm',
          colors: [
            Color(0xFF7B1FA2),
            Color(0xFF3949AB),
            Color(0xFF1E88E5),
          ],
          labels: [
            _LegendLabel('0'),
            _LegendLabel('5'),
            _LegendLabel('10'),
            _LegendLabel('20+'),
          ],
        );
      case 'temp_new':
        return const _LegendConfig(
          title: 'Temperature',
          unit: ' \u00B0C',
          colors: [
            Color(0xFF1565C0),
            Color(0xFF00BCD4),
            Color(0xFF43A047),
            Color(0xFFFDD835),
            Color(0xFFFB8C00),
            Color(0xFFE53935),
          ],
          labels: [
            _LegendLabel('-10'),
            _LegendLabel('0'),
            _LegendLabel('10'),
            _LegendLabel('20'),
            _LegendLabel('30'),
            _LegendLabel('40+'),
          ],
        );
      case 'clouds_new':
        return const _LegendConfig(
          title: 'Clouds',
          unit: ' %',
          colors: [
            Color(0xFF212121),
            Color(0xFF616161),
            Color(0xFF9E9E9E),
            Color(0xFFD6D6D6),
          ],
          labels: [
            _LegendLabel('0'),
            _LegendLabel('25'),
            _LegendLabel('50'),
            _LegendLabel('75'),
            _LegendLabel('100'),
          ],
        );
      case 'pressure_new':
        return const _LegendConfig(
          title: 'Pressure',
          unit: ' hPa',
          colors: [
            Color(0xFF6A1B9A),
            Color(0xFF1565C0),
            Color(0xFF00ACC1),
            Color(0xFF43A047),
            Color(0xFFFDD835),
            Color(0xFFE53935),
          ],
          labels: [
            _LegendLabel('980'),
            _LegendLabel('995'),
            _LegendLabel('1010'),
            _LegendLabel('1025'),
            _LegendLabel('1040+'),
          ],
        );
      default:
        return null;
    }
  }
}

class _WindField {
  final double speed;
  final double directionDegrees;

  const _WindField({
    required this.speed,
    required this.directionDegrees,
  });
}

class _WindOverlayHost extends StatelessWidget {
  final ValueNotifier<String> currentLayerNotifier;
  final ValueNotifier<_WindField?> windFieldNotifier;

  const _WindOverlayHost({
    required this.currentLayerNotifier,
    required this.windFieldNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ValueListenableBuilder<String>(
        valueListenable: currentLayerNotifier,
        builder: (context, currentLayer, _) {
          if (currentLayer != 'wind_new') {
            return const SizedBox.shrink();
          }

          return ValueListenableBuilder<_WindField?>(
            valueListenable: windFieldNotifier,
            builder: (context, windField, _) {
              if (windField == null) {
                return const SizedBox.shrink();
              }
              return RepaintBoundary(
                child: _WindParticleOverlay(
                  windField: windField,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _WindParticleOverlay extends StatefulWidget {
  final _WindField windField;

  const _WindParticleOverlay({
    required this.windField,
  });

  @override
  State<_WindParticleOverlay> createState() => _WindParticleOverlayState();
}

class _WindParticleOverlayState extends State<_WindParticleOverlay>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const Duration _frameInterval = Duration(milliseconds: 33);

  late final Ticker _ticker;
  late final _WindParticleEngine _engine;
  Duration _lastTick = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _engine = _WindParticleEngine(
      windField: widget.windField,
    );
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didUpdateWidget(covariant _WindParticleOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.windField.speed != widget.windField.speed ||
        oldWidget.windField.directionDegrees !=
            widget.windField.directionDegrees) {
      _engine.updateWind(widget.windField);
    }
  }

  void _onTick(Duration elapsed) {
    if (elapsed - _lastTick < _frameInterval) {
      return;
    }
    _lastTick = elapsed;
    _engine.step();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_ticker.isActive) {
        _ticker.start();
      }
    } else {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _engine.updateViewport(
          Size(constraints.maxWidth, constraints.maxHeight),
        );
        return CustomPaint(
          painter: _WindParticlePainter(_engine),
          size: Size.infinite,
        );
      },
    );
  }
}

class _WindParticleEngine extends ChangeNotifier {
  static const int _minParticles = 180;
  static const int _maxParticles = 260;
  static const double _directionJitterRadians = math.pi / 60;
  static const double _minTrailLength = 2.0;
  static const double _maxTrailLength = 7.0;
  static const double _lowWindThreshold = 2.0;
  static const double _highWindThreshold = 18.0;

  final math.Random _random = math.Random();
  final List<_WindParticle> _particles = <_WindParticle>[];
  final List<_WindStream> _streams = <_WindStream>[];

  late _WindField _windField;
  Size _viewport = Size.zero;
  int _particleCount = _minParticles;
  int _streamCount = 10;
  double _flowRadians = 0;
  double _screenDx = 1;
  double _screenDy = 0;
  double _perpendicularDx = 0;
  double _perpendicularDy = 1;
  double _speedFactor = 0;

  _WindParticleEngine({
    required _WindField windField,
  }) : _windField = windField {
    _updateFlowMetrics();
  }

  void updateWind(_WindField windField) {
    _windField = windField;
    if (_viewport == Size.zero || _particles.isEmpty) {
      _updateFlowMetrics();
      return;
    }

    _updateFlowMetrics();
    _syncParticleCount();
    for (final particle in _particles) {
      _applyWindVector(particle);
      _positionParticleInStream(
        particle,
        resetProgress: false,
      );
      particle.previousX = particle.x;
      particle.previousY = particle.y;
    }
    notifyListeners();
  }

  void updateViewport(Size viewport) {
    if (viewport.width <= 0 || viewport.height <= 0) {
      return;
    }

    final shouldResize = _viewport != viewport;
    _viewport = viewport;
    _updateFlowMetrics();

    if (shouldResize || _particles.length != _particleCount) {
      _reseedParticles();
    } else {
      _rebuildStreams();
    }
  }

  List<_WindParticle> get particles => _particles;

  void step() {
    if (_viewport == Size.zero || _particles.isEmpty) {
      return;
    }

    for (final particle in _particles) {
      particle.previousX = particle.x;
      particle.previousY = particle.y;
      particle.x += particle.dx;
      particle.y -= particle.dy;
      particle.life -= 1;

      if (particle.x < -8 ||
          particle.x > _viewport.width + 8 ||
          particle.y < -8 ||
          particle.y > _viewport.height + 8 ||
          particle.life <= 0) {
        _resetParticle(particle);
      }
    }

    notifyListeners();
  }

  void _reseedParticles() {
    _rebuildStreams();
    _particles
      ..clear()
      ..addAll(
        List<_WindParticle>.generate(
          _particleCount,
          (_) => _createParticle(randomizePosition: true),
          growable: false,
        ),
      );
    notifyListeners();
  }

  _WindParticle _createParticle({required bool randomizePosition}) {
    final particle = _WindParticle(
      x: 0,
      y: 0,
      previousX: 0,
      previousY: 0,
      dx: 0,
      dy: 0,
      speed: 0,
      life: 0,
      radius: 1,
      streamIndex: _random.nextInt(_streamCount),
    );

    _applyWindVector(particle);
    _positionParticleInStream(
      particle,
      resetProgress: true,
      randomizePosition: randomizePosition,
    );
    particle.previousX = particle.x;
    particle.previousY = particle.y;
    return particle;
  }

  void _applyWindVector(_WindParticle particle) {
    final jitter = (_random.nextDouble() * 2 - 1) * _directionJitterRadians;
    final radians = _flowRadians + jitter;
    final baseSpeed = _windField.speed.clamp(0.5, 20.0);
    final speedVariance = 0.92 + (_random.nextDouble() * 0.16);
    final speed = (0.6 + (baseSpeed * 0.22)) * speedVariance;
    final dx = math.cos(radians) * speed;
    final dy = math.sin(radians) * speed;
    final currentTrailLength = math.sqrt((dx * dx) + (dy * dy)).clamp(
      _minTrailLength,
      _maxTrailLength,
    );
    final trailScale = currentTrailLength / (speed == 0 ? 1 : speed);

    particle
      ..speed = speed
      ..dx = dx
      ..dy = dy
      ..radius = 1 + (_random.nextDouble() * 0.5)
      ..life = 90 + _random.nextDouble() * 140
      ..previousX = particle.x - (dx * trailScale)
      ..previousY = particle.y + (dy * trailScale);
  }

  void _updateFlowMetrics() {
    final adjustedDirection = (_windField.directionDegrees + 180) % 360;
    _flowRadians = adjustedDirection * math.pi / 180;
    _screenDx = math.cos(_flowRadians);
    _screenDy = -math.sin(_flowRadians);
    _perpendicularDx = -_screenDy;
    _perpendicularDy = _screenDx;
    final clampedSpeed = _windField.speed.clamp(
      _lowWindThreshold,
      _highWindThreshold,
    );
    _speedFactor =
        (clampedSpeed - _lowWindThreshold) /
        (_highWindThreshold - _lowWindThreshold);

    if (_viewport == Size.zero) {
      _particleCount = _minParticles;
      _streamCount = 10;
      return;
    }

    final viewportArea = _viewport.width * _viewport.height;
    final areaFactor = (viewportArea / 320000).clamp(0.9, 1.15);
    final targetCount =
        (_minParticles + ((_maxParticles - _minParticles) * _speedFactor)) *
        areaFactor;
    _particleCount = targetCount.round().clamp(
      _minParticles,
      _maxParticles,
    );
    _streamCount = (8 + (_speedFactor * 10)).round().clamp(8, 18);
  }

  void _syncParticleCount() {
    _rebuildStreams();

    if (_particles.length < _particleCount) {
      _particles.addAll(
        List<_WindParticle>.generate(
          _particleCount - _particles.length,
          (_) => _createParticle(randomizePosition: true),
          growable: false,
        ),
      );
    } else if (_particles.length > _particleCount) {
      _particles.removeRange(_particleCount, _particles.length);
    }

    for (final particle in _particles) {
      if (particle.streamIndex >= _streamCount) {
        particle.streamIndex = _random.nextInt(_streamCount);
      }
    }
  }

  void _rebuildStreams() {
    _streams
      ..clear()
      ..addAll(
        List<_WindStream>.generate(_streamCount, (index) {
          final normalizedIndex = _streamCount == 1
              ? 0.0
              : (index / (_streamCount - 1)) * 2 - 1;
          final spread =
              math.max(_viewport.width, _viewport.height) *
              (0.35 + (_speedFactor * 0.15));
          final laneJitter =
              (_random.nextDouble() - 0.5) * (18 + (_speedFactor * 22));
          return _WindStream(
            lateralOffset: (normalizedIndex * spread) + laneJitter,
            width: 10 + (_speedFactor * 12),
          );
        }),
      );
  }

  void _positionParticleInStream(
    _WindParticle particle, {
    required bool resetProgress,
    bool randomizePosition = true,
  }) {
    if (_viewport == Size.zero || _streams.isEmpty) {
      particle.x = _random.nextDouble() * _viewport.width;
      particle.y = _random.nextDouble() * _viewport.height;
      return;
    }

    final stream = _streams[particle.streamIndex % _streams.length];
    final span = math.max(_viewport.width, _viewport.height);
    final progress = randomizePosition
        ? (_random.nextDouble() * 2 - 1) * span
        : 0.0;
    final lateralNoise = (_random.nextDouble() - 0.5) * stream.width;
    final centerX =
        (_viewport.width / 2) + (_perpendicularDx * (stream.lateralOffset + lateralNoise));
    final centerY =
        (_viewport.height / 2) + (_perpendicularDy * (stream.lateralOffset + lateralNoise));

    if (resetProgress) {
      particle.x = _wrapToViewport(centerX + (_screenDx * progress), _viewport.width);
      particle.y = _wrapToViewport(centerY + (_screenDy * progress), _viewport.height);
    } else {
      final nudgedX =
          particle.x + (_perpendicularDx * lateralNoise * 0.08);
      final nudgedY =
          particle.y + (_perpendicularDy * lateralNoise * 0.08);
      particle.x = _wrapToViewport(nudgedX, _viewport.width);
      particle.y = _wrapToViewport(nudgedY, _viewport.height);
    }
  }

  double _wrapToViewport(double value, double extent) {
    if (extent <= 0) {
      return 0;
    }
    final wrapped = value % extent;
    return wrapped < 0 ? wrapped + extent : wrapped;
  }

  void _resetParticle(_WindParticle particle) {
    if (_streams.isNotEmpty) {
      particle.streamIndex = _random.nextInt(_streamCount);
    }
    _applyWindVector(particle);
    _positionParticleInStream(
      particle,
      resetProgress: true,
    );
    particle.previousX = particle.x;
    particle.previousY = particle.y;
  }
}

class _WindParticle {
  double x;
  double y;
  double previousX;
  double previousY;
  double dx;
  double dy;
  double radius;
  double speed;
  double life;
  int streamIndex;

  _WindParticle({
    required this.x,
    required this.y,
    required this.previousX,
    required this.previousY,
    required this.dx,
    required this.dy,
    required this.radius,
    required this.speed,
    required this.life,
    required this.streamIndex,
  });
}

class _WindStream {
  final double lateralOffset;
  final double width;

  const _WindStream({
    required this.lateralOffset,
    required this.width,
  });
}

class _WindParticlePainter extends CustomPainter {
  final _WindParticleEngine engine;
  final Paint _tailPaint = Paint()
    ..color = const Color(0x99D7F1FF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round;
  final Paint _dotPaint = Paint()
    ..color = const Color(0x99D7F1FF)
    ..style = PaintingStyle.fill;

  _WindParticlePainter(this.engine) : super(repaint: engine);

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in engine.particles) {
      canvas.drawLine(
        Offset(particle.previousX, particle.previousY),
        Offset(particle.x, particle.y),
        _tailPaint,
      );
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.radius,
        _dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WindParticlePainter oldDelegate) => false;
}
