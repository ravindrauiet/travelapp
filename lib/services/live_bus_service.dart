import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart' as pbrt;
import 'package:http/http.dart' as http;

import '../models/bus_network.dart';
import '../models/gtfs_models.dart';
import '../utils/app_constants.dart';
import 'bus_network_service.dart';

/// Live bus positions from the Delhi Open Transit Data (OTD) GTFS-realtime feed,
/// enriched with the offline bus network (route number, termini, nearest/next stop).
///
/// One shared, short-lived cache means the tracker, the map and the route screen
/// never download the ~360 KB feed more than once per [cacheTtl].

// ── Errors ──────────────────────────────────────────────────────────────────

enum LiveBusErrorKind { unsupportedPlatform, offline, timeout, badKey, server, invalidData }

class LiveBusException implements Exception {
  final LiveBusErrorKind kind;
  final String? detail;

  const LiveBusException(this.kind, [this.detail]);

  /// Short headline for empty/error states.
  String get title {
    switch (kind) {
      case LiveBusErrorKind.unsupportedPlatform:
        return 'Live tracking is in the app';
      case LiveBusErrorKind.offline:
        return 'You\'re offline';
      case LiveBusErrorKind.timeout:
        return 'Live feed is slow';
      case LiveBusErrorKind.badKey:
        return 'Live feed access denied';
      case LiveBusErrorKind.server:
        return 'Live feed unavailable';
      case LiveBusErrorKind.invalidData:
        return 'Couldn\'t read live data';
    }
  }

  /// Friendly explanation for the user.
  String get message {
    switch (kind) {
      case LiveBusErrorKind.unsupportedPlatform:
        return 'Delhi\'s live bus feed can\'t be opened from a web browser. '
            'Install Metromate on Android or iOS to see buses moving in real time.';
      case LiveBusErrorKind.offline:
        return 'Check your internet connection and try again.';
      case LiveBusErrorKind.timeout:
        return 'Delhi\'s live bus server took too long to respond. Try again in a moment.';
      case LiveBusErrorKind.badKey:
        return 'The live feed rejected our access key. Please update the app.';
      case LiveBusErrorKind.server:
        return 'Delhi\'s live bus server is having trouble right now. Try again shortly.';
      case LiveBusErrorKind.invalidData:
        return 'The live feed sent data we couldn\'t understand. Try again shortly.';
    }
  }

  /// Whether retrying soon could help.
  bool get isRetryable => kind != LiveBusErrorKind.unsupportedPlatform && kind != LiveBusErrorKind.badKey;

  @override
  String toString() => 'LiveBusException(${kind.name}${detail == null ? '' : ': $detail'})';
}

// ── Parsing (runs in an isolate) ────────────────────────────────────────────

/// Raw vehicles decoded from one GTFS-realtime VehiclePositions message.
class ParsedVehicleFeed {
  final List<GTFSVehiclePosition> vehicles;

  /// Feed header timestamp in seconds since epoch, if present.
  final int? headerTimestamp;

  /// Entities in the message (before filtering).
  final int entityCount;

  /// Entities dropped for missing or out-of-area coordinates.
  final int droppedInvalid;

  const ParsedVehicleFeed({
    required this.vehicles,
    required this.headerTimestamp,
    required this.entityCount,
    required this.droppedInvalid,
  });
}

/// Rough bounding box of Delhi NCR — anything outside is a bad GPS fix.
bool isPlausibleDelhiPosition(double lat, double lon) =>
    lat.isFinite && lon.isFinite && lat > 27.8 && lat < 29.4 && lon > 76.3 && lon < 78.2;

