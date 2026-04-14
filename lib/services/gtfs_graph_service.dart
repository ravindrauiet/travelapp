import 'dart:async';
import 'package:flutter/services.dart';
import '../models/metro_station.dart';
import '../models/metro_route.dart';
import 'accurate_fare_calculator.dart';

/// Correct GTFS-based Delhi Metro route finder.
///
/// Fixes all six bugs in the previous implementation:
///   1. Builds the graph from consecutive stop pairs in each trip (no sequence
///      corruption from bidirectional trips).
///   2. Uses (stopId, line) states in Dijkstra so stations are visited in the
///      real metro order, not alphabetical order.
///   3. Detects interchange stations by finding stops served by multiple lines.
///   4. Applies a 5-minute interchange penalty only on actual line changes.
///   5. Calculates fare on the TOTAL journey distance with one DMRC ticket.
///   6. Uses actual arrival/departure times from stop_times.txt for segment
///      travel time (falls back to distance × 2 min/km when the GTFS time is
///      missing or implausible).
class GTFSGraphService {
  // ── tuneable constants ────────────────────────────────────────────────────
  static const double _interchangePenalty = 5.0; // minutes per line change

  // ── cached state ──────────────────────────────────────────────────────────
  static Completer<void>? _initCompleter;
  static Map<String, List<_Edge>>? _graph;   // stopId → edges
  static Map<String, _StopInfo>? _stopMap;   // stopId → info
  static List<MetroStation>? _stationList;

  // ═══════════════════════════════════════════════════════════════════════════
  // Public API
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<List<MetroStation>> getStations() async {
    await _ensureInit();
    return _stationList ?? [];
  }

