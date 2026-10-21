import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

// fixnum comes with protobuf; only needed to build synthetic feeds.
// ignore: depend_on_referenced_packages
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart' as pbrt;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:metromate/services/bus_network_service.dart';
import 'package:metromate/services/live_bus_service.dart';

/// 50 real entities trimmed from the OTD VehiclePositions feed (Oct 2026).
const _fixture = 'test/fixtures/vehicle_positions_sample.pb';

pbrt.FeedEntity _entity(String id, double lat, double lon, int ts, {String route = '0'}) => pbrt.FeedEntity(
      id: id,
      vehicle: pbrt.VehiclePosition(
        trip: pbrt.TripDescriptor(tripId: '${route}_10_00', routeId: route),
        position: pbrt.Position(latitude: lat, longitude: lon),
        timestamp: Int64(ts),
        vehicle: pbrt.VehicleDescriptor(id: id, label: id),
      ),
    );

Uint8List _feed(int headerTs, List<pbrt.FeedEntity> entities) => pbrt.FeedMessage(
      header: pbrt.FeedHeader(gtfsRealtimeVersion: '2.0', timestamp: Int64(headerTs)),
      entity: entities,
    ).writeToBuffer();

void main() {
  final net = BusNetworkService.instance;
  late Uint8List sample;

  setUpAll(() {
    net.loadFromJson(jsonDecode(File(BusNetworkService.assetPath).readAsStringSync()) as Map<String, dynamic>);
    sample = File(_fixture).readAsBytesSync();
  });

  group('parseVehicleFeed', () {
    test('decodes the real OTD sample', () {
      final feed = parseVehicleFeed(sample);
      expect(feed.entityCount, 50);
      expect(feed.vehicles, hasLength(50));
      expect(feed.headerTimestamp, greaterThan(1700000000));
      final v = feed.vehicles.first;
      expect(v.vehicleId, 'DL1PD6453');
      expect(v.registration, 'DL1PD6453');
      expect(v.routeId, '1372');
      expect(v.tripId, startsWith('1372_'));
      expect(v.startTime, isNotNull);
      expect(v.scheduleRelationship, isNotNull);
      expect(v.timestamp, greaterThan(1700000000 * 1000)); // milliseconds
      expect(v.speed, isNull); // OTD reports 0 → unknown
    });

    test('drops missing, zero and out-of-area coordinates', () {
      final bytes = _feed(1000, [
        _entity('ok', 28.61, 77.21, 1000),
        _entity('zero', 0, 0, 1000),
        _entity('mumbai', 19.07, 72.87, 1000),
        pbrt.FeedEntity(id: 'nopos', vehicle: pbrt.VehiclePosition()),
        pbrt.FeedEntity(id: 'alert'),
      ]);
      final feed = parseVehicleFeed(bytes);
      expect(feed.vehicles.map((v) => v.vehicleId), ['ok']);
      expect(feed.droppedInvalid, 4);
    });

    test('rejects garbage bytes', () {
      expect(() => parseVehicleFeed(Uint8List.fromList(utf8.encode('<html>401</html>'))), throwsFormatException);
    });
  });

  group('LiveBusEnricher', () {
    test('matches feed route ids to bus lines with stops', () {
      final snap = LiveBusEnricher.build(parseVehicleFeed(sample), fetchedAt: DateTime.now(), network: net);
      expect(snap.count, 50);
      final matched = snap.buses.where((b) => b.isMatched).toList();
      // About half the live fleet runs route ids the published static GTFS lacks.
      expect(matched.length, greaterThan(20));
      expect(snap.matchedCount, matched.length);
      final unmatched = snap.buses.where((b) => !b.isMatched).toList();
      expect(unmatched.where((b) => b.nearStop != null), isNotEmpty);
      expect(unmatched.every((b) => b.nextStop == null && b.termini == null), isTrue);
      for (final b in matched) {
        expect(b.routeNumber, b.line!.number);
        expect(b.line!.id.toString(), b.routeId);
        expect(b.nearStop, isNotNull);
        expect(b.termini, contains('→'));
        expect(b.nextStopIndex! - b.nearStopIndex!, inInclusiveRange(0, 1));
        expect(b.whereText, anyOf(startsWith('Near '), startsWith('At '), startsWith('Approaching ')));
      }
      final first = matched.first;
      expect(snap.forLineId(first.routeId), contains(first));
      expect(snap.forRouteNumber(first.line!.number.toLowerCase()), contains(first));
      expect(snap.routeCount, greaterThan(10));
    });

    test('drops positions older than 10 minutes relative to the feed', () {
      const t = 1792574721;
      final snap = LiveBusEnricher.build(
        parseVehicleFeed(_feed(t, [
          _entity('fresh', 28.61, 77.21, t - 60),
          _entity('stale', 28.62, 77.22, t - 11 * 60),
        ])),
        fetchedAt: DateTime.now(),
        network: net,
      );
      expect(snap.buses.map((b) => b.id), ['fresh']);
      expect(snap.droppedStale, 1);
      // Age uses the feed clock, not the (possibly wrong) device clock.
      expect(snap.buses.single.ageAt(snap.fetchedAt).inSeconds, 60);
    });

    test('works without the offline network', () {
      final snap = LiveBusEnricher.build(parseVehicleFeed(sample), fetchedAt: DateTime.now());
      expect(snap.count, 50);
      expect(snap.buses.every((b) => !b.isMatched && b.routeNumber.startsWith('#')), isTrue);
    });

    test('locates a bus between two stops and picks the stop ahead', () {
      final line = net.lineById(0)!;
      final stops = net.stopsOf(line);
      // 30 % of the way from stop 3 to stop 4.
      final lat = stops[3].lat + (stops[4].lat - stops[3].lat) * 0.3;
      final lon = stops[3].lon + (stops[4].lon - stops[3].lon) * 0.3;
      final (near, next, _) = LiveBusEnricher.locateOnLine(net, line, lat, lon);
      expect(near, 3);
      expect(next, 4);

      // 70 % of the way: nearest is 4 and the bus hasn't reached it yet.
      final lat2 = stops[3].lat + (stops[4].lat - stops[3].lat) * 0.7;
      final lon2 = stops[3].lon + (stops[4].lon - stops[3].lon) * 0.7;
      final (near2, next2, _) = LiveBusEnricher.locateOnLine(net, line, lat2, lon2);
      expect(near2, 4);
      expect(next2, 4);
    });

    test('estimates speed from the previous download and lists stops ahead', () {
      final line = net.lineById(0)!;
      final s = net.stopsOf(line);
      const t = 1792574721;
      final fixes = <String, VehicleFix>{};
      LiveBusEnricher.build(parseVehicleFeed(_feed(t, [_entity('b', s[2].lat, s[2].lon, t, route: '0')])),
          fetchedAt: DateTime.now(), network: net, previous: fixes);
      final snap = LiveBusEnricher.build(
          parseVehicleFeed(_feed(t + 60, [_entity('b', s[3].lat, s[3].lon, t + 60, route: '0')])),
          fetchedAt: DateTime.now(),
          network: net,
          previous: fixes);
      final bus = snap.buses.single;
      final km = BusNetworkService.distanceKm(s[2].lat, s[2].lon, s[3].lat, s[3].lon);
      expect(bus.speedEstimated, isTrue);
      expect(bus.speedKmh, closeTo(km * 60, 0.5));
      expect(bus.isAtStop, isTrue);
      expect(bus.nextStopIndex, 4);

      final ahead = LiveBusEnricher.stopsAhead(net, bus, count: 5);
      expect(ahead.map((e) => e.index), [4, 5, 6, 7, 8]);
      for (var i = 1; i < ahead.length; i++) {
        expect(ahead[i].minutes, greaterThanOrEqualTo(ahead[i - 1].minutes));
      }
      expect(ahead.first.minutes, greaterThanOrEqualTo(1));
    });
  });

  group('LiveBusService', () {
    LiveBusService service(MockClient client) => LiveBusService(client: client, network: net, supported: true);

    test('fetches once and serves the cache', () async {
      var calls = 0;
      final s = service(MockClient((req) async {
        calls++;
        expect(req.url.queryParameters['key'], isNotEmpty);
        return http.Response.bytes(sample, 200);
      }));
      final results = await Future.wait([s.snapshot(), s.snapshot()]);
      expect(identical(results[0], results[1]), isTrue);
      await s.snapshot();
      await s.snapshot(forceRefresh: true); // within minRefreshGap
      expect(calls, 1);
      expect(s.lastSnapshot!.count, 50);
      expect((await s.busesForLine('1372')).single.registration, 'DL1PD6453');
    });

    Future<LiveBusErrorKind> kindOf(LiveBusService s) async {
      try {
        await s.snapshot();
      } on LiveBusException catch (e) {
        return e.kind;
      }
      fail('expected LiveBusException');
    }

    test('maps failures to typed errors', () async {
      expect(await kindOf(service(MockClient((_) async => http.Response('nope', 401)))), LiveBusErrorKind.badKey);
      expect(await kindOf(service(MockClient((_) async => http.Response('down', 503)))), LiveBusErrorKind.server);
      expect(await kindOf(service(MockClient((_) async => throw http.ClientException('no route')))),
          LiveBusErrorKind.offline);
      expect(await kindOf(service(MockClient((_) async => http.Response('<html>', 200)))),
          LiveBusErrorKind.invalidData);
      expect(await kindOf(LiveBusService(client: MockClient((_) async => fail('no request')), supported: false)),
          LiveBusErrorKind.unsupportedPlatform);
    });

    test('formats ages and distances', () {
      expect(formatAge(const Duration(seconds: 4)), 'just now');
      expect(formatAge(const Duration(seconds: 40)), '40 s ago');
      expect(formatAge(const Duration(minutes: 3)), '3 min ago');
      expect(formatDistance(0.347), '350 m');
      expect(formatDistance(1.24), '1.2 km');
    });
  });
}