/// Decodes a VehiclePositions protobuf. Top-level so it can run via `compute`.
/// Throws [FormatException] when the bytes are not a GTFS-realtime message.
ParsedVehicleFeed parseVehicleFeed(Uint8List bytes) {
  final pbrt.FeedMessage feed;
  try {
    feed = pbrt.FeedMessage.fromBuffer(bytes);
  } catch (e) {
    throw FormatException('Not a GTFS-realtime feed: $e');
  }

  final vehicles = <GTFSVehiclePosition>[];
  var dropped = 0;
  final header = feed.hasHeader() && feed.header.hasTimestamp() ? feed.header.timestamp.toInt() : null;

  for (final entity in feed.entity) {
    if (!entity.hasVehicle() || entity.isDeleted) {
      dropped++;
      continue;
    }
    final v = entity.vehicle;
    if (!v.hasPosition()) {
      dropped++;
      continue;
    }
    final pos = v.position;
    final lat = pos.latitude.toDouble();
    final lon = pos.longitude.toDouble();
    if (!isPlausibleDelhiPosition(lat, lon)) {
      dropped++;
      continue;
    }

    final trip = v.hasTrip() ? v.trip : null;
    final desc = v.hasVehicle() ? v.vehicle : null;
    final id = desc != null && desc.hasId() && desc.id.isNotEmpty ? desc.id : entity.id;
    final reportedSpeed = pos.hasSpeed() ? pos.speed.toDouble() : 0.0;

    vehicles.add(GTFSVehiclePosition(
      vehicleId: id,
      tripId: trip != null && trip.hasTripId() ? trip.tripId : '',
      routeId: trip != null && trip.hasRouteId() ? trip.routeId : '',
      directionId: trip != null && trip.hasDirectionId() ? trip.directionId : null,
      latitude: lat,
      longitude: lon,
      bearing: pos.hasBearing() ? pos.bearing.toDouble() : null,
      // GTFS-RT speed is metres/second; store km/h. OTD currently always sends 0.
      speed: reportedSpeed > 0 ? reportedSpeed * 3.6 : null,
      currentStatus: v.hasCurrentStatus() ? _statusName(v.currentStatus) : null,
      // 0 means "unknown"; the enricher falls back to the feed time.
      timestamp: v.hasTimestamp() ? v.timestamp.toInt() * 1000 : 0,
      label: desc != null && desc.hasLabel() ? desc.label : null,
      startTime: trip != null && trip.hasStartTime() ? trip.startTime : null,
      startDate: trip != null && trip.hasStartDate() ? trip.startDate : null,
      scheduleRelationship: trip != null && trip.hasScheduleRelationship() ? trip.scheduleRelationship.name : null,
    ));
  }

  return ParsedVehicleFeed(
    vehicles: vehicles,
    headerTimestamp: header,
    entityCount: feed.entity.length,
    droppedInvalid: dropped,
  );
}

String _statusName(pbrt.VehiclePosition_VehicleStopStatus s) {
  switch (s) {
    case pbrt.VehiclePosition_VehicleStopStatus.INCOMING_AT:
      return 'INCOMING';
    case pbrt.VehiclePosition_VehicleStopStatus.STOPPED_AT:
      return 'STOPPED';
    default:
      return 'IN_TRANSIT';
  }
}

// ── Enriched model ──────────────────────────────────────────────────────────

/// A live bus matched against the static bus network.
class LiveBus {
  final GTFSVehiclePosition vehicle;

  /// The route direction this bus is running, or null if the feed's route id
  /// isn't in the offline network.
  final BusLine? line;

  /// Index on [line] of the closest stop, and of the stop it is heading to.
  final int? nearStopIndex;
  final int? nextStopIndex;

  final BusStopInfo? nearStop;
  final BusStopInfo? nextStop;

  /// Distance from the bus to [nearStop], km.
  final double? nearStopDistanceKm;

  /// "Narela Terminal → Mori Gate"
  final String? termini;

  /// Reported speed, or an estimate from the previous position (see [speedEstimated]).
  final double? speedKmh;
  final bool speedEstimated;

  /// When the GPS fix was taken, corrected to this device's clock.
  final DateTime positionTime;

  const LiveBus({
    required this.vehicle,
    required this.positionTime,
    this.line,
    this.nearStopIndex,
    this.nextStopIndex,
    this.nearStop,
    this.nextStop,
    this.nearStopDistanceKm,
    this.termini,
    this.speedKmh,
    this.speedEstimated = false,
  });

  String get id => vehicle.vehicleId;
  String get registration => vehicle.registration;
  String get routeId => vehicle.routeId;
  double get latitude => vehicle.latitude;
  double get longitude => vehicle.longitude;
  bool get isMatched => line != null;

  /// Passenger-facing route number ("764M"), or a fallback for unknown routes.
  String get routeNumber => line?.number ?? (routeId.isEmpty ? '—' : '#$routeId');

  String get direction => line?.direction ?? '';
  String get operatorName => line?.operatorName ?? 'DTC / Cluster';

