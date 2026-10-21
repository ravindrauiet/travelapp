import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/bus_network.dart';

/// Offline Delhi bus network (all DTC + cluster routes and stops) built from the
/// OTD static GTFS feed. Provides stop search, nearest stops, direct and
/// one-transfer journeys, scheduled arrival estimates and route lookup for
/// matching realtime vehicles (GTFS-RT `trip.routeId` == [BusLine.id]).
///
/// Call [ensureLoaded] once (cheap after the first call), then use the sync API.
class BusNetworkService {
  BusNetworkService._();
  static final BusNetworkService instance = BusNetworkService._();

  static const String assetPath = 'assets/data/bus_network.json';

  /// Minutes added for changing buses (walk + uncertainty).
  static const int transferPenaltyMinutes = 6;

  /// Max walk between two different stops to count as a transfer.
  static const double maxTransferWalkKm = 0.35;

  final Map<int, BusStopInfo> _stops = {};
  final Map<int, BusLine> _lines = {};
  final Map<int, List<_StopVisit>> _visitsByStop = {};
  final Map<String, BusPlace> _places = {};
  final Map<int, BusPlace> _placeOfStop = {};
  final Map<String, List<BusLine>> _linesByNumber = {};
  Future<void>? _loading;

  bool get isLoaded => _lines.isNotEmpty;
  int get stopCount => _stops.length;
  int get routeCount => _linesByNumber.length;
  int get lineCount => _lines.length;
  Iterable<BusLine> get lines => _lines.values;
  Iterable<BusPlace> get places => _places.values;

  Future<void> ensureLoaded() {
    return _loading ??= _load().catchError((Object e) {
      _loading = null; // allow retry
      throw e;
    });
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString(assetPath);
    final data = await compute(_decode, raw);
    loadFromJson(data);
  }

  static Map<String, dynamic> _decode(String raw) => jsonDecode(raw) as Map<String, dynamic>;

  /// Builds the indexes from decoded JSON. Public so tests can load the asset directly.
  @visibleForTesting
  void loadFromJson(Map<String, dynamic> data) {
    _stops.clear();
    _lines.clear();
    _visitsByStop.clear();
    _places.clear();
    _placeOfStop.clear();
    _linesByNumber.clear();

    for (final s in data['stops'] as List) {
      final row = s as List;
      final stop = BusStopInfo(
        id: (row[0] as num).toInt(),
        code: row[1] as String,
        name: _cleanName(row[2] as String),
        lat: (row[3] as num).toDouble(),
        lon: (row[4] as num).toDouble(),
      );
      _stops[stop.id] = stop;
    }

    for (final r in data['routes'] as List) {
      final m = r as Map<String, dynamic>;
      final line = BusLine(
        id: (m['id'] as num).toInt(),
        number: m['n'] as String,
        longName: m['ln'] as String,
        direction: m['d'] as String,
        agency: m['a'] as String,
        stopIds: (m['s'] as List).map((e) => (e as num).toInt()).where(_stops.containsKey).toList(),
        offsets: (m['t'] as List).map((e) => (e as num).toInt()).toList(),
        firstDeparture: (m['f'] as num?)?.toInt(),
        lastDeparture: (m['l'] as num?)?.toInt(),
        tripCount: (m['k'] as num).toInt(),
      );
      // Unknown stops were filtered; keep offsets aligned only if nothing was dropped.
      if (line.stopIds.length != line.offsets.length || line.stopIds.length < 2) continue;
      _lines[line.id] = line;
      _linesByNumber.putIfAbsent(_normalize(line.number), () => []).add(line);
      for (var i = 0; i < line.stopIds.length; i++) {
        _visitsByStop.putIfAbsent(line.stopIds[i], () => []).add(_StopVisit(line, i));
      }
    }

    final keyOf = {for (final s in _stops.values) s.id: _normalize(s.name)};
    final grouped = <String, List<BusStopInfo>>{};
    for (final s in _stops.values) {
      if (!_visitsByStop.containsKey(s.id)) continue; // stops no route serves
      grouped.putIfAbsent(keyOf[s.id]!, () => []).add(s);
    }
    grouped.forEach((key, stops) {
      // Generic names ("ESI Hospital", "Prem Nagar") repeat across the city, so
      // split each name into clusters of stops within walking distance.
      final clusters = _clusterByDistance(stops, placeClusterKm);
      for (var i = 0; i < clusters.length; i++) {
        final cluster = clusters[i];
        final name = clusters.length == 1 ? cluster.first.name : '${cluster.first.name} (near ${_landmarkNear(cluster.first, keyOf)})';
        final place = BusPlace(name: name, stops: cluster);
        _places[i == 0 ? key : '$key#$i'] = place;
        for (final s in cluster) {
          _placeOfStop[s.id] = place;
        }
      }
    });
  }

