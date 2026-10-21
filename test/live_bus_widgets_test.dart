import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metromate/services/bus_network_service.dart';
import 'package:metromate/services/live_bus_service.dart';
import 'package:metromate/widgets/live_bus_widgets.dart';

void main() {
  final net = BusNetworkService.instance;
  late LiveBusSnapshot snap;

  setUpAll(() {
    net.loadFromJson(jsonDecode(File(BusNetworkService.assetPath).readAsStringSync()) as Map<String, dynamic>);
    final feed = parseVehicleFeed(File('test/fixtures/vehicle_positions_sample.pb').readAsBytesSync());
    snap = LiveBusEnricher.build(feed, fetchedAt: DateTime.now(), network: net);
  });

  Widget host(Widget child) => MaterialApp(home: Scaffold(body: Builder(builder: (_) => child)));

  testWidgets('bus cards render known and unknown routes', (tester) async {
    final known = snap.buses.firstWhere((b) => b.isMatched);
    final unknown = snap.buses.firstWhere((b) => !b.isMatched);
    await tester.pumpWidget(host(ListView(children: [
      LiveBusCard(bus: known, now: DateTime.now(), distanceKm: 0.42),
      LiveBusCard(bus: unknown, now: DateTime.now()),
    ])));
    expect(find.text(known.routeNumber), findsOneWidget);
    expect(find.text(known.termini!), findsOneWidget);
    expect(find.text('420 m'), findsOneWidget);
    expect(find.text('Route ?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('detail sheet lists stops ahead and route actions', (tester) async {
    final bus = snap.buses.firstWhere((b) => b.isMatched && b.nextStopIndex! < b.line!.stopIds.length - 3);
    await tester.pumpWidget(host(Builder(
      builder: (context) => TextButton(onPressed: () => showLiveBusSheet(context, bus), child: const Text('open')),
    )));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600)); // LiveDot animates forever
    expect(find.text('Stops ahead'), findsOneWidget);
    expect(find.text(bus.registration), findsOneWidget);
    await tester.dragUntilVisible(find.text('Open route'), find.byType(Scrollable).last, const Offset(0, -200));
    expect(find.text('Open route'), findsOneWidget);
    expect(find.text('Show on map'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('web explains live tracking is in the app', (tester) async {
    await tester.pumpWidget(host(const LiveFeedErrorState(
      error: LiveBusException(LiveBusErrorKind.unsupportedPlatform),
    )));
    expect(find.text('Live tracking is in the app'), findsOneWidget);
    expect(find.textContaining('Android or iOS'), findsOneWidget);
  });
}