  /// Within ~80 m of a stop.
  bool get isAtStop => (nearStopDistanceKm ?? 1) <= 0.08;

  /// Whether the bus seems to be moving (only known when speed is available).
  bool? get isMoving => speedKmh == null ? null : speedKmh! >= 3;

  Duration ageAt(DateTime now) {
    final d = now.difference(positionTime);
    return d.isNegative ? Duration.zero : d;
  }

  /// "Near Saket → next Malviya Nagar" style summary.
  String get whereText {
    if (nearStop == null) return 'Location on route unknown';
    if (nextStop == null) return 'Near ${nearStop!.name}';
    if (nextStopIndex == nearStopIndex && !isAtStop) return 'Approaching ${nearStop!.name}';
    final here = isAtStop ? 'At ${nearStop!.name}' : 'Near ${nearStop!.name}';
    if (nextStop!.id == nearStop!.id) return here; // at the last stop
    return '$here → next ${nextStop!.name}';
  }

  double distanceKmTo(double lat, double lon) => BusNetworkService.distanceKm(lat, lon, latitude, longitude);
}

/// Estimated arrival of a live bus at a stop further along its route.
class LiveStopEta {
  final BusStopInfo stop;
  final int index;

  /// Approximate minutes from now, from scheduled run times between stops.
  final int minutes;

  const LiveStopEta({required this.stop, required this.index, required this.minutes});
}

/// One download of the feed, enriched and filtered.
class LiveBusSnapshot {
  final List<LiveBus> buses;
  final DateTime fetchedAt;

  /// Feed entities before filtering.
  final int feedEntities;
  final int droppedInvalid;
  final int droppedStale;

  LiveBusSnapshot({
    required this.buses,
    required this.fetchedAt,
    required this.feedEntities,
    this.droppedInvalid = 0,
    this.droppedStale = 0,
  });

  late final Map<String, List<LiveBus>> _byRouteId = _group((b) => b.routeId);
  late final Map<String, List<LiveBus>> _byNumber =
      _group((b) => b.line == null ? '' : normalizeRouteNumber(b.line!.number));

  Map<String, List<LiveBus>> _group(String Function(LiveBus) key) {
    final out = <String, List<LiveBus>>{};
    for (final b in buses) {
      final k = key(b);
      if (k.isEmpty) continue;
      out.putIfAbsent(k, () => []).add(b);
    }
    return out;
  }

  bool get isEmpty => buses.isEmpty;
  int get count => buses.length;

  /// Distinct passenger route numbers with at least one bus out.
  int get routeCount => _byNumber.length;

  /// Buses whose route is in the offline network (route number known).
  int get matchedCount => buses.where((b) => b.isMatched).length;

  List<GTFSVehiclePosition> get vehicles => buses.map((b) => b.vehicle).toList();

  /// Buses on one direction of a route (feed `route_id` == [BusLine.id]).
  List<LiveBus> forLineId(String lineId) => _byRouteId[lineId] ?? const [];

  /// Buses on any direction of a route number such as "764M".
  List<LiveBus> forRouteNumber(String number) => _byNumber[normalizeRouteNumber(number)] ?? const [];

  /// Live bus counts per route number (normalised key).
  int countForRouteNumber(String number) => forRouteNumber(number).length;

  /// Buses within [radiusKm], closest first.
  List<(LiveBus, double)> near(double lat, double lon, {double radiusKm = 2, int? limit}) {
    final out = <(LiveBus, double)>[];
    for (final b in buses) {
      final d = b.distanceKmTo(lat, lon);
      if (d <= radiusKm) out.add((b, d));
    }
    out.sort((a, b) => a.$2.compareTo(b.$2));
    return limit == null ? out : out.take(limit).toList();
  }

  LiveBus? byId(String vehicleId) {
    for (final b in buses) {
      if (b.id == vehicleId) return b;
    }
    return null;
  }

  static String normalizeRouteNumber(String n) => n.trim().toUpperCase().replaceAll(' ', '');
}

// ── Enrichment (pure, testable) ─────────────────────────────────────────────

/// Last known fix of a vehicle, used to estimate speed between downloads.
class VehicleFix {
  final double lat;
  final double lon;
  final int timestampMs;
  final double? speedKmh;

  const VehicleFix(this.lat, this.lon, this.timestampMs, [this.speedKmh]);
}

