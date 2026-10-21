import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:metromate/models/metro_station.dart';
import 'package:metromate/services/gtfs_graph_service.dart';
import 'package:metromate/services/station_tracker_service.dart';

Position _pos(double lat, double lon, {double accuracy = 15}) => Position(
      latitude: lat,
      longitude: lon,
      timestamp: DateTime.now(),
      accuracy: accuracy,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<MetroStation> stations;
  MetroStation st(String name) => stations.firstWhere((s) => s.name == name);

  setUpAll(() async {
    GTFSGraphService.assetLoader = (path) => File(path).readAsString();
    GTFSGraphService.reset();
    stations = await GTFSGraphService.getStations();
  });

  Future<StationTrackerService> trackerFor(String from, String to) async {
    final route = (await GTFSGraphService.findRoute(
      fromName: from,
      toName: to,
      travelTime: DateTime(2025, 10, 21, 10),
      isSmartCard: false,
    ))
        .first;
    final t = StationTrackerService();
    t.setRoute(route, stations: stations);
    return t;
  }

  test('ticks off stops in order and completes at the destination', () async {
    final t = await trackerFor('Rajiv Chowk', 'Hauz Khas');
    expect(t.trackedStops.length, 10);
    expect(t.trackedStops.every((s) => s.latitude != null), isTrue);

    t.handlePosition(_pos(st('Rajiv Chowk').latitude, st('Rajiv Chowk').longitude));
    expect(t.currentStopIndex, 0);
    expect(t.remainingStops, 9);

    // GPS lost underground, regained at AIIMS: jumps ahead, never backwards
    t.handlePosition(_pos(st('AIIMS').latitude, st('AIIMS').longitude));
    final aiims = t.trackedStops.indexWhere((s) => s.name == 'AIIMS');
    expect(t.currentStopIndex, aiims);
    expect(t.trackedStops.take(aiims + 1).every((s) => s.passed), isTrue);
    t.handlePosition(_pos(st('Rajiv Chowk').latitude, st('Rajiv Chowk').longitude));
    expect(t.currentStopIndex, aiims, reason: 'must not move backwards');

    // Very inaccurate fix is ignored
    t.handlePosition(_pos(st('Hauz Khas').latitude, st('Hauz Khas').longitude, accuracy: 900));
    expect(t.journeyComplete, isFalse);

    t.handlePosition(_pos(st('Hauz Khas').latitude, st('Hauz Khas').longitude));
    expect(t.journeyComplete, isTrue);
    expect(t.remainingStops, 0);
    expect(t.isTracking, isFalse, reason: 'GPS stops at destination');
  });

  test('marks interchanges, including walking transfers', () async {
    final t = await trackerFor('Kashmere Gate', 'IGI Airport');
    final nd = t.trackedStops.firstWhere((s) => s.name == 'New Delhi');
    expect(nd.isInterchange, isTrue);
    expect(nd.changeTo, 'Airport Express');
    expect(t.trackedStops.where((s) => s.name == 'New Delhi').length, 1);

    final w = await trackerFor('Rajiv Chowk', 'Noida Sector 142');
    final s52 = w.trackedStops.firstWhere((s) => s.name == 'Noida Sector 52');
    expect(s52.isInterchange, isTrue);
    expect(s52.changeTo, contains('Aqua Line'));
    expect(w.trackedStops.map((s) => s.name), contains('Noida Sector 51'));
  });

  test('nearby list is sorted and radii are sane', () async {
    final t = await trackerFor('Rajiv Chowk', 'Hauz Khas');
    t.clearRoute();
    t.handlePosition(_pos(st('Mandi House').latitude + 0.002, st('Mandi House').longitude));
    expect(t.nearby.first.station.name, 'Mandi House');
    expect(t.nearby.first.isApproaching, isTrue);
    for (int i = 1; i < t.nearby.length; i++) {
      expect(t.nearby[i].distanceMetres, greaterThanOrEqualTo(t.nearby[i - 1].distanceMetres));
    }
  });
}
