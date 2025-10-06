import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import 'providers/location_provider.dart';
import 'providers/metro_provider.dart';
import 'providers/bus_provider.dart';
import 'providers/weather_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/metro/metro_home_screen.dart';
import 'screens/metro/fare_calculator_screen.dart';
import 'screens/metro/route_finder_screen.dart';
import 'screens/metro/live_updates_screen.dart';
import 'screens/metro/metro_map_screen.dart';
import 'screens/bus/bus_home_screen.dart';
import 'screens/bus/route_finder_screen.dart';
import 'screens/bus/stop_locator_screen.dart';
import 'screens/bus/bus_map_screen.dart';
import 'screens/bus/realtime_bus_tracker.dart';
import 'screens/bus/api_test_screen.dart';
import 'screens/transport/transport_home_screen.dart';
import 'screens/city/tourist_spots_screen.dart';
import 'screens/city/emergency_screen.dart';
import 'screens/city/weather_screen.dart';
import 'screens/games/snake_game_screen.dart';
import 'screens/games/tetris_game_screen.dart';
import 'screens/games/games_menu_screen.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const DelhiTravelApp());
}

class DelhiTravelApp extends StatelessWidget {
  const DelhiTravelApp({super.key});

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
            title: 'DelhiGo',
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
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/metro',
      builder: (context, state) => const MetroHomeScreen(),
    ),
    GoRoute(
      path: '/metro/fare-calculator',
      builder: (context, state) => const MetroFareCalculatorScreen(),
    ),
    GoRoute(
      path: '/metro/route-finder',
      builder: (context, state) => const MetroRouteFinderScreen(),
    ),
    GoRoute(
      path: '/metro/live-updates',
      builder: (context, state) => const MetroLiveUpdatesScreen(),
    ),
    GoRoute(
      path: '/metro/map',
      builder: (context, state) => const MetroMapScreen(),
    ),
    GoRoute(
      path: '/bus',
      builder: (context, state) => const BusHomeScreen(),
    ),
    GoRoute(
      path: '/bus/route-finder',
      builder: (context, state) => const BusRouteFinderScreen(),
    ),
    GoRoute(
      path: '/bus/stop-locator',
      builder: (context, state) => const BusStopLocatorScreen(),
    ),
    GoRoute(
      path: '/bus/map',
      builder: (context, state) => const BusMapScreen(),
    ),
    GoRoute(
      path: '/bus/realtime',
      builder: (context, state) => const RealtimeBusTracker(),
    ),
    GoRoute(
      path: '/bus/api-test',
      builder: (context, state) => const ApiTestScreen(),
    ),
    GoRoute(
      path: '/transport',
      builder: (context, state) => const TransportHomeScreen(),
    ),
    GoRoute(
      path: '/tourist-spots',
      builder: (context, state) => const TouristSpotsScreen(),
    ),
    GoRoute(
      path: '/emergency',
      builder: (context, state) => const EmergencyScreen(),
    ),
    GoRoute(
      path: '/weather',
      builder: (context, state) => const WeatherScreen(),
    ),
    GoRoute(
      path: '/games',
      builder: (context, state) => const GamesMenuScreen(),
    ),
    GoRoute(
      path: '/games/snake',
      builder: (context, state) => const SnakeGameScreen(),
    ),
    GoRoute(
      path: '/games/tetris',
      builder: (context, state) => const TetrisGameScreen(),
    ),
  ],
);
