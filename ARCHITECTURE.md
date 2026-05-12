# Atmos Weather App - Architecture Overview

## Project Structure

```
lib/
├── config/
│   └── api_key.dart              # OpenWeatherMap API key
├── models/
│   ├── weather.dart              # Weather data models
│   └── settings.dart             # App settings models
├── services/
│   ├── weather_service.dart      # Weather API service with caching
│   ├── cache_service.dart        # Local caching service
│   └── settings_service.dart     # Settings persistence service
├── screens/
│   ├── home_screen.dart          # Main weather display
│   └── settings_screen.dart      # Settings/preferences screen
├── widgets/
│   └── weather_widgets.dart      # Reusable weather UI components
├── utils/
│   ├── weather_icons.dart        # Weather condition icons and colors
│   └── converters.dart           # Unit conversion utilities
└── main.dart                     # App entry point
```

## Key Features Implemented

### 1. **Current Weather**
- Real-time temperature display
- "Feels like" temperature
- Weather condition and icon
- Pressure, wind speed, wind direction
- Sunrise and sunset times
- Humidity percentage
- Cloud coverage percentage
- Location name

### 2. **5-Day Forecast**
- 3-hour interval forecast data
- Temperature display with unit conversion
- Weather icons for each forecast period
- Horizontal scrolling list
- Day-based forecast grouping

### 3. **Location Services**
- Automatic geolocation detection using Geolocator
- Manual city search functionality
- Permission handling
- Last searched location persistence

### 4. **Caching & Rate Limiting**
- 15-minute cache duration per location
- Cached data stored locally as JSON via SharedPreferences
- Cache validity check automatically
- 30-second cooldown between manual refreshes
- HTTP 429 error handling
- Timestamp tracking for cache invalidation

### 5. **Settings**
- Temperature unit conversion: Celsius / Fahrenheit
- Wind speed units: m/s, km/h, mph, knots
- Pressure units: hPa, mbar, mmHg, inHg
- Settings persistence across sessions
- Real-time unit conversion application

### 6. **Theme System**
- Automatic light/dark theme based on system settings
- Dynamic gradient backgrounds based on weather condition
- Night/day detection from weather icon code
- Color-coded weather conditions

### 7. **Error Handling**
- Network connectivity checks
- Invalid city name handling
- API rate limit error handling
- Loading states with indicators
- User-friendly error messages
- Retry functionality

### 8. **UI/UX**
- Minimalist design with rounded cards
- Large temperature display at top
- Weather condition icon display
- Info cards for quick stats
- Horizontal scrolling forecast
- Clean typography and spacing
- Safe area padding and proper alignment
- Bounce physics for scrolling

## Services Architecture

### WeatherService
- Fetch weather by city name
- Fetch weather by coordinates
- Auto-detect current location
- Integrated caching
- Rate limiting enforcement
- Forecast data retrieval

### CacheService
- Store/retrieve cached weather data
- Duration validation (15 minutes)
- Refresh cooldown tracking (30 seconds)
- Last location persistence
- Cache clearing functionality

### SettingsService
- Load/save user preferences
- Settings serialization
- Persistent storage via SharedPreferences

## Data Models

### CurrentWeather
- Location name, coordinates
- Temperature, feels-like, humidity
- Wind speed and direction
- Pressure, visibility, cloudiness
- Sunrise/sunset times
- UV index
- Weather condition and icon

### ForecastItem
- Date/time
- Temperature (min/max)
- Weather condition
- Humidity, wind speed, pressure

### Forecast
- List of forecast items

### WeatherData
- Current weather + forecast
- Fetch timestamp
- Cache validation method
- JSON serialization

### AppSettings
- Temperature unit preference
- Wind speed unit preference
- Pressure unit preference
- JSON serialization

## Unit Conversion

- Celsius ↔ Fahrenheit
- m/s ↔ km/h, mph, knots
- hPa ↔ mbar, mmHg, inHg

## API Integration

### OpenWeatherMap APIs Used
- **Current Weather**: `/data/2.5/weather`
- **Forecast**: `/data/2.5/forecast`

### API Features
- Metric units
- JSON responses
- Error code handling
- Rate limit headers

## Dependencies

- `flutter` - UI framework
- `http` - HTTP requests
- `geolocator` - Location services
- `google_maps_flutter` - Map integration
- `shared_preferences` - Local storage
- `intl` - Date/time formatting
- `cupertino_icons` - iOS icons

## State Management

Simple stateful widgets with:
- Local state management
- Provider-free architecture
- Direct service injection
- Context-based navigation

## Error Handling Strategy

1. **Network Errors**: Display error message with retry button
2. **Invalid City**: Show "City not found" message
3. **API Errors**: Handle HTTP status codes (404, 429, 5xx)
4. **Cache**: Fall back to cached data when available
5. **Location**: Request permissions with graceful fallback
6. **Rate Limiting**: Enforce 30-second cooldown between refreshes

## Security

- API key stored in dedicated config file
- Sensitive endpoints accessed via HTTPS
- Permission requests follow Android/iOS guidelines

## Performance Optimizations

- 15-minute cache reduces API calls
- 30-second refresh cooldown prevents throttling
- Efficient JSON serialization
- Lazy loading of forecast items
- Horizontal scroll for forecast (minimal layout)

## Future Enhancement Possibilities

- Multi-location tracking
- Weather alerts and notifications
- Detailed hourly forecast
- Moon phase information
- UV index display
- Air quality index
- Historical weather data
- Weather comparison between locations
