import 'package:flutter/material.dart';
import '../models/settings.dart';
import '../utils/converters.dart';

/// Widget to display weather layer markers on the map
class WeatherLayerMarker extends StatelessWidget {
  final double latitude;
  final double longitude;
  final double temperature;
  final int windSpeed;
  final int windDirection;
  final int pressure;
  final int humidity;
  final String condition;
  final AppSettings settings;
  final Set<String> selectedLayers;

  const WeatherLayerMarker({
    required this.latitude,
    required this.longitude,
    required this.temperature,
    required this.windSpeed,
    required this.windDirection,
    required this.pressure,
    required this.humidity,
    required this.condition,
    required this.settings,
    required this.selectedLayers,
    super.key,
  });

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Colors.yellow.shade600;
      case 'clouds':
        return Colors.grey.shade400;
      case 'rain':
      case 'drizzle':
        return Colors.blue.shade400;
      case 'thunderstorm':
        return Colors.purple.shade600;
      case 'snow':
        return Colors.blue.shade100;
      case 'mist':
      case 'fog':
        return Colors.grey.shade300;
      default:
        return Colors.lightBlue;
    }
  }

  String _getUnit() {
    return settings.temperatureUnit == TemperatureUnit.celsius ? '°C' : '°F';
  }

  String _getWindUnit() {
    switch (settings.windSpeedUnit) {
      case WindSpeedUnit.ms:
        return 'm/s';
      case WindSpeedUnit.kmh:
        return 'km/h';
      case WindSpeedUnit.mph:
        return 'mph';
      case WindSpeedUnit.knots:
        return 'kt';
    }
  }

  double _convertTemperature(double temp) {
    if (settings.temperatureUnit == TemperatureUnit.celsius) {
      return temp;
    }
    return UnitConversionUtils.celsiusToFahrenheit(temp);
  }

  double _convertWindSpeed(int speed) {
    switch (settings.windSpeedUnit) {
      case WindSpeedUnit.ms:
        return speed.toDouble();
      case WindSpeedUnit.kmh:
        return UnitConversionUtils.msToKmh(speed.toDouble());
      case WindSpeedUnit.mph:
        return UnitConversionUtils.msToMph(speed.toDouble());
      case WindSpeedUnit.knots:
        return UnitConversionUtils.msToKnots(speed.toDouble());
    }
  }

  String _buildPrimaryLine() {
    // Prioritize temperature, then pressure, then humidity, then condition text.
    if (selectedLayers.contains('Temperature')) {
      final convertedTemp = _convertTemperature(temperature);
      return '${convertedTemp.toStringAsFixed(1)}${_getUnit()}';
    }

    if (selectedLayers.contains('Pressure')) {
      final unitKey = settings.pressureUnit.toString().split('.').last;
      final formatted =
          UnitConversionUtils.formatPressure(pressure, unitKey);
      return formatted;
    }

    if (selectedLayers.contains('Humidity')) {
      return '$humidity% RH';
    }

    // Default fallback to condition text.
    return condition;
  }

  String? _buildSecondaryLine() {
    // Show wind information when its layer is enabled.
    if (selectedLayers.contains('Wind Speed')) {
      final convertedWind = _convertWindSpeed(windSpeed);
      return '${convertedWind.toStringAsFixed(0)}${_getWindUnit()}';
    }

    // Use condition text when Clouds layer is selected and not already primary.
    final primary = _buildPrimaryLine();
    if (selectedLayers.contains('Clouds') &&
        !primary.toLowerCase().contains(condition.toLowerCase())) {
      return condition;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final primaryLine = _buildPrimaryLine();
    final secondaryLine = _buildSecondaryLine();

    return Tooltip(
      message: '$condition - $primaryLine',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getConditionColor(condition).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white70, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              primaryLine,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (secondaryLine != null)
              Text(
                secondaryLine,
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}

/// Information card for layer details
class WeatherLayerInfo extends StatelessWidget {
  final String layerType;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const WeatherLayerInfo({
    required this.layerType,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(side: BorderSide.none),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  layerType,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '$value $unit',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Layer selector widget for choosing which data to display
class LayerSelector extends StatefulWidget {
  final Function(Set<String>) onLayersChanged;
  final Set<String> selectedLayers;

  const LayerSelector({
    required this.onLayersChanged,
    required this.selectedLayers,
    super.key,
  });

  @override
  State<LayerSelector> createState() => _LayerSelectorState();
}

class _LayerSelectorState extends State<LayerSelector> {
  late Set<String> _selectedLayers;

  @override
  void initState() {
    super.initState();
    _selectedLayers = Set.from(widget.selectedLayers);
  }

  void _toggleLayer(String layer) {
    setState(() {
      if (_selectedLayers.contains(layer)) {
        _selectedLayers.remove(layer);
      } else {
        _selectedLayers.add(layer);
      }
      widget.onLayersChanged(_selectedLayers);
    });
  }

  @override
  Widget build(BuildContext context) {
    final layers = [
      ('Temperature', Icons.thermostat, Colors.red),
      ('Wind Speed', Icons.air, Colors.blue),
      ('Pressure', Icons.compress, Colors.orange),
      ('Humidity', Icons.opacity, Colors.cyan),
      ('Clouds', Icons.cloud, Colors.grey),
    ];

    return Card(
      color: Colors.black.withValues(alpha: 0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Weather Layers',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: layers.map((layer) {
                final isSelected = _selectedLayers.contains(layer.$1);
                return FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(layer.$2,
                          color: isSelected ? layer.$3 : Colors.white70,
                          size: 16),
                      const SizedBox(width: 4),
                      Text(layer.$1),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (_) => _toggleLayer(layer.$1),
                  backgroundColor: Colors.white10,
                  selectedColor: layer.$3.withValues(alpha: 0.4),
                  labelStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
