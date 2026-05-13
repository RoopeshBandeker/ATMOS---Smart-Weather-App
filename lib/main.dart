import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/settings.dart';
import 'models/location_search_result.dart';
import 'models/weather.dart';
import 'models/air_quality.dart';
import 'models/uv.dart';
import 'services/weather_service.dart';
import 'services/cache_service.dart';
import 'services/geocoding_service.dart';
import 'services/settings_service.dart';
import 'screens/forecast_screen.dart';
import 'screens/home_screen.dart';
import 'screens/outlook_screen.dart';
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/component1.dart';
import 'widgets/app_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
      systemStatusBarContrastEnforced: false,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Global error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('Flutter Error: ${details.exception}');
  };

  runApp(const AtmosApp());
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Unable to Initialize App',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please restart the application or contact support.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AtmosApp extends StatefulWidget {
  final bool enableBackgroundRefresh;

  const AtmosApp({super.key, this.enableBackgroundRefresh = true});

  @override
  State<AtmosApp> createState() => _AtmosAppState();
}

class _AtmosAppState extends State<AtmosApp> {
  late CacheService _cacheService;
  late SettingsService _settingsService;
  late WeatherService _weatherService;
  late GeocodingService _geocodingService;
  late AppSettings _settings;
  bool _isInitialized = false;
  String? _initializationError;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      _cacheService = CacheService();
      _settingsService = SettingsService();

      await _cacheService.initialize();
      await _settingsService.initialize();

      _weatherService = WeatherService(_cacheService);
      _geocodingService = GeocodingService();
      _settings = _settingsService.getSettings();

      setState(() {
        _isInitialized = true;
        _initializationError = null;
      });
    } catch (e) {
      debugPrint('Initialization error: $e');
      setState(() {
        _isInitialized = true;
        _initializationError = e.toString();
      });
    }
  }

  void _onSettingsChanged(AppSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Atmos',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: _initializationError != null
          ? const ErrorApp()
          : _isInitialized
          ? _AppShell(
              weatherService: _weatherService,
              cacheService: _cacheService,
              settingsService: _settingsService,
              geocodingService: _geocodingService,
              settings: _settings,
              onSettingsChanged: _onSettingsChanged,
              enableBackgroundRefresh: widget.enableBackgroundRefresh,
            )
          : const Scaffold(body: Center(child: CircularProgressIndicator())),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _AppShell extends StatefulWidget {
  final WeatherService weatherService;
  final CacheService cacheService;
  final SettingsService settingsService;
  final GeocodingService geocodingService;
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;
  final bool enableBackgroundRefresh;

  const _AppShell({
    required this.weatherService,
    required this.cacheService,
    required this.settingsService,
    required this.geocodingService,
    required this.settings,
    required this.onSettingsChanged,
    required this.enableBackgroundRefresh,
  });

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<OutlookScreenState> _outlookKey =
      GlobalKey<OutlookScreenState>();
  final ValueNotifier<WeatherData?> _weatherDataNotifier =
      ValueNotifier<WeatherData?>(null);
  final ValueNotifier<AirQualityIndex?> _aqiNotifier =
      ValueNotifier<AirQualityIndex?>(null);
  final ValueNotifier<UvIndex?> _uvNotifier = ValueNotifier<UvIndex?>(null);
  int _selectedTab = 0;

  int get _stackIndex {
    switch (_selectedTab) {
      case 0:
        return 0;
      case 1:
        return 1;
      case 3:
        return 2;
      case 4:
        return 3;
      default:
        return 0;
    }
  }

  Future<void> _onNavTap(int index) async {
    if (index == 2) {
      final result = await Navigator.of(context).push<LocationSearchResult>(
        MaterialPageRoute(
          builder: (context) => SearchScreen(
            geocodingService: widget.geocodingService,
            weatherNotifier: _weatherDataNotifier,
          ),
        ),
      );

      if (!mounted || result == null) {
        return;
      }

      await _homeKey.currentState?.searchLocation(result);
      await _outlookKey.currentState?.refreshForLocation(result);
      return;
    }

    setState(() {
      _selectedTab = index;
    });

    if (index == 3) {
      _outlookKey.currentState?.refreshWeather();
    }
  }

  @override
  void dispose() {
    _weatherDataNotifier.dispose();
    _aqiNotifier.dispose();
    _uvNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<WeatherData?>(
      valueListenable: _weatherDataNotifier,
      builder: (context, weather, _) {
        return AppBackground(
          weather: weather,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            extendBody: true,
            body: IndexedStack(
              index: _stackIndex,
              children: [
                HomeScreen(
                  key: _homeKey,
                  weatherService: widget.weatherService,
                  onSettingsPressed: () {
                    setState(() {
                      _selectedTab = 4;
                    });
                  },
                  settings: widget.settings,
                  cacheService: widget.cacheService,
                  weatherNotifier: _weatherDataNotifier,
                  aqiNotifier: _aqiNotifier,
                  uvNotifier: _uvNotifier,
                  enableAutoLoad: widget.enableBackgroundRefresh,
                ),
                ForecastScreen(
                  weatherNotifier: _weatherDataNotifier,
                  aqiNotifier: _aqiNotifier,
                  uvNotifier: _uvNotifier,
                  settings: widget.settings,
                ),
                OutlookScreen(
                  key: _outlookKey,
                  weatherService: widget.weatherService,
                  cacheService: widget.cacheService,
                  settings: widget.settings,
                  enableAutoLoad: false,
                ),
                SettingsScreen(
                  initialSettings: widget.settings,
                  onSettingsChanged: widget.onSettingsChanged,
                  settingsService: widget.settingsService,
                  weatherNotifier: _weatherDataNotifier,
                  showDoneButton: false,
                ),
              ],
            ),
            bottomNavigationBar: Component1(
              selectedIndex: _selectedTab,
              onItemTapped: _onNavTap,
            ),
          ),
        );
      },
    );
  }
}
