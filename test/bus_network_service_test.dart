import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:metromate/services/bus_network_service.dart';

void main() {
  final net = BusNetworkService.instance;

  setUpAll(() {
    final raw = File(BusNetworkService.assetPath).readAsStringSync();
    net.loadFromJson(jsonDecode(raw) as Map<String, dynamic>);
  });

  test('loads the full network', () {
    expect(net.stopCount, greaterThan(6000));
    expect(net.lineCount, greaterThan(2900));
    expect(net.routeCount, greaterThan(1000));
  });

  test('searches stops by name, case-insensitively', () {
    final hits = net.searchPlaces('narela');
    expect(hits, isNotEmpty);
    expect(hits.first.name.toLowerCase(), contains('narela'));
  });

  test('searches routes by number', () {
    final hits = net.searchRoutes('764');
    expect(hits.map((l) => l.number), contains('764M'));
    expect(net.linesByNumber('764M'), isNotEmpty);
  });

  test('finds a direct journey along a known route', () {
    final line = net.lineById(0)!; // 764MSTLDOWN
    final stops = net.stopsOf(line);
    final from = net.placeOfStop(stops[1].id)!;
    final to = net.placeOfStop(stops[stops.length - 2].id)!;
    final journeys = net.findJourneys(from, to);
    expect(journeys, isNotEmpty);
    expect(journeys.first.isDirect, isTrue);
    expect(journeys.first.totalMinutes, greaterThan(0));
    expect(journeys.first.fareNonAc, inInclusiveRange(5, 15));
  });

  test('finds journeys between two busy places', () {
    final from = net.searchPlaces('kashmere gate').first;
    final to = net.searchPlaces('nehru place').first;
    final journeys = net.findJourneys(from, to);
    expect(journeys, isNotEmpty);
    for (final j in journeys) {
      expect(from.stops, contains(j.legs.first.boardStop));
      expect(to.stops, contains(j.legs.last.alightStop));
      expect(j.transfers, lessThanOrEqualTo(1));
    }
  });

  test('nearest stops are sorted by distance', () {
    final near = net.nearestStops(28.6315, 77.2167); // Connaught Place
    expect(near, isNotEmpty);
    for (var i = 1; i < near.length; i++) {
      expect(near[i].$2, greaterThanOrEqualTo(near[i - 1].$2));
    }
  });

  test('scheduled arrivals are in the future and ordered', () {
    final line = net.lineById(0)!;
    final now = DateTime(2026, 10, 21, 12, 0);
    final arrivals = net.nextArrivals(line, 5, now, count: 3);
    expect(arrivals, hasLength(3));
    expect(arrivals.first.time.isBefore(now), isFalse);
    expect(arrivals[1].time.isAfter(arrivals[0].time), isTrue);
  });

  test('late at night, arrivals roll over to the next morning', () {
    final line = net.lineById(0)!;
    final now = DateTime(2026, 10, 21, 23, 59);
    final arrivals = net.nextArrivals(line, 0, now, count: 2);
    expect(arrivals, isNotEmpty);
    expect(arrivals.first.time.isAfter(now), isTrue);
  });

  test('same-name stops far apart become separate places', () {
    for (final place in net.places) {
      for (final a in place.stops) {
        for (final b in place.stops) {
          expect(
            BusNetworkService.distanceKm(a.lat, a.lon, b.lat, b.lon),
            lessThan(10),
            reason: place.name,
          );
        }
      }
    }
  });
}