class LiveBusEnricher {
  /// Positions older than this (relative to the feed time) are dropped.
  static const Duration maxAge = Duration(minutes: 10);

  /// Distance at which a bus counts as "at" a stop for next-stop purposes.
  static const double atStopKm = 0.08;

  /// Turns a parsed feed into a [LiveBusSnapshot].
  ///
  /// [network] may be null (offline network failed to load) — buses are then
  /// returned without route details. [previous] carries the last fix per vehicle
  /// and is updated in place to estimate speed across downloads.
  static LiveBusSnapshot build(
    ParsedVehicleFeed feed, {
    required DateTime fetchedAt,
    BusNetworkService? network,
    Map<String, VehicleFix>? previous,
  }) {
    final fetchedMs = fetchedAt.millisecondsSinceEpoch;
    // Judge freshness against the feed's own clock so a wrong phone clock
    // doesn't hide (or keep) every bus.
    final referenceMs = feed.headerTimestamp != null && feed.headerTimestamp! > 0
        ? feed.headerTimestamp! * 1000
        : fetchedMs;

    final buses = <LiveBus>[];
    var stale = 0;
    final seen = <String>{};

    for (final v in feed.vehicles) {
      final ts = v.timestamp > 0 ? v.timestamp : referenceMs;
      final lagMs = referenceMs - ts;
      if (lagMs > maxAge.inMilliseconds) {
        stale++;
        continue;
      }
      if (!seen.add(v.vehicleId)) continue; // duplicate entity for the same bus

      final positionTime = DateTime.fromMillisecondsSinceEpoch(fetchedMs - math.max(0, lagMs));

      // Speed: prefer the feed, else estimate from the previous download.
      double? speed = v.speed;
      var estimated = false;
      final prev = previous?[v.vehicleId];
      if (speed == null && prev != null && v.timestamp > 0) {
        final dtSec = (v.timestamp - prev.timestampMs) / 1000;
        if (dtSec >= 10 && dtSec <= 600) {
          final km = BusNetworkService.distanceKm(prev.lat, prev.lon, v.latitude, v.longitude);
          final kmh = km / dtSec * 3600;
          if (kmh <= 90) {
            speed = kmh;
            estimated = true;
          }
        } else if (dtSec == 0 && prev.speedKmh != null) {
          speed = prev.speedKmh; // same fix as last time
          estimated = true;
        }
      }
      if (previous != null && v.timestamp > 0) {
        previous[v.vehicleId] = VehicleFix(v.latitude, v.longitude, v.timestamp, speed);
      }

      final line = network?.lineByIdString(v.routeId);
      if (line == null || network == null) {
        // Route not in the offline timetable (the live feed runs routes the
        // published static GTFS lacks): still say roughly where the bus is.
        final hit = network == null ? null : _StopGrid.of(network).nearest(v.latitude, v.longitude);
        buses.add(LiveBus(
          vehicle: v,
          positionTime: positionTime,
          nearStop: hit?.$1,
          nearStopDistanceKm: hit?.$2,
          speedKmh: speed,
          speedEstimated: estimated,
        ));
        continue;
      }

      final (near, next, nearKm) = locateOnLine(network, line, v.latitude, v.longitude);
      buses.add(LiveBus(
        vehicle: v,
        positionTime: positionTime,
        line: line,
        nearStopIndex: near,
        nextStopIndex: next,
        nearStop: network.stopById(line.stopIds[near]),
        nextStop: network.stopById(line.stopIds[next]),
        nearStopDistanceKm: nearKm,
        termini: network.terminiOf(line),
        speedKmh: speed,
        speedEstimated: estimated,
      ));
    }

    // Forget vehicles that disappeared long ago so the map doesn't grow forever.
    previous?.removeWhere((_, f) => referenceMs - f.timestampMs > const Duration(minutes: 30).inMilliseconds);

    return LiveBusSnapshot(
      buses: buses,
      fetchedAt: fetchedAt,
      feedEntities: feed.entityCount,
      droppedInvalid: feed.droppedInvalid,
      droppedStale: stale,
    );
  }