  /// Stops sharing a name farther apart than this are treated as different places.
  static const double placeClusterKm = 1.0;

  List<List<BusStopInfo>> _clusterByDistance(List<BusStopInfo> stops, double km) {
    final clusters = <List<BusStopInfo>>[];
    for (final s in stops) {
      final home = clusters.where((c) => c.any((o) => distanceKm(s.lat, s.lon, o.lat, o.lon) <= km)).toList();
      if (home.isEmpty) {
        clusters.add([s]);
      } else {
        // Merge every cluster this stop links together
        final merged = home.expand((c) => c).toList()..add(s);
        clusters.removeWhere(home.contains);
        clusters.add(merged);
      }
    }
    // Busiest cluster keeps the plain name
    clusters.sort((a, b) => _clusterWeight(b).compareTo(_clusterWeight(a)));
    return clusters;
  }

  int _clusterWeight(List<BusStopInfo> c) => c.fold(0, (a, s) => a + (_visitsByStop[s.id]?.length ?? 0));

  /// Name of the closest served stop with a different name, for disambiguation.
  String _landmarkNear(BusStopInfo stop, Map<int, String> keyOf) {
    final own = keyOf[stop.id];
    BusStopInfo? best;
    var bestD = double.infinity;
    for (final s in _stops.values) {
      if (!_visitsByStop.containsKey(s.id) || keyOf[s.id] == own) continue;
      final d = distanceKm(stop.lat, stop.lon, s.lat, s.lon);
      if (d < bestD) {
        bestD = d;
        best = s;
      }
    }
    return best?.name ?? stop.code;
  }

  // ── Lookup ───────────────────────────────────────────────────────────────

  BusStopInfo? stopById(int id) => _stops[id];
  BusLine? lineById(int id) => _lines[id];
  BusLine? lineByIdString(String id) => int.tryParse(id) == null ? null : _lines[int.parse(id)];

  /// Both directions (and variants) of a route number, e.g. "764M".
  List<BusLine> linesByNumber(String number) => _linesByNumber[_normalize(number)] ?? const [];

  BusPlace? placeByName(String name) => _places[_normalize(name)];

  /// The searchable place a stop belongs to.
  BusPlace? placeOfStop(int stopId) => _placeOfStop[stopId];

  /// Distinct lines (by number) serving any stop of a place.
  List<BusLine> linesAtPlace(BusPlace place) {
    final seen = <int>{};
    final out = <BusLine>[];
    for (final s in place.stops) {
      for (final v in _visitsByStop[s.id] ?? const <_StopVisit>[]) {
        if (seen.add(v.line.id)) out.add(v.line);
      }
    }
    out.sort((a, b) => _compareNumbers(a.number, b.number));
    return out;
  }

  List<BusStopInfo> stopsOf(BusLine line) => line.stopIds.map((id) => _stops[id]!).toList();

  // ── Search ───────────────────────────────────────────────────────────────

  /// Ranked stop-name search: exact > prefix > word-prefix > contains.
  List<BusPlace> searchPlaces(String query, {int limit = 20}) {
    final q = _normalize(query);
    if (q.isEmpty) return const [];
    final scored = <(int, BusPlace)>[];
    _places.forEach((key, place) {
      int score;
      if (key == q) {
        score = 0;
      } else if (key.startsWith(q)) {
        score = 1;
      } else if (key.split(' ').any((w) => w.startsWith(q))) {
        score = 2;
      } else if (key.contains(q)) {
        score = 3;
      } else if (key.replaceAll(' ', '').contains(q.replaceAll(' ', ''))) {
        score = 4;
      } else {
        return;
      }
      scored.add((score, place));
    });
    scored.sort((a, b) {
      final c = a.$1.compareTo(b.$1);
      if (c != 0) return c;
      // Busier stops first
      final busy = _placeWeight(b.$2).compareTo(_placeWeight(a.$2));
      return busy != 0 ? busy : a.$2.name.compareTo(b.$2.name);
    });
    return scored.take(limit).map((e) => e.$2).toList();
  }

  /// Route-number search ("764", "534a") returning one entry per number.
  List<BusLine> searchRoutes(String query, {int limit = 20}) {
    final q = _normalize(query).replaceAll(' ', '');
    if (q.isEmpty) return const [];
    final matches = _linesByNumber.entries
        .where((e) => e.key.replaceAll(' ', '').startsWith(q))
        .map((e) => e.value.first)
        .toList()
      ..sort((a, b) => _compareNumbers(a.number, b.number));
    return matches.take(limit).toList();
  }

