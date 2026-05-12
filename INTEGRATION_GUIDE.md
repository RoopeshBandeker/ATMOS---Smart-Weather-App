// Example: Complete Integration of Interactive Map Preview with HomeScreen
//
// This file demonstrates how the map preview integrates with the search/weather flow.

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

// ============================================================================
// 1. STATE MANAGEMENT WITH MapLocationNotifier
// ============================================================================
//
// The MapLocationNotifier is a simple ValueNotifier that holds a LatLng:
//
//   class MapLocationNotifier extends ValueNotifier<LatLng> {
//     void updateLocation(double latitude, double longitude) {
//       value = LatLng(latitude, longitude);
//     }
//   }
//
// No Redux, Riverpod, or Provider package needed. Just a lightweight notifier.

// ============================================================================
// 2. HOMESCREEN SETUP (Simplified Extract)
// ============================================================================
//
// class _HomeScreenState extends State<HomeScreen> {
//   late MapLocationNotifier _mapLocationNotifier;
//
//   @override
//   void initState() {
//     super.initState();
//     // Create notifier with default location (0, 0)
//     _mapLocationNotifier = MapLocationNotifier(const LatLng(0, 0));
//   }
//
//   @override
//   void dispose() {
//     _mapLocationNotifier.dispose(); // Clean up
//     super.dispose();
//   }
//
//   Future<void> _loadWeather() async {
//     // Fetch weather from API...
//     final weather = await widget.weatherService.getCurrentLocationWeather();
//
//     // Update map when data arrives
//     _mapLocationNotifier.updateLocation(
//       weather.current.latitude,
//       weather.current.longitude,
//     );
//   }
//
//   Future<void> _searchWeather(String city) async {
//     // Fetch weather for the searched city...
//     final weather = await widget.weatherService.getWeatherByCity(city);
//
//     // Update map location automatically ← THE KEY FEATURE
//     _mapLocationNotifier.updateLocation(
//       weather.current.latitude,
//       weather.current.longitude,
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         children: [
//           // Search bar...
//           _buildSearchBar(),
//
//           // Interactive map preview
//           // ← Automatically updates when _mapLocationNotifier changes
//           MapPreviewWidget(
//             locationNotifier: _mapLocationNotifier,
//             height: 200,
//             initialZoom: 13,
//           ),
//
//           // Weather data...
//           CurrentWeatherCard(weather: _weather!.current),
//         ],
//       ),
//     );
//   }
// }

// ============================================================================
// 3. HOW THE FLOW WORKS
// ============================================================================
//
// User Input (Search)
//        ↓
// _searchWeather() fetches new data
//        ↓
// _mapLocationNotifier.updateLocation(lat, lon) is called
//        ↓
// ALL listeners are notified (MapPreviewWidget rebuilds)
//        ↓
// Map animates to new location (smooth camera movement)
//        ↓
// Marker updates position
//        ↓
// Zoom controls and info display update automatically
//
// NO setState() needed in MapPreviewWidget → It uses ValueListenableBuilder
// NO navigation between widgets → Pure reactive data flow

// ============================================================================
// 4. MAPPREVIEWWIDGET FEATURES
// ============================================================================
//
// ✓ Fully interactive: zoom (pinch), pan (drag), rotate (two-finger)
// ✓ Zoom controls: red [+] and [-] buttons in top-right
// ✓ Camera animation: smooth transition when location changes
// ✓ Marker tracking: follows the notifier's location
// ✓ Attribution: "© OpenStreetMap contributors" at bottom
// ✓ Info display: coordinates at top-left, zoom level at bottom-left
// ✓ Responsive: rebuilds only when location changes (via ValueListenableBuilder)

// ============================================================================
// 5. CLEAN ARCHITECTURE BENEFITS
// ============================================================================
//
// ✓ Single Responsibility:
//   - MapLocationNotifier: manages location state only
//   - MapPreviewWidget: renders the map only
//   - HomeScreen: orchestrates weather/search logic
//
// ✓ Decoupled:
//   - MapPreviewWidget doesn't know about WeatherService
//   - HomeScreen doesn't directly manipulate map internals
//   - Communication via a simple LatLng value
//
// ✓ Testable:
//   - MapLocationNotifier can be tested in isolation
//   - MapPreviewWidget can be tested with mock notifier values
//   - HomeScreen search logic is independent
//
// ✓ Lightweight:
//   - No heavy dependency injection
//   - No code generation
//   - Just ValueNotifier → minimal overhead

// ============================================================================
// 6. ADVANCED: CUSTOM ZOOM ON SEARCH
// ============================================================================
//
// If you want the map to zoom to specific level based on search context:
//
// 1. Extend MapLocationNotifier:
//    class MapLocationNotifier extends ValueNotifier<LatLng> {
//      double zoomLevel = 13;
//      void updateLocation(double lat, double lon, {double? zoom}) {
//        value = LatLng(lat, lon);
//        if (zoom != null) zoomLevel = zoom.clamp(2, 18);
//        notifyListeners();
//      }
//    }
//
// 2. Update MapPreviewWidget to listen to zoom changes and apply them.

// ============================================================================
// 7. EXAMPLE: SEARCH FLOW WITH DEBUG LOGGING
// ============================================================================
//
// Future<void> _searchWeather(String city) async {
//   print('[SEARCH] User searched for: $city');
//
//   try {
//     final weather = await widget.weatherService.getWeatherByCity(city);
//     print('[FETCH] Got lat=${weather.current.latitude}, '
//           'lon=${weather.current.longitude}');
//
//     // Update map
//     _mapLocationNotifier.updateLocation(
//       weather.current.latitude,
//       weather.current.longitude,
//     );
//     print('[MAP] Notifier updated → MapPreviewWidget rebuilds');
//
//     // Update UI
//     setState(() {
//       _weather = weather;
//     });
//     print('[UI] Weather display updated');
//   } catch (e) {
//     print('[ERROR] Search failed: $e');
//   }
// }

// ============================================================================

// This is a documentation/example file. Actual implementations are in:
// - lib/providers/map_location_notifier.dart
// - lib/widgets/map_preview_widget_interactive.dart
// - lib/screens/home_screen.dart
