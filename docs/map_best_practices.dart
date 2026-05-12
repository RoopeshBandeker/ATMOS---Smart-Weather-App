// Best Practices for Interactive Map Integration
//
// This guide demonstrates proven patterns for using MapPreviewWidget
// with WeatherService and search flows.

// ============================================================================
// PATTERN 1: Clean Separation of Concerns
// ============================================================================
//
// HomeScreen should NOT:
// ❌ Directly manipulate MapController
// ❌ Know about flutter_map internals
// ❌ Call map animation methods
// ❌ Manage marker state
//
// HomeScreen SHOULD:
// ✅ Create and own MapLocationNotifier
// ✅ Update notifier when data changes
// ✅ Pass notifier to MapPreviewWidget
// ✅ Let MapPreviewWidget handle rendering
//
// Example:
// ```dart
// class _HomeScreenState extends State<HomeScreen> {
//   late MapLocationNotifier _mapLocationNotifier;
//
//   @override
//   void initState() {
//     _mapLocationNotifier = MapLocationNotifier(const LatLng(0, 0));
//   }
//
//   Future<void> _searchWeather(String city) async {
//     final weather = await widget.weatherService.getWeatherByCity(city);
//     
//     // Single line to update map
//     _mapLocationNotifier.updateLocation(
//       weather.current.latitude,
//       weather.current.longitude,
//     );
//   }
// }
// ```

// ============================================================================
// PATTERN 2: Responsive Data Flow
// ============================================================================
//
// The data flow is unidirectional and reactive:
//
//   User Input
//        ↓
//   fetch data
//        ↓
//   update notifier
//        ↓
//   UI rebuilds automatically
//
// There's no explicit "tell the map to move". The map listens to the notifier
// and reacts automatically. This is the reactive programming model.

// ============================================================================
// PATTERN 3: Error Handling Without Blocking UI
// ============================================================================
//
// When a search fails, the map keeps the old location (doesn't reset).
// This is good UX.
//
// Example:
// ```dart
// Future<void> _searchWeather(String city) async {
//   try {
//     final weather = await widget.weatherService.getWeatherByCity(city);
//     
//     // Only update map on successful fetch
//     _mapLocationNotifier.updateLocation(
//       weather.current.latitude,
//       weather.current.longitude,
//     );
//     
//     setState(() => _weather = weather);
//   } catch (e) {
//     // Show error, but DON'T reset map
//     // User still sees the last successful location
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Failed to search: $e')),
//     );
//   }
// }
// ```

// ============================================================================
// PATTERN 4: Initialization Best Practices
// ============================================================================

// Note: This file contains example code snippets for documentation.
// The MapLocationNotifier import examples below are conceptual.

// ❌ DON'T: Initialize notifier with null
// Example (conceptual):
// class BadHomeScreen extends StatefulWidget {
//   @override
//   State<BadHomeScreen> createState() => _BadHomeScreenState();
// }
// class _BadHomeScreenState extends State<BadHomeScreen> {
//   late MapLocationNotifier _mapLocationNotifier; // Uninitialized!
// }

// ✅ DO: Initialize with default location in initState
// Example (best practice):
// Create the actual widget by copying the pattern from lib/screens/home_screen.dart

// ============================================================================
// PATTERN 5: Handling Widget Lifecycle
// ============================================================================
//
// When the widget is torn down or navigated away:
//
// 1. dispose() is called
// 2. _mapLocationNotifier.dispose() should be called (cleans up listeners)
// 3. MapPreviewWidget removes its listener
// 4. No memory leaks
//
// Example:
// ```dart
// @override
// void dispose() {
//   _mapLocationNotifier.dispose();
//   super.dispose();
// }
// ```

// ============================================================================
// PATTERN 6: Multiple Map Updates in Sequence
// ============================================================================
//
// If you need to update the map multiple times (e.g., loading different cities):
//
// ```dart
// Future<void> _loadWeatherSequence() async {
//   // Load NYC
//   var weather = await weatherService.getWeatherByCity('New York');
//   _mapLocationNotifier.updateLocation(weather.current.latitude, weather.current.longitude);
//   await Future.delayed(Duration(seconds: 2));
//   
//   // Load London
//   weather = await weatherService.getWeatherByCity('London');
//   _mapLocationNotifier.updateLocation(weather.current.latitude, weather.current.longitude);
//   
//   // Map will smoothly animate between locations
// }
// ```