  /// Nearest served stops to a coordinate, closest first, with distance in km.
  List<(BusStopInfo, double)> nearestStops(double lat, double lon, {int limit = 10, double maxKm = 3}) {
    final out = <(BusStopInfo, double)>[];
    for (final s in _stops.values) {
      if (!_visitsByStop.containsKey(s.id)) continue;
      final d = distanceKm(lat, lon, s.lat, s.lon);
      if (d <= maxKm) out.add((s, d));
    }
    out.sort((a, b) => a.$2.compareTo(b.$2));
    return out.take(limit).toList();
  }

  // ── Journey planning ─────────────────────────────────────────────────────

  /// Finds direct and one-transfer bus journeys between two places, best first.
  List<BusJourney> findJourneys(BusPlace from, BusPlace to, {int limit = 8}) {
    if (identical(from, to) || from.name == to.name) return const [];
    final originIds = from.stops.map((s) => s.id).toSet();
    final destIds = to.stops.map((s) => s.id).toSet();
    final results = <BusJourney>[];

    // Direct: same line visits an origin stop and later a destination stop.
    final bestDirect = <int, BusJourney>{}; // per line
    for (final o in originIds) {
      for (final v in _visitsByStop[o] ?? const <_StopVisit>[]) {
        final line = v.line;
        for (var j = v.index + 1; j < line.stopIds.length; j++) {
          if (!destIds.contains(line.stopIds[j])) continue;
          final leg = _leg(line, v.index, j);
          final journey = BusJourney(legs: [leg], totalMinutes: leg.rideMinutes + _expectedWait(line));
          final prev = bestDirect[line.id];
          if (prev == null || journey.totalMinutes < prev.totalMinutes) bestDirect[line.id] = journey;
          break;
        }
      }
    }
    results.addAll(bestDirect.values);

    // One transfer: reachable stops from origin, then lines into destination.
    if (results.length < limit) {
      // stopId -> best (arrival minutes, line, board index, alight index)
      final reach = <int, _Reach>{};
      for (final o in originIds) {
        for (final v in _visitsByStop[o] ?? const <_StopVisit>[]) {
          final line = v.line;
          final wait = _expectedWait(line);
          for (var j = v.index + 1; j < line.stopIds.length; j++) {
            final sid = line.stopIds[j];
            if (destIds.contains(sid)) break; // direct handled above
            final t = wait + line.offsets[j] - line.offsets[v.index];
            final prev = reach[sid];
            if (prev == null || t < prev.minutes) reach[sid] = _Reach(t, line, v.index, j);
          }
        }
      }

      final bestTransfer = <String, BusJourney>{}; // per (line1 number, line2 number)
      for (final d in destIds) {
        for (final v in _visitsByStop[d] ?? const <_StopVisit>[]) {
          final line2 = v.line;
          final wait2 = _expectedWait(line2);
          for (var i = v.index - 1; i >= 0; i--) {
            final sid = line2.stopIds[i];
            final ride2 = line2.offsets[v.index] - line2.offsets[i];
            for (final (r, walkM) in _reachAround(reach, sid)) {
              if (r.line.number == line2.number) continue;
              final total = r.minutes + transferPenaltyMinutes + (walkM / 80).round() + wait2 + ride2;
              final key = '${r.line.number}>${line2.number}';
              final prev = bestTransfer[key];
              if (prev != null && prev.totalMinutes <= total) continue;
              bestTransfer[key] = BusJourney(
                legs: [_leg(r.line, r.boardIndex, r.alightIndex), _leg(line2, i, v.index)],
                totalMinutes: total,
                transferWalkMeters: walkM,
              );
            }
          }
        }
      }
      results.addAll(bestTransfer.values);
    }

    results.sort((a, b) {
      final c = a.transfers.compareTo(b.transfers);
      if (c != 0 && (a.totalMinutes - b.totalMinutes).abs() < 25) return c;
      return a.totalMinutes.compareTo(b.totalMinutes);
    });

    // One journey per distinct route-number combination
    final seen = <String>{};
    return results
        .where((j) => seen.add(j.legs.map((l) => l.line.number).join('>')))
        .take(limit)
        .toList();
  }

  Iterable<(_Reach, int)> _reachAround(Map<int, _Reach> reach, int stopId) sync* {
    final here = reach[stopId];
    if (here != null) yield (here, 0);
    final stop = _stops[stopId]!;
    // Same-name stops (other side of the road) count as a short walk
    final place = _placeOfStop[stopId];
    if (place == null) return;
    for (final s in place.stops) {
      if (s.id == stopId) continue;
      final r = reach[s.id];
      if (r == null) continue;
      final km = distanceKm(stop.lat, stop.lon, s.lat, s.lon);
      if (km <= maxTransferWalkKm) yield (r, (km * 1000).round());
    }
  }