  static Future<List<MetroRoute>> findRoute({
    required String fromName,
    required String toName,
    required DateTime travelTime,
    required bool isSmartCard,
  }) async {
    await _ensureInit();
    if (_graph == null || _stopMap == null) return [];

    final from = _matchStop(fromName);
    final to   = _matchStop(toName);
    if (from == null) throw Exception('Station not found: $fromName');
    if (to   == null) throw Exception('Station not found: $toName');
    if (from.stopId == to.stopId) return [];

    final result = _dijkstra(from.stopId, to.stopId);
    if (result == null || result.states.length < 2) return [];

    return [_buildRoute(result, from, to, travelTime, isSmartCard)];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Initialisation — load GTFS files and build graph (once)
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> _ensureInit() async {
    if (_initCompleter != null) return _initCompleter!.future;
    _initCompleter = Completer<void>();
    try {
      await _loadAndBuild();
      _initCompleter!.complete();
    } catch (e, st) {
      // allow retry on next call
      final c = _initCompleter!;
      _initCompleter = null;
      c.completeError(e, st);
      rethrow;
    }
  }

  static Future<void> _loadAndBuild() async {
    print('GTFSGraph: loading GTFS files…');

    // ── 1. Load raw text ───────────────────────────────────────────────────
    final stopsRaw     = await rootBundle.loadString('assets/gtfs_data/stops.txt');
    final routesRaw    = await rootBundle.loadString('assets/gtfs_data/routes.txt');
    final tripsRaw     = await rootBundle.loadString('assets/gtfs_data/trips.txt');
    final stopTimesRaw = await rootBundle.loadString('assets/gtfs_data/stop_times.txt');

    // ── 2. Parse stops ─────────────────────────────────────────────────────
    // stops.txt columns: stop_id[0], stop_code[1], stop_name[2],
    //                    stop_desc[3], stop_lat[4], stop_lon[5]
    final stops = <String, _StopInfo>{};
    for (final line in _nonEmpty(stopsRaw).skip(1)) {
      final p = _csv(line);
      if (p.length < 6) continue;
      stops[p[0]] = _StopInfo(
        stopId: p[0],
        name:   p[2],
        lat:    double.tryParse(p[4]) ?? 0.0,
        lon:    double.tryParse(p[5]) ?? 0.0,
      );
    }
    print('GTFSGraph: ${stops.length} stops');

    // ── 3. Parse routes → line name ────────────────────────────────────────
    // routes.txt columns: route_id[0], agency_id[1], route_short_name[2],
    //                     route_long_name[3], …
    final routeToLine = <String, String>{};
    for (final line in _nonEmpty(routesRaw).skip(1)) {
      final p = _csv(line);
      if (p.length < 4) continue;
      final ln = _lineNameFromRoute(p[3]);
      if (ln.isNotEmpty) routeToLine[p[0]] = ln;
    }
    print('GTFSGraph: ${routeToLine.length} routes');

    // ── 4. Parse trips → route_id ──────────────────────────────────────────
    // trips.txt columns: route_id[0], service_id[1], trip_id[2], …
    final tripToRoute = <String, String>{};
    for (final line in _nonEmpty(tripsRaw).skip(1)) {
      final p = _csv(line);
      if (p.length < 3) continue;
      tripToRoute[p[2]] = p[0];                 // trip_id → route_id
    }
    print('GTFSGraph: ${tripToRoute.length} trips');

    // ── 5. Parse stop_times: collect ordered stops per trip ─────────────────
    // stop_times.txt columns: trip_id[0], arrival_time[1], departure_time[2],
    //                         stop_id[3], stop_sequence[4], …
    //
    // KEY FIX: group by trip_id and sort by stop_sequence WITHIN each trip.
    // This avoids the "minimum sequence across all trips" bug that collapsed
    // both route endpoints to sequence 0.
    final tripStops = <String, List<_TripStop>>{};
    for (final line in _nonEmpty(stopTimesRaw).skip(1)) {
      final p = _csv(line);
      if (p.length < 5) continue;

      final tripId  = p[0];
      final routeId = tripToRoute[tripId];
      if (routeId == null) continue;
      final ln = routeToLine[routeId];
      if (ln == null || ln.isEmpty) continue;

      tripStops.putIfAbsent(tripId, () => []).add(_TripStop(
        stopId:   p[3],
        sequence: int.tryParse(p[4]) ?? 0,
        arrMins:  _timeToMins(p[1]),
        depMins:  _timeToMins(p[2]),
        line:     ln,
      ));
    }
    print('GTFSGraph: stop_times for ${tripStops.length} trips');

    // ── 6. Build graph edges from consecutive stops in each trip ────────────
    // edge key = "fromStopId::toStopId::lineName" → keep minimum travel time
    final edgeTimeMins = <String, double>{};
    final edgeDistKm   = <String, double>{};

    for (final tripStopList in tripStops.values) {
      // Sort by sequence so we get the correct order for THIS trip
      tripStopList.sort((a, b) => a.sequence.compareTo(b.sequence));
      final ln = tripStopList.first.line;

      // Tag each stop with the lines it serves
      for (final ts in tripStopList) {
        stops[ts.stopId]?.lines.add(ln);
      }

      // Create bidirectional edge between every consecutive pair
      for (int i = 0; i < tripStopList.length - 1; i++) {
        final cur = tripStopList[i];
        final nxt = tripStopList[i + 1];
        if (!stops.containsKey(cur.stopId)) continue;
        if (!stops.containsKey(nxt.stopId)) continue;

        // Travel time from actual GTFS times
        double t = nxt.arrMins - cur.depMins;
        if (t <= 0 || t > 60) {
          // Fall back: distance-based estimate (≈ 2 min/km, 1–10 min clamp)
          final d = AccurateFareCalculator.calculateDistance(
            stops[cur.stopId]!.lat, stops[cur.stopId]!.lon,
            stops[nxt.stopId]!.lat, stops[nxt.stopId]!.lon,
          );
          t = (d * 2.0).clamp(1.0, 10.0);
        }

        final dist = AccurateFareCalculator.calculateDistance(
          stops[cur.stopId]!.lat, stops[cur.stopId]!.lon,
          stops[nxt.stopId]!.lat, stops[nxt.stopId]!.lon,
        );

        // Bidirectional; keep minimum time (best service across all trips)
        for (final key in [
          '${cur.stopId}::${nxt.stopId}::$ln',
          '${nxt.stopId}::${cur.stopId}::$ln',
        ]) {
          if (!edgeTimeMins.containsKey(key) || edgeTimeMins[key]! > t) {
            edgeTimeMins[key] = t;
            edgeDistKm[key]   = dist;
          }
        }
      }
    }

    // ── 7. Build adjacency list ────────────────────────────────────────────
    final graph = <String, List<_Edge>>{};
    for (final stopId in stops.keys) {
      graph[stopId] = [];
    }
    for (final entry in edgeTimeMins.entries) {
      final parts = entry.key.split('::');
      final fromId = parts[0];
      final toId   = parts[1];
      final ln     = parts[2];
      graph[fromId] ??= [];
      graph[fromId]!.add(_Edge(
        toStopId:   toId,
        line:       ln,
        travelMins: entry.value,
        distKm:     edgeDistKm[entry.key] ?? 0.0,
      ));
    }
    print('GTFSGraph: ${graph.length} nodes, ${edgeTimeMins.length} directed edges');

    // ── 8. Build MetroStation list ─────────────────────────────────────────
    final stations = <MetroStation>[];
    for (final stop in stops.values) {
      if (stop.lines.isEmpty) continue;           // not served by any trip
      final primary = stop.lines.first;
      stations.add(MetroStation(
        id:               stop.stopId,
        name:             stop.name,
        line:             primary,
        lineColor:        _lineColor(primary),
        latitude:         stop.lat,
        longitude:        stop.lon,
        isInterchange:    stop.lines.length > 1,
        interchangeLines: stop.lines.toList(),
      ));
    }

    _stopMap     = stops;
    _graph       = graph;
    _stationList = stations;
    print('GTFSGraph: ready — ${stations.length} stations, '
        '${stations.where((s) => s.isInterchange).length} interchange stations');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Dijkstra with (stopId, line) state space
  //
  // Using (stop, line) pairs as states correctly models the fact that
  // arriving at an interchange stop on Line A vs Line B leads to different
  // future costs (because switching lines costs +5 min).
  // ═══════════════════════════════════════════════════════════════════════════

  static _DijkstraResult? _dijkstra(String startId, String endId) {
    final stops = _stopMap!;
    final graph = _graph!;

    if (!stops.containsKey(startId) || !stops.containsKey(endId)) return null;

    // state key = "stopId::lineName"
    final dist = <String, double>{};
    final prev = <String, String?>{};

    // Initialise all (stop, line) states to ∞
    for (final stop in stops.values) {
      for (final ln in stop.lines) {
        final key = '${stop.stopId}::$ln';
        dist[key] = double.infinity;
        prev[key] = null;
      }
    }

    // Source: distance 0 for every line at the start stop
    for (final ln in stops[startId]!.lines) {
      dist['$startId::$ln'] = 0.0;
    }

    final unvisited = Set<String>.from(dist.keys);

    while (unvisited.isNotEmpty) {
      // Find unvisited state with minimum distance (O(n) — fine for ~3 000 states)
      String? cur;
      var minD = double.infinity;
      for (final s in unvisited) {
        if ((dist[s] ?? double.infinity) < minD) {
          minD = dist[s]!;
          cur  = s;
        }
      }

      if (cur == null || minD == double.infinity) break;

      final curParts = cur.split('::');
      final curStop  = curParts[0];
      final curLine  = curParts[1];

      // Early exit once we settle any state at the destination
      if (curStop == endId) break;

      unvisited.remove(cur);

      // ── Travel on the same line ──────────────────────────────────────────
      for (final edge in graph[curStop] ?? []) {
        if (edge.line != curLine) continue;
        final nxtState = '${edge.toStopId}::${edge.line}';
        if (!unvisited.contains(nxtState)) continue;
        final newD = minD + edge.travelMins;
        if (newD < (dist[nxtState] ?? double.infinity)) {
          dist[nxtState] = newD;
          prev[nxtState] = cur;
        }
      }

      // ── Interchange: switch line at the same physical stop ───────────────
      // KEY FIX: interchange penalty applied only when line actually changes.
      if (stops[curStop]!.lines.length > 1) {
        for (final otherLine in stops[curStop]!.lines) {
          if (otherLine == curLine) continue;
          final transferState = '$curStop::$otherLine';
          if (!unvisited.contains(transferState)) continue;
          final newD = minD + _interchangePenalty;
          if (newD < (dist[transferState] ?? double.infinity)) {
            dist[transferState] = newD;
            prev[transferState] = cur;
          }
        }
      }
    }

    // Pick best arrival state at destination
    String? bestState;
    var bestDist = double.infinity;
    for (final ln in stops[endId]!.lines) {
      final state = '$endId::$ln';
      if ((dist[state] ?? double.infinity) < bestDist) {
        bestDist = dist[state]!;
        bestState = state;
      }
    }
    if (bestState == null || bestDist == double.infinity) return null;

    // Reconstruct path (list of "stopId::line" states, source → destination)
    final path = <String>[];
    String? cur = bestState;
    while (cur != null) {
      path.insert(0, cur);
      cur = prev[cur];
    }

    return _DijkstraResult(states: path, totalMins: bestDist);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Convert Dijkstra path → MetroRoute
  // ═══════════════════════════════════════════════════════════════════════════

  static MetroRoute _buildRoute(
    _DijkstraResult result,
    _StopInfo       from,
    _StopInfo       to,
    DateTime        travelTime,
    bool            isSmartCard,
  ) {
    final stops  = _stopMap!;
    final states = result.states;

    // ── Split path into line segments ──────────────────────────────────────
    // A line segment is a consecutive run of states on the same line.
    // Interchange = same stopId appears twice with different lines.
    final rawSegments    = <_RawSeg>[];
    final interchangeNames = <String>[];

    var segLine    = states[0].split('::')[1];
    var segStopIds = [states[0].split('::')[0]];

    for (int i = 1; i < states.length; i++) {
      final parts  = states[i].split('::');
      final stopId = parts[0];
      final line   = parts[1];

      if (stopId == segStopIds.last) {
        // Same physical stop, different line → interchange
        rawSegments.add(_RawSeg(stopIds: List.from(segStopIds), line: segLine));
        interchangeNames.add(stops[stopId]?.name ?? stopId);
        segStopIds = [stopId];
        segLine    = line;
      } else {
        segStopIds.add(stopId);
      }
    }
    rawSegments.add(_RawSeg(stopIds: List.from(segStopIds), line: segLine));

    // ── Build RouteSegment objects (with actual edge times) ────────────────
    final segments = rawSegments
        .where((s) => s.stopIds.length >= 2)
        .map((s) => _buildSegment(s))
        .toList();

    // ── Fare: ONE calculation on the TOTAL journey distance ────────────────
    // KEY FIX: previously each segment was billed independently, causing
    // inflated fares on interchange routes.
    double totalDistKm = 0.0;
    for (int i = 0; i < states.length - 1; i++) {
      final aId = states[i].split('::')[0];
      final bId = states[i + 1].split('::')[0];
      if (aId == bId) continue;                 // interchange walk — no distance
      final a = stops[aId];
      final b = stops[bId];
      if (a != null && b != null) {
        totalDistKm += AccurateFareCalculator.calculateDistance(
            a.lat, a.lon, b.lat, b.lon);
      }
    }

    final hasAEL = segments.any((s) => s.seg.line == 'Airport Express');
    final fareResult = AccurateFareCalculator.calculateFareComparison(
      distance:        totalDistKm,
      travelTime:      travelTime,
      isAirportExpress: hasAEL,
    );
    final totalFare =
        (isSmartCard ? fareResult.smartCardFare : fareResult.ticketFare)
            .toDouble();

    // Distribute fare to segments proportionally by segment distance
    final segDists = segments
        .map((s) => _segDistKm(s.stopIdsForFare, stops))
        .toList();
    final sumDist = segDists.fold(0.0, (a, b) => a + b);

    final finalSegments = List.generate(segments.length, (i) {
      final ratio = sumDist > 0 ? segDists[i] / sumDist : 1.0 / segments.length;
      return RouteSegment(
        line:                 segments[i].seg.line,
        lineColor:            segments[i].seg.lineColor,
        fromStation:          segments[i].seg.fromStation,
        toStation:            segments[i].seg.toStation,
        stationsCount:        segments[i].seg.stationsCount,
        timeMinutes:          segments[i].seg.timeMinutes,
        fare:                 totalFare * ratio,
        intermediateStations: segments[i].seg.intermediateStations,
      );
    });

    // Total stations = sum of segment sizes minus shared interchange stops
    final totalStations = finalSegments.fold(0, (s, seg) => s + seg.stationsCount)
        - (finalSegments.length - 1);

    return MetroRoute(
      id:                  '${from.stopId}_${to.stopId}',
      fromStation:         from.name,
      toStation:           to.name,
      segments:            finalSegments,
      totalTime:           result.totalMins.round(),
      totalFare:           totalFare,
      totalStations:       totalStations.clamp(1, 999),
      interchangeStations: interchangeNames,
    );
  }

  // ── Build a single RouteSegment from an ordered list of stopIds ────────────
  static _BuiltSeg _buildSegment(_RawSeg raw) {
    final stops = _stopMap!;
    final graph = _graph!;
    final fromStop = stops[raw.stopIds.first]!;
    final toStop   = stops[raw.stopIds.last]!;

    final intermediates = raw.stopIds.length > 2
        ? raw.stopIds
            .sublist(1, raw.stopIds.length - 1)
            .map((id) => stops[id]?.name ?? id)
            .toList()
        : <String>[];

    // Sum actual edge travel times from the graph
    int timeMinutes = 0;
    for (int i = 0; i < raw.stopIds.length - 1; i++) {
      final curId = raw.stopIds[i];
      final nxtId = raw.stopIds[i + 1];
      double t    = 2.0; // fallback
      for (final edge in graph[curId] ?? []) {
        if (edge.toStopId == nxtId && edge.line == raw.line) {
          t = edge.travelMins;
          break;
        }
      }
      timeMinutes += t.ceil();
    }

    final seg = RouteSegment(
      line:                 raw.line,
      lineColor:            _lineColor(raw.line),
      fromStation:          fromStop.name,
      toStation:            toStop.name,
      stationsCount:        raw.stopIds.length,
      timeMinutes:          timeMinutes,
      fare:                 0.0,               // overwritten in _buildRoute
      intermediateStations: intermediates,
    );

    return _BuiltSeg(seg: seg, stopIdsForFare: List.from(raw.stopIds));
  }

  // Distance for a list of ordered stop IDs (km)
  static double _segDistKm(List<String> stopIds, Map<String, _StopInfo> stops) {
    double d = 0.0;
    for (int i = 0; i < stopIds.length - 1; i++) {
      final a = stops[stopIds[i]];
      final b = stops[stopIds[i + 1]];
      if (a != null && b != null) {
        d += AccurateFareCalculator.calculateDistance(a.lat, a.lon, b.lat, b.lon);
      }
    }
    return d == 0.0 ? 1.0 : d;   // avoid div-by-zero
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Station matching
  // ═══════════════════════════════════════════════════════════════════════════

  static _StopInfo? _matchStop(String name) {
    if (_stopMap == null) return null;
    final q = name.toLowerCase().trim();

    // 1. Exact match
    for (final s in _stopMap!.values) {
      if (s.name.toLowerCase() == q) return s;
    }
    // 2. Query contained in stop name
    for (final s in _stopMap!.values) {
      if (s.name.toLowerCase().contains(q)) return s;
    }
    // 3. Stop name contained in query
    for (final s in _stopMap!.values) {
      if (q.contains(s.name.toLowerCase())) return s;
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Small helpers
  // ═══════════════════════════════════════════════════════════════════════════

  /// Parse GTFS time "HH:MM:SS" (may exceed 24 h) → total minutes as double.
  static double _timeToMins(String t) {
    final parts = t.split(':');
    if (parts.length < 3) return 0.0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final s = int.tryParse(parts[2]) ?? 0;
    return h * 60.0 + m + s / 60.0;
  }

  /// Split raw GTFS text into non-empty lines.
  static Iterable<String> _nonEmpty(String raw) =>
      raw.split('\n').where((l) => l.trim().isNotEmpty);

  /// Parse one CSV line handling double-quoted fields.
  static List<String> _csv(String line) {
    final result = <String>[];
    final buf    = StringBuffer();
    var inQ = false;
    for (int i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        inQ = !inQ;
      } else if (c == ',' && !inQ) {
        result.add(buf.toString().trim());
        buf.clear();
      } else {
        buf.write(c);
      }
    }
    result.add(buf.toString().trim());
    return result;
  }

  /// Map GTFS route_long_name (e.g. "RED_Rithala to Dilshad Garden") → line name.
  static String _lineNameFromRoute(String routeLongName) {
    final u = routeLongName.toUpperCase();
    // Order matters: GREEN_ before GRAY_ to avoid partial-match conflicts.
    if (u.startsWith('RED_'))      return 'Red Line';
    if (u.startsWith('YELLOW_'))   return 'Yellow Line';
    if (u.startsWith('BLUE_'))     return 'Blue Line';
    if (u.startsWith('GREEN_'))    return 'Green Line';
    if (u.startsWith('GRAY_') || u.startsWith('GREY_')) return 'Gray Line';
    if (u.startsWith('VIOLET_'))   return 'Violet Line';
    if (u.startsWith('PINK_'))     return 'Pink Line';
    if (u.startsWith('MAGENTA_'))  return 'Magenta Line';
    if (u.startsWith('AQUA_'))     return 'Aqua Line';
    if (u.contains('AIRPORT') || u.startsWith('ORANGE')) return 'Airport Express';
    if (u.startsWith('RAPID_'))    return 'Rapid Metro';
    return '';
  }

  static String _lineColor(String line) {
    switch (line) {
      case 'Red Line':       return '#D32F2F';
      case 'Yellow Line':    return '#FBC02D';
      case 'Blue Line':      return '#1976D2';
      case 'Green Line':     return '#388E3C';
      case 'Violet Line':    return '#7B1FA2';
      case 'Pink Line':      return '#E91E63';
      case 'Magenta Line':   return '#C2185B';
      case 'Gray Line':      return '#616161';
      case 'Aqua Line':      return '#00BCD4';
      case 'Airport Express':return '#FF5722';
      case 'Rapid Metro':    return '#795548';
      default:               return '#1976D2';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Private data classes
// ═══════════════════════════════════════════════════════════════════════════

class _StopInfo {
  final String     stopId;
  final String     name;
  final double     lat;
  final double     lon;
  final Set<String> lines = {};          // populated during graph build

  _StopInfo({
    required this.stopId,
    required this.name,
    required this.lat,
    required this.lon,
  });
}

class _Edge {
  final String toStopId;
  final String line;
  final double travelMins;
  final double distKm;

  const _Edge({
    required this.toStopId,
    required this.line,
    required this.travelMins,
    required this.distKm,
  });
}

class _TripStop {
  final String stopId;
  final int    sequence;
  final double arrMins;
  final double depMins;
  final String line;

  const _TripStop({
    required this.stopId,
    required this.sequence,
    required this.arrMins,
    required this.depMins,
    required this.line,
  });
}

class _DijkstraResult {
  final List<String> states;    // each = "stopId::lineName"
  final double       totalMins;

  const _DijkstraResult({required this.states, required this.totalMins});
}

class _RawSeg {
  final List<String> stopIds;
  final String       line;

  const _RawSeg({required this.stopIds, required this.line});
}

class _BuiltSeg {
  final RouteSegment seg;
  final List<String> stopIdsForFare;

  const _BuiltSeg({required this.seg, required this.stopIdsForFare});
}