// ============================================================================
// PATTERN 7: Coordinating with Full-Screen Map
// ============================================================================
//
// When opening MapScreen from HomeScreen, pass the current location:
//
// ```dart
// onPressed: () {
//   Navigator.of(context).push(
//     MaterialPageRoute(
//       builder: (context) => MapScreen(
//         settings: widget.settings,
//         initialCenter: _mapLocationNotifier.value,  // ← Current location
//       ),
//     ),
//   );
// }
// ```
//
// This ensures the full-screen map opens at the same location as the preview.

// ============================================================================
// PATTERN 8: Avoiding Common Mistakes
// ============================================================================

// ❌ MISTAKE 1: Forgetting to update notifier
// Future<void> _searchWeather(String city) async {
//   final weather = await weatherService.getWeatherByCity(city);
//   setState(() => _weather = weather);
//   // Forgot to call: _mapLocationNotifier.updateLocation(...)
//   // Result: Map doesn't move when city changes
// }

// ✅ CORRECT: Always update notifier
// Future<void> _searchWeather(String city) async {
//   final weather = await weatherService.getWeatherByCity(city);
//   _mapLocationNotifier.updateLocation(
//     weather.current.latitude,
//     weather.current.longitude,
//   );
//   setState(() => _weather = weather);
// }

// ❌ MISTAKE 2: Not disposing notifier
// class BadState extends State {
//   late MapLocationNotifier notifier;
//   @override
//   void initState() => notifier = MapLocationNotifier(const LatLng(0, 0));
//   // No dispose() = potential memory leak
// }

// ✅ CORRECT: Always dispose
// class GoodState extends State {
//   late MapLocationNotifier notifier;
//   @override
//   void initState() => notifier = MapLocationNotifier(const LatLng(0, 0));
//   @override
//   void dispose() {
//     notifier.dispose();
//     super.dispose();
//   }
// }

// ❌ MISTAKE 3: Passing null location
// _mapLocationNotifier = MapLocationNotifier(null);  // ← Error
// Result: Type mismatch, app crashes

// ✅ CORRECT: Use valid LatLng
// _mapLocationNotifier = MapLocationNotifier(const LatLng(0, 0));

// ============================================================================
// PATTERN 9: Testing the Integration
// ============================================================================
//
// Unit test for notifier:
// ```dart
// void main() {
//   test('MapLocationNotifier updates value', () {
//     final notifier = MapLocationNotifier(const LatLng(0, 0));
//     notifier.updateLocation(40.7128, -74.0060);
//     expect(notifier.value.latitude, 40.7128);
//     notifier.dispose();
//   });
// }
// ```
//
// Widget test for integration:
// ```dart
// testWidgets('HomeScreen updates map on search', (tester) async {
//   await tester.pumpWidget(const MyApp());
//   
//   // Enter search text
//   await tester.enterText(find.byType(TextField), 'New York');
//   await tester.tap(find.byIcon(Icons.search));
//   await tester.pumpAndSettle();
//   
//   // Verify map marker is present
//   expect(find.byIcon(Icons.location_pin), findsOneWidget);
// });
// ```

// ============================================================================
// PATTERN 10: Performance Optimization
// ============================================================================
//
// MapPreviewWidget uses ValueListenableBuilder, which:
// - Only rebuilds when location changes
// - Doesn't rebuild on every HomeScreen setState
// - Minimal overhead
//
// The widget is already optimized. No additional optimization needed
// unless you have 100+ map updates per second (unlikely).

// ============================================================================
// SUMMARY: Checklist
// ============================================================================
//
// Before deploying:
// □ MapLocationNotifier created in initState
// □ notifier.dispose() called in dispose()
// □ updateLocation() called whenever lat/lon changes
// □ MapPreviewWidget receives locationNotifier
// □ All imports are present
// □ No null safety warnings
// □ Map updates on search/location change
// □ Full-screen map receives initialCenter from notifier.value
// □ Error handling doesn't interfere with map state
// □ No memory leaks (test with DevTools)

// ============================================================================

// End of best practices guide.