  BusLeg _leg(BusLine line, int from, int to) {
    final stops = <BusStopInfo>[for (var i = from; i <= to; i++) _stops[line.stopIds[i]]!];
    var km = 0.0;
    for (var i = 1; i < stops.length; i++) {
      km += distanceKm(stops[i - 1].lat, stops[i - 1].lon, stops[i].lat, stops[i].lon);
    }
    return BusLeg(line: line, fromIndex: from, toIndex: to, stops: stops, distanceKm: km);
  }

  int _expectedWait(BusLine line) {
    final h = line.headwayMinutes;
    if (h == null) return 30;
    return (h / 2).round().clamp(2, 30);
  }

  // ── Schedules ────────────────────────────────────────────────────────────

  /// Scheduled (not live) arrivals of [line] at stop index [stopIndex] after [now].
  /// Trips are assumed evenly spaced between first and last departure.
  List<BusArrival> nextArrivals(BusLine line, int stopIndex, DateTime now, {int count = 3}) {
    final first = line.firstDeparture;
    final last = line.lastDeparture;
    if (first == null || last == null) return const [];
    final offset = line.offsets[stopIndex];
    final midnight = DateTime(now.year, now.month, now.day);
    final nowMin = now.difference(midnight).inMinutes;
    final out = <BusArrival>[];
    final headway = line.headwayMinutes;

    if (headway == null) {
      var t = first + offset;
      if (t < nowMin) t += 24 * 60;
      out.add(BusArrival(line: line, stopIndex: stopIndex, time: midnight.add(Duration(minutes: t))));
      return out;
    }

    // Index of the next trip whose arrival at this stop is >= now
    var k = ((nowMin - offset - first) / headway).ceil();
    if (k < 0) k = 0;
    var dayShift = 0;
    while (out.length < count) {
      final start = first + k * headway;
      if (start > last) {
        // Service over for today -> tomorrow's first trips
        k = 0;
        dayShift += 24 * 60;
        if (dayShift > 24 * 60) break;
        continue;
      }
      final t = start + offset + dayShift;
      out.add(BusArrival(line: line, stopIndex: stopIndex, time: midnight.add(Duration(minutes: t))));
      k++;
    }
    return out;
  }

  /// Upcoming scheduled arrivals of all lines at any stop of [place], soonest first.
  List<BusArrival> departuresAt(BusPlace place, DateTime now, {int limit = 20}) {
    final out = <BusArrival>[];
    for (final s in place.stops) {
      for (final v in _visitsByStop[s.id] ?? const <_StopVisit>[]) {
        if (v.index == v.line.stopIds.length - 1) continue; // terminating here
        out.addAll(nextArrivals(v.line, v.index, now, count: 1));
      }
    }
    out.sort((a, b) => a.time.compareTo(b.time));
    return out.take(limit).toList();
  }

  // ── Realtime helpers ─────────────────────────────────────────────────────

  /// Index of the stop on [line] closest to a vehicle position.
  int nearestStopIndex(BusLine line, double lat, double lon) {
    var best = 0;
    var bestD = double.infinity;
    for (var i = 0; i < line.stopIds.length; i++) {
      final s = _stops[line.stopIds[i]]!;
      final d = distanceKm(lat, lon, s.lat, s.lon);
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  /// Text for a route's endpoints, e.g. "Narela Terminal → Mori Gate".
  String terminiOf(BusLine line) => '${_stops[line.stopIds.first]!.name} → ${_stops[line.stopIds.last]!.name}';

  // ── Utils ────────────────────────────────────────────────────────────────

  static double distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
    return 2 * r * atan2(sqrt(a), sqrt(1 - a));
  }

  int _placeWeight(BusPlace p) =>
      p.stops.fold(0, (a, s) => a + (_visitsByStop[s.id]?.length ?? 0));

  static String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9()+ ]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  /// Feed names are inconsistently cased ("NARELA TERMINAL", "narela terminal").
  static String _cleanName(String s) {
    final t = s.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (t != t.toUpperCase() && t != t.toLowerCase()) return t;
    return t.split(' ').map((w) {
      if (w.isEmpty) return w;
      if (w.length <= 3 && RegExp(r'^[A-Z0-9]+$').hasMatch(w) && RegExp(r'\d').hasMatch(w)) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  static int _compareNumbers(String a, String b) {
    final na = int.tryParse(RegExp(r'^\d+').firstMatch(a)?.group(0) ?? '');
    final nb = int.tryParse(RegExp(r'^\d+').firstMatch(b)?.group(0) ?? '');
    if (na != null && nb != null && na != nb) return na.compareTo(nb);
    if (na != null && nb == null) return -1;
    if (na == null && nb != null) return 1;
    return a.compareTo(b);
  }
}

class _StopVisit {
  final BusLine line;
  final int index;
  const _StopVisit(this.line, this.index);
}

class _Reach {
  final int minutes;
  final BusLine line;
  final int boardIndex;
  final int alightIndex;
  const _Reach(this.minutes, this.line, this.boardIndex, this.alightIndex);
}
