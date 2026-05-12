import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// A simple state holder for map location using ValueNotifier.
/// 
/// This allows widgets to listen to location changes without heavy
/// dependency injection frameworks. Usage:
/// 
/// ```dart
/// final notifier = MapLocationNotifier(LatLng(0, 0));
/// 
/// // Update location (will notify listeners)
/// notifier.updateLocation(LatLng(40.7128, -74.0060));
/// 
/// // Listen in a widget
/// ValueListenableBuilder<LatLng>(
///   valueListenable: notifier,
///   builder: (context, location, _) => Text('${location.latitude}'),
/// )
/// ```
class MapLocationNotifier extends ValueNotifier<LatLng> {
  // using super parameter to satisfy use_super_parameters lint
  MapLocationNotifier(super.value);

  /// Update the location and notify all listeners.
  void updateLocation(double latitude, double longitude) {
    value = LatLng(latitude, longitude);
  }

  /// Update with a LatLng object directly.
  void updateLocationFromLatLng(LatLng location) {
    value = location;
  }
}
