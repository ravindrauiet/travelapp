import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:metromate/main.dart';
import 'package:metromate/services/bus_network_service.dart';
import 'package:metromate/services/gtfs_graph_service.dart';

/// End-to-end-ish UI flows on a phone-sized surface. Any RenderFlex overflow
/// or uncaught exception while a screen is shown fails the test.
void main() {
  final net = BusNetworkService.instance;

  setUpAll(() async {
    // Real app font so text metrics match the device (the default test font is much wider).
    final jakarta = FontLoader('Jakarta');
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
      final bytes = File('assets/fonts/PlusJakartaSans-$w.ttf').readAsBytesSync();
      jakarta.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await jakarta.load();
    net.loadFromJson(
      jsonDecode(File(BusNetworkService.assetPath).readAsStringSync()) as Map<String, dynamic>,
    );
    GTFSGraphService.assetLoader = (path) => File(path).readAsString();
    await GTFSGraphService.getStations();
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> settle(WidgetTester tester, [int frames = 12]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  Future<void> launch(WidgetTester tester, {double textScale = 1.0, Size size = const Size(360, 760)}) async {
    tester.view.physicalSize = Size(size.width * 3, size.height * 3);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const MetromateApp());
    await tester.pump(const Duration(seconds: 3));
    await settle(tester, 8);
  }

  GoRouter router(WidgetTester tester) => GoRouter.of(tester.element(find.byType(Navigator).first));

  Future<void> goTo(WidgetTester tester, String location, {int frames = 16}) async {
    router(tester).go(location);
    await settle(tester, frames);
  }

  Future<void> tearDownApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  }

  testWidgets('home loads and every bottom-nav tab opens', (tester) async {
    await launch(tester);
    await goTo(tester, '/');
    expect(find.text('Travel your way'), findsOneWidget);

    for (final label in ['Metro', 'Bus', 'Transport', 'Weather', 'Home']) {
      final tab = find.text(label).last;
      await tester.ensureVisible(tab);
      await tester.tap(tab, warnIfMissed: false);
      await settle(tester);
    }
    expect(router(tester).routerDelegate.currentConfiguration.uri.path, '/');
    await tearDownApp(tester);
  });

  testWidgets('every drawer item navigates', (tester) async {
    await launch(tester);
    const items = {
      'Metro Services': '/metro',
      'Bus Guide & Tracking': '/bus',
      'Auto & Cab Fares': '/transport',
      'Weather & Air Quality (AQI)': '/weather',
      'Tourist Spots': '/tourist-spots',
      'Emergency Helplines': '/emergency',
      'Commute Games': '/games',
      'Home': '/',
    };
    for (final entry in items.entries) {
      await goTo(tester, '/');
      await tester.tap(find.byTooltip('Menu'));
      await settle(tester, 6);
      final item = find.descendant(of: find.byType(Drawer), matching: find.text(entry.key));
      expect(item, findsWidgets, reason: 'drawer item ${entry.key}');
      await tester.ensureVisible(item.first);
      await tester.tap(item.first);
      await settle(tester);
      expect(router(tester).routerDelegate.currentConfiguration.uri.path, entry.value);
    }
    await tearDownApp(tester);
  });

  testWidgets('metro route finder with prefilled stations shows a route', (tester) async {
    await launch(tester);
    await tester.runAsync(() async {
      router(tester).go('/metro/route-finder?from=Rajiv%20Chowk&to=Hauz%20Khas');
      await Future<void>.delayed(const Duration(seconds: 2));
    });
    // The search does real async work; wait for it (bounded) instead of a fixed delay.
    final result = find.textContaining(RegExp(r'^\d+ routes? found'));
    for (var i = 0; i < 40 && result.evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 250)));
      await settle(tester, 2);
    }
    expect(result, findsOneWidget);
    expect(find.textContaining('min'), findsWidgets);
    await tearDownApp(tester);
  });

  testWidgets('metro sub-screens render', (tester) async {
    await launch(tester);
    for (final r in ['/metro', '/metro/fare-calculator', '/metro/live-updates', '/metro/map', '/metro/live-tracker']) {
      await goTo(tester, r);
    }
    await tearDownApp(tester);
  });

  testWidgets('bus planner, route and stop pages render', (tester) async {
    await launch(tester);
    final line = net.lineById(0)!;
    final stop = net.stopsOf(line).first;
    for (final r in [
      '/bus',
      '/bus/route-finder',
      '/bus/route-finder?from=Kashmere%20Gate&to=Nehru%20Place',
      '/bus/route/0',
      '/bus/stop/${stop.id}',
      '/bus/route/999999',
      '/bus/stop/abc',
      '/bus/journey',
      '/bus/stop-locator',
      '/bus/realtime',
      '/bus/map',
    ]) {
      await goTo(tester, r);
    }
    await tearDownApp(tester);
  });

  testWidgets('city screens and games render', (tester) async {
    await launch(tester);
    for (final r in ['/transport', '/tourist-spots', '/emergency', '/weather', '/games']) {
      await goTo(tester, r);
    }
    for (final g in ['/games/snake', '/games/tetris', '/games/2048', '/games/flappy-bird', '/games/memory']) {
      await goTo(tester, '/games');
      router(tester).push(g);
      await settle(tester);
    }
    await tearDownApp(tester);
  });

  testWidgets('key screens survive large text (1.3x)', (tester) async {
    await launch(tester, textScale: 1.3);
    for (final r in ['/', '/metro', '/bus', '/metro/route-finder', '/bus/route-finder', '/bus/route/0', '/transport', '/emergency', '/games']) {
      await goTo(tester, r);
    }
    await tearDownApp(tester);
  });

  testWidgets('home sheets, drawer dialogs and tourist sheet open without errors', (tester) async {
    await launch(tester);
    await goTo(tester, '/');
    await tester.tap(find.byTooltip('Transit alerts'));
    await settle(tester, 6);
    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.binding.handlePopRoute(); // close the sheet
    await settle(tester, 6);

    for (final label in ['About & Disclaimers', 'Privacy Policy']) {
      await tester.tap(find.byTooltip('Menu'));
      await settle(tester, 6);
      final item = find.descendant(of: find.byType(Drawer), matching: find.text(label));
      await tester.scrollUntilVisible(
        item,
        120,
        scrollable: find.descendant(of: find.byType(Drawer), matching: find.byType(Scrollable)).first,
      );
      await tester.tap(item);
      await settle(tester, 4);
      // Privacy Policy first asks the platform whether it can open a browser.
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await settle(tester, 6);
      expect(find.byType(Dialog), findsOneWidget, reason: label);
      await tester.binding.handlePopRoute(); // close the dialog
      await settle(tester, 6);
      expect(find.byType(Dialog), findsNothing);
    }

    await goTo(tester, '/tourist-spots');
    await tester.tap(find.text('Top Curated Spots'));
    await settle(tester, 8);
    final spot = find.text('Red Fort');
    expect(spot, findsWidgets);
    await tester.tap(spot.first, warnIfMissed: false);
    await settle(tester, 8);
    await tearDownApp(tester);
  });

  testWidgets('back on a page opened without history goes to its section', (tester) async {
    await launch(tester);
    String path() => router(tester).routerDelegate.currentConfiguration.uri.path;

    await goTo(tester, '/bus/route/999999');
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(path(), '/bus');

    await goTo(tester, '/games/snake');
    await tester.tap(find.byTooltip('Back'));
    await settle(tester);
    expect(path(), '/games');

    await goTo(tester, '/tourist-spots');
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(path(), '/');

    // Pushed root tab pops back instead of asking to exit.
    router(tester).push('/weather');
    await settle(tester);
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(path(), '/');
    expect(find.text('Exit App'), findsNothing);

    // A root tab with nothing beneath asks before exiting.
    await goTo(tester, '/metro');
    await tester.binding.handlePopRoute();
    await settle(tester, 6);
    expect(find.text('Exit App'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await settle(tester, 6);
    expect(path(), '/metro');
    await tearDownApp(tester);
  });
}