  /// Nearest stop index, the stop the bus is heading to, and distance to the
  /// nearest stop in km. Without a heading we infer direction of travel from
  /// geometry: if the bus is closer to stop i+1 than stop i is, it has passed i.
  static (int, int, double) locateOnLine(BusNetworkService net, BusLine line, double lat, double lon) {
    final i = net.nearestStopIndex(line, lat, lon);
    final last = line.stopIds.length - 1;
    final stop = net.stopById(line.stopIds[i])!;
    final dNear = BusNetworkService.distanceKm(lat, lon, stop.lat, stop.lon);
    if (i >= last) return (i, i, dNear);

    final after = net.stopById(line.stopIds[i + 1])!;
    final busToAfter = BusNetworkService.distanceKm(lat, lon, after.lat, after.lon);
    final stopToAfter = BusNetworkService.distanceKm(stop.lat, stop.lon, after.lat, after.lon);
    final passed = dNear <= atStopKm || busToAfter < stopToAfter;
    return (i, passed ? i + 1 : i, dNear);
  }

  /// Approximate arrival times at the next [count] stops, from scheduled
  /// run times between stops ([BusLine.offsets]).
  static List<LiveStopEta> stopsAhead(BusNetworkService net, LiveBus bus, {int count = 8}) {
    final line = bus.line;
    final next = bus.nextStopIndex;
    final near = bus.nearStopIndex;
    if (line == null || next == null || near == null) return const [];

    final base = line.offsets[near];
    final out = <LiveStopEta>[];
    for (var j = next; j < line.stopIds.length && out.length < count; j++) {
      final stop = net.stopById(line.stopIds[j]);
      if (stop == null) continue;
      out.add(LiveStopEta(stop: stop, index: j, minutes: math.max(1, line.offsets[j] - base)));
    }
    return out;
  }
}

/// Coarse spatial index over all served stops (~1 km cells) for quick
/// "nearest stop" lookups of buses on routes we don't know.
class _StopGrid {
  static const double _cell = 0.01;
  static _StopGrid? _cached;
  static BusNetworkService? _cachedFor;
  static int _cachedLines = -1;

  final Map<int, List<BusStopInfo>> _cells = {};

  _StopGrid(Iterable<BusStopInfo> stops) {
    for (final s in stops) {
      _cells.putIfAbsent(_key((s.lat / _cell).floor(), (s.lon / _cell).floor()), () => []).add(s);
    }
  }

  static _StopGrid of(BusNetworkService net) {
    if (_cached == null || !identical(_cachedFor, net) || _cachedLines != net.lineCount) {
      _cached = _StopGrid(net.places.expand((p) => p.stops));
      _cachedFor = net;
      _cachedLines = net.lineCount;
    }
    return _cached!;
  }

  static int _key(int r, int c) => r * 100000 + c;

  (BusStopInfo, double)? nearest(double lat, double lon, {double maxKm = 0.6}) {
    final r = (lat / _cell).floor();
    final c = (lon / _cell).floor();
    BusStopInfo? best;
    var bestD = maxKm;
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        for (final s in _cells[_key(r + dr, c + dc)] ?? const <BusStopInfo>[]) {
          final d = BusNetworkService.distanceKm(lat, lon, s.lat, s.lon);
          if (d <= bestD) {
            bestD = d;
            best = s;
          }
        }
      }
    }
    return best == null ? null : (best, bestD);
  }
}

// ── Service ─────────────────────────────────────────────────────────────────

class LiveBusService {
  LiveBusService({
    http.Client? client,
    BusNetworkService? network,
    this.cacheTtl = const Duration(seconds: 20),
    this.requestTimeout = const Duration(seconds: 20),
    bool? supported,
  })  : _client = client ?? http.Client(),
        _network = network ?? BusNetworkService.instance,
        _supported = supported ?? !kIsWeb;

  static final LiveBusService instance = LiveBusService();

  /// Snapshots younger than this are served from memory.
  final Duration cacheTtl;
  final Duration requestTimeout;

  /// Even a manual refresh won't re-download more often than this.
  static const Duration minRefreshGap = Duration(seconds: 5);

  final http.Client _client;
  final BusNetworkService _network;
  final bool _supported;
  final Map<String, VehicleFix> _fixes = {};

  LiveBusSnapshot? _last;
  LiveBusException? _lastError;
  Future<LiveBusSnapshot>? _inFlight;

  /// The OTD feed sends no CORS headers, so browsers block it.
  bool get isSupported => _supported;

  /// Most recent successful snapshot (may be older than [cacheTtl]).
  LiveBusSnapshot? get lastSnapshot => _last;
  LiveBusException? get lastError => _lastError;

