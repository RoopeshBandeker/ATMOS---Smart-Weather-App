# Interactive Map Preview - Implementation Guide

## Overview

A fully interactive OpenStreetMap preview card integrated into HomeScreen with automatic updates when users search for new cities. Built with clean architecture using `ValueNotifier` for lightweight state management.

## Architecture

### File Structure
```
lib/
├── providers/
│   └── map_location_notifier.dart      # Lightweight state holder
├── widgets/
│   └── map_preview_widget_interactive.dart  # Interactive map widget
└── screens/
    └── home_screen.dart                # Integration point
```

### Dependencies
```yaml
dependencies:
  flutter_map: ^6.0.0      # OpenStreetMap rendering
  latlong2: ^0.9.0         # Location coordinate types
```

## Components

### 1. MapLocationNotifier
**Purpose:** Manages location state with automatic listener notification

**File:** `lib/providers/map_location_notifier.dart`

```dart
class MapLocationNotifier extends ValueNotifier<LatLng> {
  MapLocationNotifier(LatLng initialLocation) : super(initialLocation);
  
  void updateLocation(double latitude, double longitude) {
    value = LatLng(latitude, longitude);
  }
}
```

**Key Features:**
- Extends `ValueNotifier<LatLng>` for reactive updates
- Zero configuration
- Automatic listener notification on location change
- Proper memory cleanup with `dispose()`

### 2. MapPreviewWidget
**Purpose:** Render interactive map with automatic animation on location changes

**File:** `lib/widgets/map_preview_widget_interactive.dart`

**Parameters:**
```dart
MapPreviewWidget(
  locationNotifier: MapLocationNotifier,  // Required: state notifier
  height: double = 200,                    // Card height in pixels
  initialZoom: double = 13,                // Initial zoom level
  onMapTap: VoidCallback?,                 // Optional tap callback
)
```

**Features:**
- ✅ Full interactivity: zoom (pinch), pan (drag)
- ✅ Zoom controls: [+] and [-] buttons
- ✅ Auto-animation: smooth camera movement on location change
- ✅ Marker tracking: red pin at current location
- ✅ Attribution: "© OpenStreetMap contributors"
- ✅ Info overlay: coordinates and zoom level display
- ✅ Responsive: rebuilds only on location changes

**Implementation Details:**
```dart
ValueListenableBuilder<LatLng>(
  valueListenable: locationNotifier,
  builder: (context, location, _) {
    // Map rebuilds here when location changes
    // Camera animates to new coordinates
    // Marker updates position
    // Info displays update
  },
)
```

## Integration Steps

### Step 1: Create Notifier in HomeScreen
```dart
class _HomeScreenState extends State<HomeScreen> {
  late MapLocationNotifier _mapLocationNotifier;

  @override
  void initState() {
    super.initState();
    _mapLocationNotifier = MapLocationNotifier(const LatLng(0, 0));
  }

  @override
  void dispose() {
    _mapLocationNotifier.dispose();
    super.dispose();
  }
```

### Step 2: Update Map on Location Change
```dart
Future<void> _loadWeather() async {
  final weather = await widget.weatherService.getCurrentLocationWeather();
  
  // Update map automatically
  _mapLocationNotifier.updateLocation(
    weather.current.latitude,
    weather.current.longitude,
  );
  
  setState(() => _weather = weather);
}

Future<void> _searchWeather(String city) async {
  final weather = await widget.weatherService.getWeatherByCity(city);
  
  // Map updates instantly when search results arrive
  _mapLocationNotifier.updateLocation(
    weather.current.latitude,
    weather.current.longitude,
  );
  
  setState(() => _weather = weather);
}
```

### Step 3: Add Widget to UI
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        _buildSearchBar(),
        
        // Interactive map preview
        MapPreviewWidget(
          locationNotifier: _mapLocationNotifier,
          height: 200,
          initialZoom: 13,
        ),
        
        CurrentWeatherCard(weather: _weather?.current),
      ],
    ),
  );
}
```

## State Flow Diagram

```
┌─────────────────────────────────────────────────────────┐
│ User Interaction (Search / Location Change)              │
└──────────────────────┬──────────────────────────────────┘
                       ↓
        ┌──────────────────────────────┐
        │ _searchWeather(city)          │
        │ _loadWeather()                │
        └──────────────┬────────────────┘
                       ↓
        ┌──────────────────────────────┐
        │ Fetch from:                   │
        │ - WeatherService              │
        │ - OpenWeatherMap API          │
        └──────────────┬────────────────┘
                       ↓
        ┌──────────────────────────────────────┐
        │ Update: _mapLocationNotifier.value     │
        │ (triggers ValueNotifier listeners)     │
        └──────────────┬──────────────────────┘
                       ↓
        ┌──────────────────────────────────────┐
        │ MapPreviewWidget                     │
        │ (ValueListenableBuilder detects      │
        │  change and rebuilds)                │
        └──────────────┬──────────────────────┘
                       ↓
        ┌──────────────────────────────────────┐
        │ Actions:                             │
        │ 1. Animate map to new location       │
        │ 2. Update marker position            │
        │ 3. Refresh coordinate display        │
        │ 4. Sync with zoom level              │
        └──────────────────────────────────────┘
