# Quick Reference Guide - Interactive Map Preview

## 🚀 5-Minute Setup

### Step 1: Initialize in HomeScreen
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

### Step 2: Update on Location Change
```dart
Future<void> _loadWeather() async {
  final weather = await widget.weatherService.getCurrentLocationWeather();
  
  // This is the magic line
  _mapLocationNotifier.updateLocation(
    weather.current.latitude,
    weather.current.longitude,
  );
}

Future<void> _searchWeather(String city) async {
  final weather = await widget.weatherService.getWeatherByCity(city);
  
  // Same magic line - map updates instantly
  _mapLocationNotifier.updateLocation(
    weather.current.latitude,
    weather.current.longitude,
  );
}
```

### Step 3: Add to UI
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        // Your search bar and header...
        
        // Add this single widget
        MapPreviewWidget(
          locationNotifier: _mapLocationNotifier,
          height: 200,
          initialZoom: 13,
        ),
        
        // Your weather cards...
      ],
    ),
  );
}
```

**Done!** Your map now:
- ✅ Updates on search
- ✅ Allows zoom/pan
- ✅ Shows coordinates
- ✅ Has zoom controls
- ✅ Includes attribution

---

## 📚 File Reference

| File | Purpose | Lines |
|------|---------|-------|
| `lib/providers/map_location_notifier.dart` | State manager | 30 |
| `lib/widgets/map_preview_widget_interactive.dart` | Map widget | 200 |
| `lib/screens/home_screen.dart` | Integration | Updated |

---

## 🎮 Usage Examples

### Basic Setup
```dart
final notifier = MapLocationNotifier(const LatLng(0, 0));

MapPreviewWidget(
  locationNotifier: notifier,
)
```

### Update Location
```dart
notifier.updateLocation(40.7128, -74.0060);  // NYC
```

### With All Parameters
```dart
MapPreviewWidget(
  locationNotifier: notifier,
  height: 250,
  initialZoom: 15,
  onMapTap: () => print('Map tapped!'),
)
```

### Pass to Full-Screen Map
```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => MapScreen(
      settings: widget.settings,
      initialCenter: notifier.value,  // Use current location
    ),
  ),
);
```

---

## ⚠️ Common Mistakes

### ❌ Forget to Update Notifier
```dart
Future<void> _searchWeather(String city) async {
  final weather = await widget.weatherService.getWeatherByCity(city);
  setState(() => _weather = weather);
  // Map doesn't move! Forgot to call:
  // _mapLocationNotifier.updateLocation(...)
}
```

### ✅ Correct
```dart
Future<void> _searchWeather(String city) async {
  final weather = await widget.weatherService.getWeatherByCity(city);
  _mapLocationNotifier.updateLocation(
    weather.current.latitude,
    weather.current.longitude,
  );
  setState(() => _weather = weather);
}
```

### ❌ Forget to Dispose
```dart
@override
void dispose() {
  _searchController.dispose();
  // Missing: _mapLocationNotifier.dispose();
  super.dispose();
}
```

### ✅ Correct
```dart
@override
void dispose() {
  _searchController.dispose();
  _mapLocationNotifier.dispose();  // Always include
  super.dispose();
}
```

---

## 🔧 Customization

### Change Map Height
```dart
MapPreviewWidget(
  locationNotifier: notifier,
  height: 300,  // Default: 200
)
```

### Change Initial Zoom
```dart
MapPreviewWidget(
  locationNotifier: notifier,
  initialZoom: 15,  // Default: 13
)
```

### Add Tap Handler
```dart
MapPreviewWidget(
  locationNotifier: notifier,
  onMapTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => FullMapScreen()),
    );
  },
)
```

---

## 📱 Features at a Glance

| Feature | Enabled | How to Use |
|---------|---------|-----------|
| Zoom | ✅ Yes | Pinch gesture or +/- buttons |
| Pan | ✅ Yes | Drag with one finger |
| Rotate | ✅ Yes | Two-finger rotation |
| Marker | ✅ Yes | Auto-positioned at location |
| Attribution | ✅ Yes | Auto-displayed |
| Coordinates | ✅ Yes | Top-left corner |
| Zoom Level | ✅ Yes | Bottom-left corner |

---

## 🧪 Quick Test

### In Terminal
```bash
flutter run
```

### In App
1. Search for a city (e.g., "London")
2. Watch the map animate to that location
3. Pinch to zoom
4. Drag to pan
5. Tap [+] and [-] buttons for zoom

**Expected Result:** Smooth, responsive map that updates instantly with search

---

## 📊 Dependency Check

All required packages are already in `pubspec.yaml`:
```yaml
flutter_map: ^6.0.0      ✅
latlong2: ^0.9.0         ✅
geolocator: ^14.0.2      ✅
```

No new dependencies to add!

---

## 🐛 Troubleshooting

### Map Not Showing
→ Check `MapPreviewWidget` is in build() Column

### Map Not Updating on Search
→ Check `updateLocation()` is called after weather fetch

### Marker Not Visible
→ Check latitude/longitude values are valid (not 0/0)

### Memory Leak
→ Check `dispose()` calls `_mapLocationNotifier.dispose()`

---

## 📖 Full Documentation

- **Integration Guide:** `INTEGRATION_GUIDE.md`
- **Complete Docs:** `docs/INTERACTIVE_MAP_GUIDE.md`
- **Best Practices:** `docs/map_best_practices.dart`
- **Visual Guide:** `docs/VISUAL_GUIDE.md`
- **Delivery Summary:** `DELIVERY_SUMMARY.md`

---

## ✅ Verification Checklist

Before deployment:

```
□ MapLocationNotifier created in initState()
□ updateLocation() called on weather fetch
□ updateLocation() called on search
□ dispose() cleans up notifier
□ MapPreviewWidget in build() with notifier
□ No null safety warnings
□ Map updates on search (manual test)
□ Zoom/pan gestures work
□ No memory leaks (DevTools)
```

---

**Need Help?** See the full documentation files or check the code comments!