  /// Latest live buses. Uses the shared cache unless [forceRefresh].
  /// Throws [LiveBusException].
  Future<LiveBusSnapshot> snapshot({bool forceRefresh = false}) {
    if (!_supported) {
      return Future.error(const LiveBusException(LiveBusErrorKind.unsupportedPlatform));
    }
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;

    final last = _last;
    if (last != null) {
      final age = DateTime.now().difference(last.fetchedAt);
      if (age < (forceRefresh ? minRefreshGap : cacheTtl)) return Future.value(last);
    }

    final future = _fetch();
    _inFlight = future;
    future.then((_) {}, onError: (_) {}).whenComplete(() {
      if (identical(_inFlight, future)) _inFlight = null;
    });
    return future;
  }

  /// Buses on one direction of a route (feed route id == [BusLine.id]).
  Future<List<LiveBus>> busesForLine(String lineId, {bool forceRefresh = false}) async =>
      (await snapshot(forceRefresh: forceRefresh)).forLineId(lineId);

  /// Buses on any direction of a route number such as "764M".
  Future<List<LiveBus>> busesForRouteNumber(String number, {bool forceRefresh = false}) async =>
      (await snapshot(forceRefresh: forceRefresh)).forRouteNumber(number);

  /// Upcoming stops for a live bus with approximate minutes.
  List<LiveStopEta> stopsAhead(LiveBus bus, {int count = 8}) =>
      _network.isLoaded ? LiveBusEnricher.stopsAhead(_network, bus, count: count) : const [];

  Future<LiveBusSnapshot> _fetch() async {
    try {
      final snap = await _download();
      _last = snap;
      _lastError = null;
      return snap;
    } on LiveBusException catch (e) {
      _lastError = e;
      rethrow;
    }
  }

  Future<LiveBusSnapshot> _download() async {
    final uri = Uri.parse('${AppConstants.otdRealtimeUrl}?key=${AppConstants.otdApiKey}');

    // Load the offline network alongside the download.
    final networkReady = _network.isLoaded
        ? Future.value(true)
        : _network.ensureLoaded().then((_) => true, onError: (Object e) {
      debugPrint('LiveBusService: bus network unavailable: $e');
      return false;
    });

    final http.Response res;
    try {
      res = await _client.get(uri, headers: const {
        'Accept': 'application/x-protobuf, application/octet-stream',
        'User-Agent': 'Metromate/1.0',
      }).timeout(requestTimeout);
    } on TimeoutException {
      throw const LiveBusException(LiveBusErrorKind.timeout);
    } on http.ClientException catch (e) {
      throw LiveBusException(LiveBusErrorKind.offline, e.message);
    } catch (e) {
      // SocketException / HandshakeException etc. (dart:io types aren't
      // importable on web, so match broadly).
      throw LiveBusException(LiveBusErrorKind.offline, e.toString());
    }

    final code = res.statusCode;
    if (code == 401 || code == 403) throw LiveBusException(LiveBusErrorKind.badKey, 'HTTP $code');
    if (code != 200) throw LiveBusException(LiveBusErrorKind.server, 'HTTP $code');
    if (res.bodyBytes.isEmpty) throw const LiveBusException(LiveBusErrorKind.invalidData, 'empty body');

    final ParsedVehicleFeed feed;
    try {
      // ~360 KB / 3,500 entities: decode off the UI thread.
      feed = await compute(parseVehicleFeed, res.bodyBytes);
    } catch (e) {
      throw LiveBusException(LiveBusErrorKind.invalidData, e.toString());
    }

    final hasNetwork = await networkReady;
    return LiveBusEnricher.build(
      feed,
      fetchedAt: DateTime.now(),
      network: hasNetwork ? _network : null,
      previous: _fixes,
    );
  }

  @visibleForTesting
  void resetCache() {
    _last = null;
    _lastError = null;
    _inFlight = null;
    _fixes.clear();
  }
}

/// "just now", "40 s ago", "3 min ago".
String formatAge(Duration d) {
  if (d.inSeconds < 10) return 'just now';
  if (d.inSeconds < 60) return '${d.inSeconds} s ago';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  return '${d.inHours} h ago';
}

/// "350 m" / "1.2 km".
String formatDistance(double km) => km < 1 ? '${(km * 1000 / 10).round() * 10} m' : '${km.toStringAsFixed(1)} km';
