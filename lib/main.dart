import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import 'providers/location_provider.dart';
import 'providers/metro_provider.dart';
import 'providers/bus_provider.dart';
import 'providers/weather_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/professional_home_screen.dart';
import 'screens/metro/professional_metro_home_screen.dart';
import 'screens/metro/fare_calculator_screen.dart';
import 'screens/metro/route_finder_screen.dart';
import 'screens/metro/live_updates_screen.dart';
import 'screens/metro/metro_map_screen.dart';
import 'screens/metro/simple_pdf_viewer.dart';
import 'screens/bus/professional_bus_home_screen.dart';
import 'screens/bus/route_finder_screen.dart';
import 'screens/bus/stop_locator_screen.dart';
import 'screens/bus/bus_map_screen.dart';
import 'screens/bus/realtime_bus_tracker.dart';
import 'screens/bus/api_test_screen.dart';
import 'screens/transport/professional_transport_home_screen.dart';
import 'screens/city/enhanced_tourist_spots_screen.dart';
import 'screens/city/emergency_screen.dart';
import 'screens/city/professional_weather_screen.dart';
import 'screens/games/snake_game_screen.dart';
import 'screens/games/tetris_game_screen.dart';
import 'screens/games/game_2048_screen.dart';
import 'screens/games/flappy_bird_screen.dart';
import 'screens/games/memory_game_screen.dart';
import 'screens/games/games_menu_screen.dart';
import 'utils/app_theme.dart';
import 'widgets/app_scaffold.dart';

void main() {
  runApp(const MetromateApp());
}

class MetromateApp extends StatelessWidget {
  const MetromateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => MetroProvider()),
        ChangeNotifierProvider(create: (_) => BusProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: 'Metromate',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: _router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const ProfessionalHomeScreen().withAppScaffold(useCustomScaffold: true),
    ),
    GoRoute(
      path: '/metro',
      builder: (context, state) => const ProfessionalMetroHomeScreen().withAppScaffold(),
    ),
    GoRoute(
      path: '/metro/fare-calculator',
      builder: (context, state) => const MetroFareCalculatorScreen().withAppScaffold(),
    ),
    GoRoute(
      path: '/metro/route-finder',
      builder: (context, state) => const MetroRouteFinderScreen().withAppScaffold(),
    ),
    GoRoute(
      path: '/metro/live-updates',
      builder: (context, state) => const MetroLiveUpdatesScreen().withAppScaffold(),
    ),
    GoRoute(
      path: '/metro/map',
      builder: (context, state) => const MetroMapScreen().withAppScaffold(),
    ),
    GoRoute(
      path: '/metro/pdf-viewer',
      builder: (context, state) => const SimplePDFViewer(
        pdfPath: 'assets/pdf/Metro.pdf',
        title: 'Delhi Metro Map',
      ).withAppScaffold(),
    ),
    GoRoute(
      path: '/bus',
      builder: (context, state) => const ProfessionalBusHomeScreen().withAppScaffold(),
    ),
    GoRoute(
      path: '/bus/route-finder',
      builder: (context, state) => const BusRouteFinderScreen().withAppScaffold(),
    ),
    GoRoute(
      path: '/bus/stop-locator',
      builder: (context, state) => const BusStopLocatorScreen().withAppScaffold(),
    ),
    GoRoute(
      path: '/bus/map',
      builder: (context, state) => const BusMapScreen().withAppScaffold(),
    ),
    GoRoute(
      path: '/bus/realtime',
      builder: (context, state) => const RealtimeBusTracker().withAppScaffold(),
    ),
    GoRoute(
      path: '/bus/api-test',
      builder: (context, state) => const ApiTestScreen().withAppScaffold(),
    ),
    GoRoute(
      path: '/transport',
      builder: (context, state) => const ProfessionalTransportHomeScreen().withAppScaffold(),
    ),
    GoRoute(
      path: '/tourist-spots',
      builder: (context, state) => const EnhancedTouristSpotsScreen().withAppScaffold(),
    ),
    GoRoute(
      path: '/emergency',
      builder: (context, state) => const EmergencyScreen().withAppScaffold(),
    ),
    GoRoute(
      path: '/weather',
      builder: (context, state) => const ProfessionalWeatherScreen().withAppScaffold(),
    ),
    GoRoute(
      path: '/games',
      builder: (context, state) => const GamesMenuScreen().withAppScaffold(),
    ),
    GoRoute(
      path: '/games/snake',
      builder: (context, state) => const SnakeGameScreen().withAppScaffold(),
    ),
    GoRoute(
      path: '/games/tetris',
      builder: (context, state) => const TetrisGameScreen().withAppScaffold(),
    ),
    GoRoute(
      path: '/games/2048',
      builder: (context, state) => const Game2048Screen().withAppScaffold(),
    ),
    GoRoute(
      path: '/games/flappy-bird',
      builder: (context, state) => const FlappyBirdScreen().withAppScaffold(),
    ),
    GoRoute(
      path: '/games/memory',
      builder: (context, state) => const MemoryGameScreen().withAppScaffold(),
    ),
  ],
);
