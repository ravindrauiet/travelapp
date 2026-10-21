import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:metromate/providers/bus_provider.dart';
import 'package:metromate/providers/location_provider.dart';
import 'package:metromate/screens/bus/bus_journey_detail_screen.dart';
import 'package:metromate/screens/bus/bus_route_detail_screen.dart';
import 'package:metromate/screens/bus/bus_stop_detail_screen.dart';
import 'package:metromate/screens/bus/bus_ui.dart';
import 'package:metromate/screens/bus/professional_bus_home_screen.dart';
import 'package:metromate/screens/bus/route_finder_screen.dart';
import 'package:metromate/screens/bus/stop_locator_screen.dart';
import 'package:metromate/services/bus_network_service.dart';
import 'package:metromate/utils/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final net = BusNetworkService.instance;

  // Runs before the network is loaded (group order is declaration order).
  group('loading', () {
    test('reports an error when loading fails, then recovers on retry', () async {
      var fail = true;
      final bus = BusProvider(loader: () async {
        if (fail) throw StateError('asset missing');
      });
      expect(bus.isLoading, isTrue);
      await bus.ensureLoaded();
      expect(bus.hasError, isTrue);
      expect(bus.error, isNotNull);

      fail = false;
      final notified = Completer<void>();
      bus.addListener(() {
        if (!notified.isCompleted) notified.complete();
      });
      await bus.ensureLoaded();
      await notified.future;
      expect(bus.hasError, isFalse);
      expect(bus.status, BusDataStatus.ready);
    });
  });

  group('with network', () {
    setUpAll(() {
      final raw = File(BusNetworkService.assetPath).readAsStringSync();
      net.loadFromJson(jsonDecode(raw) as Map<String, dynamic>);
    });

    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('is ready immediately once the network is loaded', () async {
      final bus = BusProvider();
      await bus.ensureLoaded();
      expect(bus.isReady, isTrue);
      expect(bus.routeCount, greaterThan(1000));
      expect(bus.stopCount, greaterThan(6000));
      expect(bus.dailyTrips, greaterThan(50000));
      expect(bus.routeCountForAgency('DTC') + bus.routeCountForAgency('DIMTS'), greaterThanOrEqualTo(bus.routeCount));
    });

    test('popular routes are real route numbers, busiest first', () {
      final bus = BusProvider();
      final popular = bus.popularRoutes(limit: 8);
      expect(popular, hasLength(8));
      for (var i = 1; i < popular.length; i++) {
        expect(popular[i].dailyTrips, lessThanOrEqualTo(popular[i - 1].dailyTrips));
      }
      for (final r in popular) {
        expect(net.linesByNumber(r.number), isNotEmpty);
        expect(r.termini, contains('→'));
      }
    });

    test('search finds both route numbers and stops', () {
      final bus = BusProvider();
      final byNumber = bus.search('534');
      expect(byNumber.routes.map((r) => r.number), contains('534'));

      final byName = bus.search('kashmere');
      expect(byName.places, isNotEmpty);
      expect(byName.places.first.name.toLowerCase(), contains('kashmere'));

      expect(bus.search('   ').isEmpty, isTrue);
      expect(bus.search('zzzzqqq').isEmpty, isTrue);
    });

    test('resolvePlace matches exact names and falls back to best hit', () {
      final bus = BusProvider();
      final place = bus.suggestPlaces('nehru place').first;
      expect(bus.resolvePlace(place.name), same(place));
      expect(bus.resolvePlace(place.name.toUpperCase()), same(place));
      expect(bus.resolvePlace('nehru pl'), isNotNull);
      expect(bus.resolvePlace(''), isNull);
      expect(bus.resolvePlace('zzzzqqq'), isNull);
    });

    test('route numbers at a place are distinct', () {
      final bus = BusProvider();
      final place = bus.suggestPlaces('kashmere gate').first;
      final numbers = bus.routeNumbersAt(place);
      expect(numbers, isNotEmpty);
      expect(numbers.toSet(), hasLength(numbers.length));
      expect(bus.routeCountAt(place), numbers.length);
    });

    test('busiest places are ordered by routes served', () {
      final bus = BusProvider();
      final busiest = bus.busiestPlaces(limit: 5);
      expect(busiest, hasLength(5));
      for (var i = 1; i < busiest.length; i++) {
        expect(bus.routeCountAt(busiest[i]), lessThanOrEqualTo(bus.routeCountAt(busiest[i - 1])));
      }
    });

    test('nearby stops are one per place, closest first, with walk times', () {
      final bus = BusProvider();
      final near = bus.nearbyStops(28.6315, 77.2167, limit: 8); // Connaught Place
      expect(near, isNotEmpty);
      expect(near.map((n) => n.place).toSet(), hasLength(near.length));
      for (var i = 1; i < near.length; i++) {
        expect(near[i].distanceKm, greaterThanOrEqualTo(near[i - 1].distanceKm));
      }
      expect(near.first.walkMinutes, greaterThanOrEqualTo(1));
      expect(BusProvider.walkMinutes(0.8), 10);
      expect(bus.nearbyStops(19.07, 72.87), isEmpty); // Mumbai
    });

    test('directions list UP before DOWN', () {
      final bus = BusProvider();
      final dirs = bus.directionsOf(net.lineById(0)!); // 764M DOWN
      expect(dirs.length, greaterThanOrEqualTo(2));
      expect(dirs.first.direction, startsWith('UP'));
      expect(dirs.map((l) => l.number).toSet(), {'764M'});
    });

    test('findJourneys returns journeys between busy places', () async {
      final bus = BusProvider();
      final from = bus.resolvePlace('kashmere gate')!;
      final to = bus.resolvePlace('nehru place')!;
      final journeys = await bus.findJourneys(from, to);
      expect(journeys, isNotEmpty);
    });

    test('recent searches are de-duplicated, capped and persisted', () async {
      final bus = BusProvider();
      await bus.loadRecentSearches();
      expect(bus.recentSearches, isEmpty);
      for (var i = 0; i < 8; i++) {
        await bus.addRecentSearch('A$i', 'B$i');
      }
      expect(bus.recentSearches, hasLength(BusProvider.maxRecentSearches));
      expect(bus.recentSearches.first, const BusRecentSearch('A7', 'B7'));

      await bus.addRecentSearch('A3', 'B3');
      expect(bus.recentSearches.first, const BusRecentSearch('A3', 'B3'));
      expect(bus.recentSearches.where((r) => r.from == 'A3'), hasLength(1));

      final reloaded = BusProvider();
      await reloaded.loadRecentSearches();
      expect(reloaded.recentSearches, bus.recentSearches);

      await reloaded.removeRecentSearch(const BusRecentSearch('A3', 'B3'));
      expect(reloaded.recentSearches.contains(const BusRecentSearch('A3', 'B3')), isFalse);
      await reloaded.clearRecentSearches();
      expect(reloaded.recentSearches, isEmpty);
    });

    test('live bus count sums all directions and degrades to null', () async {
      final asked = <String>[];
      final ok = BusProvider(liveVehicleFetcher: (id) async {
        asked.add(id);
        return [Object(), Object()];
      });
      final lines = net.linesByNumber('764M');
      expect(await ok.liveBusCount('764M'), 2 * lines.length);
      expect(asked.toSet(), lines.map((l) => '${l.id}').toSet());

      final failing = BusProvider(liveVehicleFetcher: (_) async => throw Exception('CORS'));
      expect(await failing.liveBusCount('764M'), isNull);

      final slow = BusProvider(liveVehicleFetcher: (_) => Completer<List<Object>>().future);
      expect(await slow.liveBusCount('764M', timeout: const Duration(milliseconds: 20)), isNull);

      expect(await ok.liveBusCount('NO-SUCH-ROUTE'), isNull);
    });

    test('recognises the LocationProvider fallback position', () {
      Position at(double lat, double lon, double acc) => Position(
            latitude: lat,
            longitude: lon,
            timestamp: DateTime(2026),
            accuracy: acc,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
      expect(BusProvider.isFallbackPosition(at(28.6139, 77.2090, 0)), isTrue);
      expect(BusProvider.isFallbackPosition(at(28.6139, 77.2090, 12)), isFalse);
      expect(BusProvider.isFallbackPosition(at(28.70, 77.10, 0)), isFalse);
    });

    testWidgets('route finder: autocomplete, pick stops, show journeys', (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => BusProvider()),
          ChangeNotifierProvider(create: (_) => LocationProvider()),
        ],
        child: MaterialApp(theme: AppTheme.lightTheme, home: const BusRouteFinderScreen()),
      ));
      await tester.pump();

      await tester.enterText(find.byKey(const ValueKey('bus-from')), 'kashmere gate');
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('PICK STARTING STOP'), findsOneWidget);
      final from = BusNetworkService.instance.searchPlaces('kashmere gate').first;
      await tester.tap(find.text(from.name).last);
      await tester.pump();

      await tester.enterText(find.byKey(const ValueKey('bus-to')), 'nehru place');
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('PICK DESTINATION STOP'), findsOneWidget);
      final to = BusNetworkService.instance.searchPlaces('nehru place').first;
      await tester.tap(find.text(to.name).last);
      await tester.pump(); // starts search
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();

      expect(find.textContaining('bus option'), findsOneWidget);
      expect(find.text('Women ride free (pink ticket)'), findsWidgets);
    });

    Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
      await tester.binding.setSurfaceSize(const Size(400, 2400)); // phone (test font is wider than Jakarta)
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => BusProvider()),
          ChangeNotifierProvider(create: (_) => LocationProvider()),
        ],
        child: MaterialApp(theme: AppTheme.lightTheme, home: screen),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('journey detail renders legs with board/alight markers', (tester) async {
      final from = net.searchPlaces('kashmere gate').first;
      final to = net.searchPlaces('nehru place').first;
      final journey = net.findJourneys(from, to).first;
      await pumpScreen(tester, BusJourneyDetailScreen(journey: journey));
      expect(find.text('Board here'), findsWidgets);
      expect(find.text('Get off here'), findsWidgets);
      expect(find.textContaining('View route'), findsWidgets);
    });

    testWidgets('route detail shows timetable, directions and stops', (tester) async {
      final bus = BusProvider(liveVehicleFetcher: (_) async => throw Exception('offline'));
      await tester.binding.setSurfaceSize(const Size(400, 4000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: bus,
        child: MaterialApp(theme: AppTheme.lightTheme, home: const BusRouteDetailScreen(lineId: '0')),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Bus 764M'), findsOneWidget);
      expect(find.text('FIRST BUS'), findsOneWidget);
      expect(find.text('Live positions unavailable'), findsOneWidget);
      expect(find.text('Track 764M live'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsWidgets);
    });

    testWidgets('unknown route id shows a friendly empty state', (tester) async {
      await pumpScreen(tester, const BusRouteDetailScreen(lineId: 'nope'));
      expect(find.text('Route not found'), findsOneWidget);
    });

    testWidgets('stop detail lists departures and routes', (tester) async {
      final place = net.searchPlaces('kashmere gate').first;
      await pumpScreen(tester, BusStopDetailScreen(stopId: '${place.stops.first.id}'));
      expect(find.text(place.name), findsOneWidget);
      expect(find.text('Upcoming buses'), findsOneWidget);
      expect(find.text('Plan from here'), findsOneWidget);
      expect(find.byType(BusNumberChip), findsWidgets);
    });

    testWidgets('bus home shows real stats, popular routes and search', (tester) async {
      await pumpScreen(tester, const ProfessionalBusHomeScreen());
      final top = BusProvider().popularRoutes(limit: 1).first;
      expect(find.text(top.number), findsWidgets);
      await tester.enterText(find.byType(TextField).first, '534');
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('ROUTES'), findsOneWidget);
    });

    testWidgets('stop locator shows a clear state when location is off, and still searches', (tester) async {
      const channel = MethodChannel('flutter.baseflow.com/geolocator');
      final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'isLocationServiceEnabled') return false;
        return null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

      await pumpScreen(tester, const BusStopLocatorScreen());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Location is turned off'), findsOneWidget);
      expect(find.text('Location settings'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'nehru');
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(BusPlaceTile), findsWidgets);
    });
  });
}