```

## Customization Examples

### Example 1: Custom Zoom on Search
```dart
Future<void> _searchWeather(String city) async {
  final weather = await widget.weatherService.getWeatherByCity(city);
  
  // Update location and zoom in when searching
  _mapLocationNotifier.updateLocation(
    weather.current.latitude,
    weather.current.longitude,
  );
  
  // Note: If you need custom zoom, extend MapLocationNotifier
  // to track zoom level separately
}
```

### Example 2: Manual Map Control
```dart
// From HomeScreen, you can open full-screen map
// while preserving current location
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => MapScreen(
      settings: widget.settings,
      initialCenter: _mapLocationNotifier.value,  // Use current location
    ),
  ),
);
```

### Example 3: Add Download/Share Button
```dart
FloatingActionButton(
  onPressed: () {
    final location = _mapLocationNotifier.value;
    // Share location...
    Share.share('lat=${location.latitude}, lon=${location.longitude}');
  },
  child: const Icon(Icons.share),
)
```

## Best Practices

### 1. Always Clean Up
```dart
@override
void dispose() {
  _mapLocationNotifier.dispose();  // IMPORTANT
  super.dispose();
}
```

### 2. Initialize with Safe Default
```dart
// Don't use null, use a valid LatLng
_mapLocationNotifier = MapLocationNotifier(const LatLng(0, 0));
```

### 3. Update on Every Location Change
```dart
// Call this whenever lat/lon changes:
_mapLocationNotifier.updateLocation(lat, lon);

// Don't manually update map controllers unless needed
```

### 4. Keep State Logic Minimal
```dart
// Good: Update notifier, let MapPreviewWidget handle rendering
_mapLocationNotifier.updateLocation(wea.current.latitude, wea.current.longitude);

// Avoid: Multiple setState calls for map state
// setState(() { _mapLat = ...; _mapLon = ...; });
```

## Testing

### Unit Test Example
```dart
test('MapLocationNotifier updates value', () {
  final notifier = MapLocationNotifier(const LatLng(0, 0));
  
  notifier.updateLocation(40.7128, -74.0060);
  
  expect(notifier.value.latitude, 40.7128);
  expect(notifier.value.longitude, -74.0060);
  
  notifier.dispose();
});
```

### Widget Test Example
```dart
testWidgets('MapPreviewWidget updates on notifier change', (tester) async {
  final notifier = MapLocationNotifier(const LatLng(0, 0));
  
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MapPreviewWidget(locationNotifier: notifier),
      ),
    ),
  );
  
  // Update location
  notifier.updateLocation(40.7128, -74.0060);
  await tester.pumpAndSettle();
  
  // Verify marker moved
  expect(find.byIcon(Icons.location_pin), findsOneWidget);
]);
```

## Performance Considerations

### Listener Registration
- `ValueListenableBuilder` automatically listens/unlistens
- No manual `addListener` needed for UI updates
- Minimal overhead from `ValueNotifier`

### Rebuild Scope
- Only `MapPreviewWidget` rebuilds on location change
- Parent widgets remain unaffected
- No full-screen rebuild

### Memory
- `dispose()` cleans up resources
- No memory leaks from listeners
- Standard Flutter lifecycle

## Troubleshooting

### Map Not Updating
**Symptom:** Searching for a city doesn't move the map
```dart
// Verify updateLocation is called:
_mapLocationNotifier.updateLocation(
  weather.current.latitude,
  weather.current.longitude,
);
```

### Animation Lag
**Symptom:** Map animation is choppy
- Check device performance
- Reduce UI complexity
- Use `InteractiveFlag.all` if gestures are slow

### Marker Not Showing
**Symptom:** Red pin doesn't appear on map
```dart
// Ensure latest location is being used
Marker(
  point: location,  // This should be the notifier's value
  child: const Icon(Icons.location_pin, color: Colors.red),
)
```

## Related Files

- **HomeScreen:** `lib/screens/home_screen.dart` - Integration point
- **WeatherService:** `lib/services/weather_service.dart` - Data source
- **MapScreen:** `lib/screens/map_screen.dart` - Full-screen map version
- **OpenWeatherMap API:** Weather and location source

## License & Attribution

- **flutter_map:** BSD License
- **OpenStreetMap:** ODbL License
- **Attribution required:** "© OpenStreetMap contributors" (included in widget)

---

**Last Updated:** March 2, 2026
