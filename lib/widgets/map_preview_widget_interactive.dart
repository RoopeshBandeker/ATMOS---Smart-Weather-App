import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../models/settings.dart';
import '../providers/map_location_notifier.dart';
import '../utils/time_formatters.dart';

class MapPreviewWidget extends StatefulWidget {
  final MapLocationNotifier locationNotifier;
  final double height;
  final double initialZoom;
  final AppSettings settings;
  final VoidCallback? onMapTap;
  final int? timezoneOffsetSeconds;
  final String? locationName;

  const MapPreviewWidget({
    required this.locationNotifier,
    required this.settings,
    this.height = 200,
    this.initialZoom = 13,
    this.onMapTap,
    this.timezoneOffsetSeconds,
    this.locationName,
    super.key,
  });

  @override
  State<MapPreviewWidget> createState() => _MapPreviewWidgetState();
}

class _MapPreviewWidgetState extends State<MapPreviewWidget> {
  static const int _previewInteractionFlags =
      InteractiveFlag.all & ~InteractiveFlag.rotate;

  late final MapController _mapController;
  late DateTime _currentDateTime;
  late Timer _timer;
  LatLng? _lastLocation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentDateTime = _getDisplayDateTime();
    _lastLocation = widget.locationNotifier.value;

    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {
          _currentDateTime = _getDisplayDateTime();
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant MapPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timezoneOffsetSeconds != widget.timezoneOffsetSeconds) {
      setState(() {
        _currentDateTime = _getDisplayDateTime();
      });
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _timer.cancel();
    super.dispose();
  }

  String _formatDateDisplay(DateTime dateTime) {
    final dateFormat = DateFormat('EEE d MMM');
    return dateFormat.format(dateTime);
  }

  String _formatTimeDisplay(DateTime dateTime) {
    return formatTimeOfDay(dateTime, widget.settings);
  }

  DateTime _getDisplayDateTime() {
    final timezoneOffsetSeconds = widget.timezoneOffsetSeconds;
    if (timezoneOffsetSeconds == null) {
      return DateTime.now();
    }

    return DateTime.now().toUtc().add(Duration(seconds: timezoneOffsetSeconds));
  }

  void _onLocationChanged() {
    final newLocation = widget.locationNotifier.value;

    _mapController.move(newLocation, widget.initialZoom);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LatLng>(
      valueListenable: widget.locationNotifier,
      builder: (context, location, _) {
        if (_lastLocation == null ||
            _lastLocation!.latitude != location.latitude ||
            _lastLocation!.longitude != location.longitude) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _onLocationChanged();
            }
          });
          _lastLocation = location;
        }

        return Container(
          width: double.infinity,
          height: 200,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                    bottom: Radius.circular(15),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 162,
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: location,
                            initialZoom: widget.initialZoom,
                            minZoom: 2,
                            maxZoom: 18,
                            interactionOptions: const InteractionOptions(
                              flags: _previewInteractionFlags,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.atmos',
                              maxNativeZoom: 19,
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: widget.locationNotifier.value,
                                  width: 28,
                                  height: 28,
                                  child: const Icon(
                                    Icons.location_on,
                                    size: 28,
                                    color: Color(0xFFFF1C46),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Positioned(
                          right: 6,
                          bottom: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                top: 167,
                child: Text(
                  '${_formatDateDisplay(_currentDateTime)}\n${_formatTimeDisplay(_currentDateTime)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    height: 1.2,
                  ),
                ),
              ),
              Positioned(
                right: 16,
                bottom: 6,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onMapTap,
                    borderRadius: BorderRadius.circular(25),
                    child: Container(
                      width: 75,
                      height: 25,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 2,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 12,
                            color: Colors.black,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Map',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
