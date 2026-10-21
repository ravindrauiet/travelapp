import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/metro_station.dart';
import '../models/metro_route.dart';
import 'accurate_fare_calculator.dart';

/// GTFS-based Delhi Metro route finder (primary finder used by MetroService,
/// the fare calculator and the live station tracker).
///
/// How it works
///   * The graph is built from consecutive stop pairs inside every trip of
///     `assets/gtfs_data/stop_times.txt`, so stations are always in real line
///     order.
///   * Dijkstra runs over (stop, line-pattern) states. Changing line at the same
///     station costs [interchangePenalty] minutes; a handful of official
///     out-of-station interchanges (e.g. Noida Sector 52 ↔ Noida Sector 51) are
///     modelled as walking links.
///   * Blue and Green lines have branches that are served by different trains
///     (Yamuna Bank ↔ Vaishali, Ashok Park Main ↔ Inderlok/Kirti Nagar). They are
///     kept as separate patterns so the planner tells riders to change trains
///     there, while through services (Dwarka ↔ Vaishali) remain one leg.
///   * Segment time = median GTFS arrival-to-arrival time (includes dwell).
///   * Segment distance = GTFS `shape_dist_traveled` difference (track distance).
///   * Fare = ONE DMRC ticket on the total DMRC distance. Airport Express,
///     Aqua Line (NMRC) and Rapid Metro are separate fare systems and need a
///     separate ticket, so each block of consecutive legs on one system is
///     priced once.
class GTFSGraphService {
  // ── tuneable constants ────────────────────────────────────────────────────
  /// Minutes added when changing line inside the same station.
  static const double interchangePenalty = 5.0;

  /// Real extra minutes when changing between separate fare systems (exit the
  /// paid area, buy a new ticket, security check) e.g. Yellow ↔ Airport
  /// Express at New Delhi.
  static const double fareSystemChangeMins = 10.0;

  /// Routing-only weight (not shown as time) that makes the planner avoid an
  /// extra ticket (₹20–₹64 more) unless it saves a lot of real time.
  static const double fareSystemChangeWeight = 20.0;

  /// Routing-only weight per line change, so a direct train is preferred over
  /// a marginally faster route with more changes.
  static const double changeWeight = 3.0;

  /// The bundled GTFS still has the pre-2023 Airport Express timetable
  /// (New Delhi → IGI Airport 23 min). Trains now run at 120 km/h and DMRC
  /// advertises ~19 min, so AEL ride times are scaled accordingly.
  static const double _aelSpeedFactor = 19 / 23;

  // ── cached state ──────────────────────────────────────────────────────────
  static Completer<void>? _initCompleter;
  static Map<String, List<_Edge>>? _graph; // stopId → ride edges
  static Map<String, _StopInfo>? _stopMap; // stopId → info
  static Map<String, List<_Walk>>? _walks; // stopId → walking transfers
  static Map<String, String>? _nameIndex; // normalised name/alias → stopId
  static List<MetroStation>? _stationList;

  /// Optional loader override (tests can read files from disk directly).
  @visibleForTesting
  static Future<String> Function(String assetPath)? assetLoader;

  // ═══════════════════════════════════════════════════════════════════════════
  // Static data patches
  // ═══════════════════════════════════════════════════════════════════════════

  /// Official / current station names for GTFS stops whose names in the
  /// bundled feed are outdated or misspelt. The GTFS name keeps working as an
  /// alias.
  static const Map<String, String> _displayNames = {
    'Huda City Centre': 'Millennium City Centre Gurugram',
    'Dwarka Sector - 21': 'Dwarka Sector 21',
    'Dwarka Sector - 14': 'Dwarka Sector 14',
    'Dwarka Sector - 13': 'Dwarka Sector 13',
    'Dwarka Sector - 12': 'Dwarka Sector 12',
    'Dwarka Sector - 11': 'Dwarka Sector 11',
    'Dwarka Sector - 10': 'Dwarka Sector 10',
    'Dwarka Sector - 9': 'Dwarka Sector 9',
    'Dwarka Sector - 8': 'Dwarka Sector 8',
    'Noida Sec -18': 'Noida Sector 18',
    'Noida Sec -16': 'Noida Sector 16',
    'Noida Sec -15': 'Noida Sector 15',
    'Noida Sec-34': 'Noida Sector 34',
    'Noida Sec-52': 'Noida Sector 52',
    'Noida Sec-61': 'Noida Sector 61',
    'Noida Sec-59': 'Noida Sector 59',
    'Noida Sec-62': 'Noida Sector 62',
    'Mansrover park': 'Mansarovar Park',
    'Seelam Pur': 'Seelampur',
    'Netaji Subash Place': 'Netaji Subhash Place',
    'Subash Nagar': 'Subhash Nagar',
    'Janak Puri West': 'Janakpuri West',
    'Janak Puri East': 'Janakpuri East',
    'Jorbagh': 'Jor Bagh',
    'Chhattarpur': 'Chhatarpur',
    'Gurudronacharya': 'Guru Dronacharya',
    'Barakhamba': 'Barakhamba Road',
    'RK Ashram Marg': 'Ramakrishna Ashram Marg',
    'Jawahar Lal Nehru Stadium': 'Jawaharlal Nehru Stadium',
    'Jasola-Apollo': 'Jasola Apollo',
    'Sector-28': 'Sector 28',
    'Mayur Vihar Ext': 'Mayur Vihar Extension',
    'Anand Vihar': 'Anand Vihar ISBT',
    'Peera Garhi': 'Peeragarhi',
    'Paschim Vihar (West)': 'Paschim Vihar West',
    'Paschim Vihar (East)': 'Paschim Vihar East',
    'Mundka Industrial Area (M.I.A)': 'Mundka Industrial Area',
    'Ghevra Metro station': 'Ghevra',
    'Delhi Cantt.': 'Delhi Cantt',
    'Sir Vishweshwaraiah Moti Bagh': 'Sir M. Vishweshwaraiah Moti Bagh',
    'Sadar Bazar Contonment': 'Sadar Bazar Cantonment',
    'Terminal 1- IGI Airport': 'Terminal 1-IGI Airport',
    'IIT': 'IIT Delhi',
    'Jafrabad': 'Jaffrabad',
    'Major Mohit Sharma Rajender Nagar': 'Major Mohit Sharma Rajendra Nagar',
    'Knowledge Park': 'Knowledge Park II',
    'Phase-I (Rapid Metro)': 'Phase 1 (Rapid Metro)',
    'Raja Nahar Singh': 'Raja Nahar Singh (Ballabhgarh)',
  };

  /// Extra spellings people (and other parts of the app) use. Keys and values
  /// are normalised with [_norm] before use; values may be GTFS or display
  /// names.
  static const Map<String, String> _aliases = {
    'IGI Airport T3': 'IGI Airport',
    'IGI Airport Terminal 3': 'IGI Airport',
    'Airport T3': 'IGI Airport',
    'Terminal 3': 'IGI Airport',
    'T3': 'IGI Airport',
    'IGI Airport T2': 'IGI Airport',
    'Indira Gandhi International Airport': 'IGI Airport',
    'Terminal 1': 'Terminal 1-IGI Airport',
    'IGI Airport T1': 'Terminal 1-IGI Airport',
    'IGI Terminal 1': 'Terminal 1-IGI Airport',
    'T1': 'Terminal 1-IGI Airport',
    'Aerocity': 'Delhi Aerocity',
    'JLN Stadium': 'Jawaharlal Nehru Stadium',
    'Kashmiri Gate': 'Kashmere Gate',
    'ISBT Kashmere Gate': 'Kashmere Gate',
    'Red Fort': 'Lal Quila',
    'Lal Qila': 'Lal Quila',
    'INA': 'Dilli Haat - INA',
    'Delhi Haat INA': 'Dilli Haat - INA',
    'Dilli Haat': 'Dilli Haat - INA',
    'ESI Hospital': 'ESI Basai Darapur',
    'ESI Basaidarapur': 'ESI Basai Darapur',
    'Maya Puri': 'Mayapuri',
    'Shahid Nagar': 'Shaheed Nagar',
    'Shahdara Metro': 'Shahdara',
    'Dabri Mor - South Janakpuri': 'Dabri Mor - Janakpuri South',
    'Dabri Mor': 'Dabri Mor - Janakpuri South',
    'Knowledge Park 2': 'Knowledge Park II',
    'Nizamuddin': 'Sarai Kale Khan - Nizamuddin',
    'Hazrat Nizamuddin': 'Sarai Kale Khan - Nizamuddin',
    'Sarai Kale Khan': 'Sarai Kale Khan - Nizamuddin',
    'New Bus Adda': 'Shaheed Sthal (New Bus Adda)',
    'Shaheed Sthal': 'Shaheed Sthal (New Bus Adda)',
    'Ballabhgarh': 'Raja Nahar Singh (Ballabhgarh)',
    'Huda City Center': 'Huda City Centre',
    'Millennium City Centre': 'Huda City Centre',
    'Millennium City Center': 'Huda City Centre',
    'Guru Tegh Bahadur Nagar GTB Nagar': 'Guru Tegh Bahadur Nagar',
    'GTB Nagar': 'Guru Tegh Bahadur Nagar',
    'Delhi University': 'Vishwavidyalaya',
    'Central Sectt': 'Central Secretariat',
    'Rajiv Chowk CP': 'Rajiv Chowk',
    'Moti Bagh': 'Sir M. Vishweshwaraiah Moti Bagh',
    'South Campus': 'Durgabai Deshmukh South Campus',
    'Mayur Vihar 1': 'Mayur Vihar-I',
    'Mayur Vihar Phase 1': 'Mayur Vihar-I',
    'Mayur Vihar II': 'East Vinod Nagar - Mayur Vihar-II',
    'Yashobhoomi': 'Yashobhoomi Dwarka Sector 25',
    'Dwarka Sector 25': 'Yashobhoomi Dwarka Sector 25',
    'IICC Dwarka Sector 25': 'Yashobhoomi Dwarka Sector 25',
    'Cyber Hub': 'Cyber City (Rapid Metro)',
    'Gurugram Cyber City': 'Cyber City (Rapid Metro)',
    'Noida Sector 52 Aqua': 'Noida Sector 51',
  };

  /// GTFS stops that are physically the same station as another stop
  /// (merged so the line change is an ordinary interchange).
  static const Map<String, String> _mergeStops = {
    '148': '68', // Sikanderpur (Rapid Metro) → Sikanderpur (Yellow Line)
  };

  /// Official out-of-station interchanges (walkway / travelator).
  /// Stop ids from stops.txt, walking time in minutes (incl. waiting).
  static const List<(String, String, double)> _walkLinks = [
    ('234', '500', 5.0), // Noida Sector 52 (Blue) ↔ Noida Sector 51 (Aqua)
    ('156', '181', 10.0), // Dhaula Kuan (AEL) ↔ Durgabai Deshmukh South Campus (Pink)
  ];

  /// Airport Express extension opened in 2023 but missing from the bundled
  /// GTFS feed. Coordinates are approximate; distance is the official 2.2 km.
  static const String _yashobhoomiId = 'X_YASHOBHOOMI';

  // ═══════════════════════════════════════════════════════════════════════════
  // Public API
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<List<MetroStation>> getStations() async {
    await _ensureInit();
    return _stationList ?? [];
  }

  /// Resolve any user / app supplied name (old GTFS spelling, landmark-ish
  /// alias such as "IGI Airport T3", "Noida Sec 18", "Janak Puri West") to the
  /// station name shown in the app. Returns `null` when nothing matches.
  static Future<String?> resolveStationName(String input) async {
    await _ensureInit();
    return resolveStationNameSync(input);
  }

  /// Same as [resolveStationName] but only works after the data is loaded.
  static String? resolveStationNameSync(String input) {
    final s = _matchStop(input);
    return s?.name;
  }

  /// True once GTFS data has been loaded and the graph built.
  static bool get isReady => _graph != null;

  static Future<List<MetroRoute>> findRoute({
    required String fromName,
    required String toName,
    required DateTime travelTime,
    required bool isSmartCard,
  }) async {
    await _ensureInit();
    if (_graph == null || _stopMap == null) return [];

    final from = _matchStop(fromName);
    final to = _matchStop(toName);
    if (from == null) throw StationNotFoundException(fromName);
    if (to == null) throw StationNotFoundException(toName);
    if (from.stopId == to.stopId) return [];

    final result = _dijkstra(from.stopId, to.stopId);
    if (result == null || result.states.length < 2) return [];

    return [_buildRoute(result, from, to, travelTime)];
  }

  /// Clears cached data (tests only).
  @visibleForTesting
  static void reset() {
    _initCompleter = null;
    _graph = null;
    _stopMap = null;
    _walks = null;
    _nameIndex = null;
    _stationList = null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Initialisation — load GTFS files and build graph (once)
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> _ensureInit() async {
    if (_initCompleter != null) return _initCompleter!.future;
    final c = Completer<void>();
    _initCompleter = c;
    try {
      await _loadAndBuild();
      c.complete();
    } catch (e, st) {
      // allow retry on next call
      _initCompleter = null;
      c.completeError(e, st);
      // Mark the future as handled so it does not surface as an uncaught error.
      c.future.ignore();
      rethrow;
    }
  }

  static Future<String> _load(String path) =>
      assetLoader != null ? assetLoader!(path) : rootBundle.loadString(path);

  static Future<void> _loadAndBuild() async {
    // ── 1. Load raw text ───────────────────────────────────────────────────
    final stopsRaw = await _load('assets/gtfs_data/stops.txt');
    final routesRaw = await _load('assets/gtfs_data/routes.txt');
    final tripsRaw = await _load('assets/gtfs_data/trips.txt');
    final stopTimesRaw = await _load('assets/gtfs_data/stop_times.txt');

    // ── 2. Parse stops ─────────────────────────────────────────────────────
    // stops.txt columns: stop_id[0], stop_code[1], stop_name[2],
    //                    stop_desc[3], stop_lat[4], stop_lon[5]
    final stops = <String, _StopInfo>{};
    for (final line in _nonEmpty(stopsRaw).skip(1)) {
      final p = _csv(line);
      if (p.length < 6) continue;
      if (_mergeStops.containsKey(p[0])) continue;
      final rawName = p[2];
      stops[p[0]] = _StopInfo(
        stopId: p[0],
        name: _displayNames[rawName] ?? rawName,
        gtfsName: rawName,
        lat: double.tryParse(p[4]) ?? 0.0,
        lon: double.tryParse(p[5]) ?? 0.0,
      );
    }

    // ── 3. Parse routes → line name ────────────────────────────────────────
    final routeToLine = <String, String>{};
    for (final line in _nonEmpty(routesRaw).skip(1)) {
      final p = _csv(line);
      if (p.length < 4) continue;
      final ln = _lineNameFromRoute(p[3]);
      if (ln.isNotEmpty) routeToLine[p[0]] = ln;
    }

    // ── 4. Parse trips → route_id ──────────────────────────────────────────
    final tripToRoute = <String, String>{};
    for (final line in _nonEmpty(tripsRaw).skip(1)) {
      final p = _csv(line);
      if (p.length < 3) continue;
      tripToRoute[p[2]] = p[0];
    }

    // ── 5. Parse stop_times: collect ordered stops per trip ─────────────────
    // stop_times.txt columns: trip_id[0], arrival_time[1], departure_time[2],
    //   stop_id[3], stop_sequence[4], …, shape_dist_traveled[8] (metres)
    final tripStops = <String, List<_TripStop>>{};
    final tripLine = <String, String>{};
    for (final line in _nonEmpty(stopTimesRaw).skip(1)) {
      final p = _csv(line);
      if (p.length < 5) continue;
      final tripId = p[0];
      final routeId = tripToRoute[tripId];
      if (routeId == null) continue;
      final ln = routeToLine[routeId];
      if (ln == null || ln.isEmpty) continue;
      tripLine[tripId] = ln;
      final stopId = _mergeStops[p[3]] ?? p[3];
      tripStops.putIfAbsent(tripId, () => []).add(_TripStop(
            stopId: stopId,
            sequence: int.tryParse(p[4]) ?? 0,
            arrMins: _timeToMins(p[1]),
            depMins: _timeToMins(p[2]),
            distM: p.length > 8 ? double.tryParse(p[8]) : null,
          ));
    }

    // ── 6. Collect edge samples from consecutive stops in each trip ─────────
    final edgeTimes = <String, List<double>>{};
    final edgeDist = <String, double>{};

    for (final entry in tripStops.entries) {
      final list = entry.value..sort((a, b) => a.sequence.compareTo(b.sequence));
      // Drop consecutive duplicates (created by merged stops).
      final ordered = <_TripStop>[];
      for (final ts in list) {
        if (ordered.isNotEmpty && ordered.last.stopId == ts.stopId) continue;
        ordered.add(ts);
      }
      if (ordered.length < 2) continue;
      final ln = _patternFor(tripLine[entry.key]!, ordered.map((t) => t.stopId));

      for (final ts in ordered) {
        stops[ts.stopId]?.lines.add(ln);
      }

      for (int i = 0; i < ordered.length - 1; i++) {
        final cur = ordered[i];
        final nxt = ordered[i + 1];
        final a = stops[cur.stopId];
        final b = stops[nxt.stopId];
        if (a == null || b == null) continue;

        // Arrival-to-arrival time includes the dwell at the current station.
        double t = nxt.arrMins - cur.arrMins;
        if (t <= 0 || t > 30) {
          final d = AccurateFareCalculator.calculateDistance(a.lat, a.lon, b.lat, b.lon);
          t = (d * 2.0).clamp(1.0, 10.0);
        }

        double distKm;
        if (cur.distM != null && nxt.distM != null && nxt.distM! > cur.distM!) {
          distKm = (nxt.distM! - cur.distM!) / 1000.0;
        } else {
          distKm = AccurateFareCalculator.calculateDistance(a.lat, a.lon, b.lat, b.lon);
        }

        for (final key in [
          '${cur.stopId}::${nxt.stopId}::$ln',
          '${nxt.stopId}::${cur.stopId}::$ln',
        ]) {
          edgeTimes.putIfAbsent(key, () => []).add(t);
          // keep the larger of the two directional measurements (both are
          // track distances; a tiny value usually means a data glitch)
          final prev = edgeDist[key];
          if (prev == null || distKm > prev) edgeDist[key] = distKm;
        }
      }
    }

    // ── 7. Patch: Airport Express extension to Yashobhoomi Dwarka Sector 25 ─
    final sec21 = stops['121'];
    if (sec21 != null) {
      final y = _StopInfo(
        stopId: _yashobhoomiId,
        name: 'Yashobhoomi Dwarka Sector 25',
        gtfsName: 'Yashobhoomi Dwarka Sector 25',
        lat: 28.5560,
        lon: 77.0360,
      );
      y.lines.add('Airport Express');
      stops[y.stopId] = y;
      for (final key in [
        '121::$_yashobhoomiId::Airport Express',
        '$_yashobhoomiId::121::Airport Express',
      ]) {
        edgeTimes[key] = [3.0];
        edgeDist[key] = 2.2;
      }
    }

    // ── 8. Build adjacency list (median time per edge) ─────────────────────
    final graph = <String, List<_Edge>>{for (final id in stops.keys) id: []};
    for (final entry in edgeTimes.entries) {
      final parts = entry.key.split('::');
      final samples = entry.value..sort();
      var t = samples[samples.length ~/ 2];
      final d = edgeDist[entry.key] ?? 0.0;
      // Some trips (e.g. Rapid Metro) carry implausible timings such as 12 min
      // for a 0.6 km hop. Fall back to a typical metro speed in that case.
      if (t > 1.5 + d * 3.0) t = 1.0 + d * 1.8;
      if (parts[2] == 'Airport Express') t *= _aelSpeedFactor;
      graph[parts[0]]!.add(_Edge(
        toStopId: parts[1],
        line: parts[2],
        travelMins: t,
        distKm: d,
      ));
    }

    // ── 9. Walking transfers ───────────────────────────────────────────────
    final walks = <String, List<_Walk>>{};
    for (final (a, b, mins) in _walkLinks) {
      if (!stops.containsKey(a) || !stops.containsKey(b)) continue;
      walks.putIfAbsent(a, () => []).add(_Walk(b, mins));
      walks.putIfAbsent(b, () => []).add(_Walk(a, mins));
    }

    // ── 10. Station list + name index ──────────────────────────────────────
    final stations = <MetroStation>[];
    for (final stop in stops.values) {
      if (stop.lines.isEmpty) continue;
      final baseLines = stop.lines.map(baseLineName).toSet().toList();
      final primary = baseLines.first;
      final walkLines = <String>{
        for (final w in walks[stop.stopId] ?? const <_Walk>[])
          ...stops[w.toStopId]!.lines.map(baseLineName),
      }..removeAll(baseLines);
      stations.add(MetroStation(
        id: stop.stopId,
        name: stop.name,
        line: primary,
        lineColor: lineColor(primary),
        latitude: stop.lat,
        longitude: stop.lon,
        isInterchange: baseLines.length > 1 || walkLines.isNotEmpty,
        interchangeLines: [...baseLines, ...walkLines],
      ));
    }
    stations.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final index = <String, String>{};
    void addKey(String name, String stopId) {
      final k = _norm(name);
      if (k.isEmpty) return;
      index.putIfAbsent(k, () => stopId);
      index.putIfAbsent(k.replaceAll(' ', ''), () => stopId);
    }

    // Display names first (they win on conflicts), then GTFS names.
    for (final s in stops.values) {
      if (s.lines.isNotEmpty) addKey(s.name, s.stopId);
    }
    for (final s in stops.values) {
      if (s.lines.isNotEmpty) addKey(s.gtfsName, s.stopId);
    }
    for (final e in _aliases.entries) {
      final target = index[_norm(e.value)];
      if (target != null) addKey(e.key, target);
    }

    _stopMap = stops;
    _graph = graph;
    _walks = walks;
    _nameIndex = index;
    _stationList = stations;
    debugPrint('GTFSGraph: ready — ${stations.length} stations, '
        '${stations.where((s) => s.isInterchange).length} interchanges');
  }

  /// Splits lines whose branches are run by different trains.
  static String _patternFor(String line, Iterable<String> stopIds) {
    final ids = stopIds.toSet();
    if (line == 'Blue Line' && ids.contains('72')) return 'Blue Line (Vaishali)';
    if (line == 'Green Line' && ids.contains('100')) return 'Green Line (Kirti Nagar)';
    return line;
  }

  /// Line name without the branch qualifier ("Blue Line (Vaishali)" → "Blue Line").
  static String baseLineName(String pattern) {
    final i = pattern.indexOf(' (');
    return i < 0 ? pattern : pattern.substring(0, i);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Dijkstra with (stopId, line) state space
  // ═══════════════════════════════════════════════════════════════════════════

  static _DijkstraResult? _dijkstra(String startId, String endId) {
    final stops = _stopMap!;
    final graph = _graph!;
    final walks = _walks ?? const {};

    if (!stops.containsKey(startId) || !stops.containsKey(endId)) return null;

    // dist = routing cost (time + preference weights), time = real minutes.
    final dist = <String, double>{};
    final time = <String, double>{};
    final prev = <String, String?>{};
    for (final stop in stops.values) {
      for (final ln in stop.lines) {
        dist['${stop.stopId}::$ln'] = double.infinity;
      }
    }
    for (final ln in stops[startId]!.lines) {
      dist['$startId::$ln'] = 0.0;
      time['$startId::$ln'] = 0.0;
      prev['$startId::$ln'] = null;
    }

    final unvisited = Set<String>.from(dist.keys);
    String? reached;

    void relax(String state, double cost, double t, String from) {
      if (!unvisited.contains(state)) return;
      if (cost < (dist[state] ?? double.infinity)) {
        dist[state] = cost;
        time[state] = t;
        prev[state] = from;
      }
    }

    // Extra (time, weight) when switching from line pattern a to b.
    (double, double) changeCost(String a, String b) {
      if (fareSystemFor(a) != fareSystemFor(b)) {
        return (fareSystemChangeMins, fareSystemChangeWeight + changeWeight);
      }
      return (0.0, changeWeight);
    }

    while (unvisited.isNotEmpty) {
      String? cur;
      var minD = double.infinity;
      for (final s in unvisited) {
        final d = dist[s]!;
        if (d < minD) {
          minD = d;
          cur = s;
        }
      }
      if (cur == null) break;
      unvisited.remove(cur);

      final sep = cur.indexOf('::');
      final curStop = cur.substring(0, sep);
      final curLine = cur.substring(sep + 2);
      if (curStop == endId) {
        reached = cur;
        break;
      }

      final curT = time[cur]!;
      // Ride on the same line pattern
      for (final edge in graph[curStop] ?? const <_Edge>[]) {
        if (edge.line != curLine) continue;
        relax('${edge.toStopId}::${edge.line}', minD + edge.travelMins,
            curT + edge.travelMins, cur);
      }
      // Change line inside the station
      for (final other in stops[curStop]!.lines) {
        if (other == curLine) continue;
        final (extraT, extraW) = changeCost(curLine, other);
        final t = interchangePenalty + extraT;
        relax('$curStop::$other', minD + t + extraW, curT + t, cur);
      }
      // Walk to a linked station
      for (final w in walks[curStop] ?? const <_Walk>[]) {
        for (final other in stops[w.toStopId]!.lines) {
          final (extraT, extraW) = changeCost(curLine, other);
          final t = w.minutes + extraT;
          relax('${w.toStopId}::$other', minD + t + extraW, curT + t, cur);
        }
      }
    }

    if (reached == null) return null;
    final path = <String>[];
    String? s = reached;
    while (s != null) {
      path.add(s);
      s = prev[s];
    }
    return _DijkstraResult(states: path.reversed.toList(), totalMins: time[reached]!);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Convert Dijkstra path → MetroRoute
  // ═══════════════════════════════════════════════════════════════════════════

  static MetroRoute _buildRoute(
    _DijkstraResult result,
    _StopInfo from,
    _StopInfo to,
    DateTime travelTime,
  ) {
    final stops = _stopMap!;
    final states = result.states
        .map((s) {
          final i = s.indexOf('::');
          return (s.substring(0, i), s.substring(i + 2));
        })
        .toList();

    // ── Split path into legs: a new leg starts whenever the line changes ───
    // Walking transfers (different stop, different line) become a 'Walk' leg.
    final rawSegments = <_RawSeg>[];
    var segLine = states[0].$2;
    var segStopIds = <String>[states[0].$1];

    for (int i = 1; i < states.length; i++) {
      final (stopId, line) = states[i];
      final prevStop = states[i - 1].$1;
      final isWalk = stopId != prevStop && line != segLine;
      final isChange = stopId == prevStop && line != segLine;
      if (isWalk || isChange) {
        if (segStopIds.length >= 2) {
          rawSegments.add(_RawSeg(stopIds: List.of(segStopIds), line: segLine));
        }
        if (isWalk) {
          rawSegments.add(_RawSeg(stopIds: [prevStop, stopId], line: walkLine));
        }
        segStopIds = [stopId];
        segLine = line;
      } else {
        segStopIds.add(stopId);
      }
    }
    if (segStopIds.length >= 2) {
      rawSegments.add(_RawSeg(stopIds: List.of(segStopIds), line: segLine));
    }

    // Interchange labels between consecutive train legs.
    final interchangeNames = <String>[];
    for (int i = 0; i < rawSegments.length - 1; i++) {
      final a = rawSegments[i];
      final b = rawSegments[i + 1];
      if (a.line == walkLine) continue; // label added from the leg before it
      if (b.line == walkLine) {
        if (i + 2 < rawSegments.length) {
          interchangeNames.add(
              '${stops[b.stopIds.first]!.name} → ${stops[b.stopIds.last]!.name}');
        }
      } else {
        interchangeNames.add(stops[b.stopIds.first]!.name);
      }
    }

    final built = rawSegments.map(_buildSegment).toList();

    // ── Fare: one ticket per fare system block ─────────────────────────────
    final blocks = <_FareBlock>[];
    for (int i = 0; i < built.length; i++) {
      final b = built[i];
      if (b.seg.line == walkLine) continue;
      final sys = fareSystemFor(b.seg.line);
      if (blocks.isEmpty || blocks.last.system != sys) {
        blocks.add(_FareBlock(sys));
      }
      blocks.last.distanceKm += b.distKm;
      blocks.last.segmentIdx.add(i);
    }

    var tokenTotal = 0;
    var cardTotal = 0;
    final segFare = List<double>.filled(built.length, 0);
    final fareLegs = <FareLeg>[];
    for (final blk in blocks) {
      final quote = MetroFare.quote(
        system: blk.system,
        distanceKm: blk.distanceKm,
        when: travelTime,
        fromStation: built[blk.segmentIdx.first].seg.fromStation,
        toStation: built[blk.segmentIdx.last].seg.toStation,
      );
      tokenTotal += quote.tokenFare;
      cardTotal += quote.smartCardFare;
      segFare[blk.segmentIdx.first] = quote.tokenFare.toDouble();
      fareLegs.add(FareLeg(
        system: blk.system,
        fromStation: built[blk.segmentIdx.first].seg.fromStation,
        toStation: built[blk.segmentIdx.last].seg.toStation,
        distanceKm: blk.distanceKm,
        tokenFare: quote.tokenFare,
        smartCardFare: quote.smartCardFare,
      ));
    }

    final finalSegments = <RouteSegment>[
      for (int i = 0; i < built.length; i++)
        RouteSegment(
          line: built[i].seg.line,
          lineColor: built[i].seg.lineColor,
          fromStation: built[i].seg.fromStation,
          toStation: built[i].seg.toStation,
          stationsCount: built[i].seg.stationsCount,
          timeMinutes: built[i].seg.timeMinutes,
          fare: segFare[i],
          intermediateStations: built[i].seg.intermediateStations,
        ),
    ];

    final totalStops = finalSegments.fold(0, (s, seg) => s + seg.stationsCount);
    final totalDist = built.fold(0.0, (s, b) => s + b.distKm);

    return MetroRoute(
      id: '${from.stopId}_${to.stopId}',
      fromStation: from.name,
      toStation: to.name,
      segments: finalSegments,
      totalTime: result.totalMins.round(),
      totalFare: tokenTotal.toDouble(),
      totalStations: totalStops.clamp(1, 999),
      interchangeStations: interchangeNames,
      distanceKm: double.parse(totalDist.toStringAsFixed(1)),
      smartCardFare: cardTotal.toDouble(),
      fareLegs: fareLegs,
    );
  }

  /// Line name used for walking transfer legs.
  static const String walkLine = 'Walk';

  static _BuiltSeg _buildSegment(_RawSeg raw) {
    final stops = _stopMap!;
    final graph = _graph!;
    final fromStop = stops[raw.stopIds.first]!;
    final toStop = stops[raw.stopIds.last]!;

    if (raw.line == walkLine) {
      final mins = (_walks?[fromStop.stopId] ?? const <_Walk>[])
          .firstWhere((w) => w.toStopId == toStop.stopId, orElse: () => const _Walk('', 8))
          .minutes;
      return _BuiltSeg(
        seg: RouteSegment(
          line: walkLine,
          lineColor: '#64748B',
          fromStation: fromStop.name,
          toStation: toStop.name,
          stationsCount: 0,
          timeMinutes: mins.round(),
          fare: 0.0,
        ),
        distKm: 0,
      );
    }

    final intermediates = raw.stopIds.length > 2
        ? raw.stopIds
            .sublist(1, raw.stopIds.length - 1)
            .map((id) => stops[id]?.name ?? id)
            .toList()
        : <String>[];

    double time = 0;
    double dist = 0;
    for (int i = 0; i < raw.stopIds.length - 1; i++) {
      final curId = raw.stopIds[i];
      final nxtId = raw.stopIds[i + 1];
      for (final edge in graph[curId] ?? const <_Edge>[]) {
        if (edge.toStopId == nxtId && edge.line == raw.line) {
          time += edge.travelMins;
          dist += edge.distKm;
          break;
        }
      }
    }

    final base = baseLineName(raw.line);
    final seg = RouteSegment(
      line: base,
      lineColor: lineColor(base),
      fromStation: fromStop.name,
      toStation: toStop.name,
      stationsCount: (raw.stopIds.length - 1).clamp(1, 999),
      timeMinutes: time.round().clamp(1, 999),
      fare: 0.0,
      intermediateStations: intermediates,
    );
    return _BuiltSeg(seg: seg, distKm: dist);
  }

  /// Fare system a line belongs to (separate systems need separate tickets).
  static FareSystem fareSystemFor(String line) {
    final u = line.toUpperCase();
    if (u.contains('AIRPORT')) return FareSystem.airportExpress;
    if (u.contains('AQUA')) return FareSystem.nmrc;
    if (u.contains('RAPID')) return FareSystem.rapidMetro;
    return FareSystem.dmrc;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Station matching
  // ═══════════════════════════════════════════════════════════════════════════

  /// Normalise a station name for matching.
  static String _norm(String s) {
    var t = s.toLowerCase().replaceAll('&', ' and ');
    t = t.replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
    t = t.replaceAll(RegExp(r'\bsec\b'), 'sector');
    t = t.replaceAll(RegExp(r'\brapid metro\b'), ' ');
    t = t.replaceAll(RegExp(r'\bmetro station\b'), ' ');
    t = t.replaceAll(RegExp(r'\bmetro stn\b'), ' ');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t;
  }

  static _StopInfo? _matchStop(String name) {
    final stops = _stopMap;
    final index = _nameIndex;
    if (stops == null || index == null) return null;
    final q = _norm(name);
    if (q.isEmpty) return null;

    final direct = index[q] ?? index[q.replaceAll(' ', '')];
    if (direct != null) return stops[direct];

    // Fuzzy: prefix match first, then contains; shortest name wins.
    if (q.length < 3) return null;
    _StopInfo? best;
    var bestScore = -1;
    for (final s in stops.values) {
      if (s.lines.isEmpty) continue;
      final n = _norm(s.name);
      int score;
      if (n.startsWith(q)) {
        score = 3;
      } else if (n.split(' ').any((w) => w.startsWith(q))) {
        score = 2;
      } else if (n.contains(q)) {
        score = 1;
      } else if (q.contains(n) && n.length >= 5) {
        score = 0;
      } else {
        continue;
      }
      if (score > bestScore ||
          (score == bestScore && best != null && s.name.length < best.name.length)) {
        best = s;
        bestScore = score;
      }
    }
    return best;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Small helpers
  // ═══════════════════════════════════════════════════════════════════════════

  static double _timeToMins(String t) {
    final parts = t.split(':');
    if (parts.length < 3) return 0.0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final s = int.tryParse(parts[2]) ?? 0;
    return h * 60.0 + m + s / 60.0;
  }

  static Iterable<String> _nonEmpty(String raw) =>
      raw.split('\n').map((l) => l.replaceAll('\r', '')).where((l) => l.trim().isNotEmpty);

  static List<String> _csv(String line) {
    final result = <String>[];
    final buf = StringBuffer();
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
    if (u.startsWith('RED_')) return 'Red Line';
    if (u.startsWith('YELLOW_')) return 'Yellow Line';
    if (u.startsWith('BLUE_')) return 'Blue Line';
    if (u.startsWith('GREEN_')) return 'Green Line';
    if (u.startsWith('GRAY_') || u.startsWith('GREY_')) return 'Grey Line';
    if (u.startsWith('VIOLET_')) return 'Violet Line';
    if (u.startsWith('PINK_')) return 'Pink Line';
    if (u.startsWith('MAGENTA_')) return 'Magenta Line';
    if (u.startsWith('AQUA_')) return 'Aqua Line';
    if (u.contains('AIRPORT') || u.startsWith('ORANGE')) return 'Airport Express';
    if (u.startsWith('RAPID_')) return 'Rapid Metro';
    return '';
  }

  /// Hex colour for a line (matches the line colours used in the app theme).
  static String lineColor(String line) {
    switch (baseLineName(line)) {
      case 'Red Line':
        return '#DC2626';
      case 'Yellow Line':
        return '#F59E0B';
      case 'Blue Line':
        return '#1D4ED8';
      case 'Green Line':
        return '#16A34A';
      case 'Violet Line':
        return '#7C3AED';
      case 'Pink Line':
        return '#DB2777';
      case 'Magenta Line':
        return '#C026D3';
      case 'Grey Line':
      case 'Gray Line':
        return '#64748B';
      case 'Aqua Line':
        return '#06B6D4';
      case 'Airport Express':
        return '#EA580C';
      case 'Rapid Metro':
        return '#0284C7';
      default:
        return '#1D4ED8';
    }
  }
}

/// Thrown when a station name cannot be matched to any GTFS station.
class StationNotFoundException implements Exception {
  final String name;
  const StationNotFoundException(this.name);
  @override
  String toString() => 'Station not found: $name';
}

// ═══════════════════════════════════════════════════════════════════════════
// Private data classes
// ═══════════════════════════════════════════════════════════════════════════

class _StopInfo {
  final String stopId;
  final String name; // display name
  final String gtfsName;
  final double lat;
  final double lon;
  final Set<String> lines = {}; // line patterns, populated during build

  _StopInfo({
    required this.stopId,
    required this.name,
    required this.gtfsName,
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

class _Walk {
  final String toStopId;
  final double minutes;
  const _Walk(this.toStopId, this.minutes);
}

class _TripStop {
  final String stopId;
  final int sequence;
  final double arrMins;
  final double depMins;
  final double? distM;

  const _TripStop({
    required this.stopId,
    required this.sequence,
    required this.arrMins,
    required this.depMins,
    required this.distM,
  });
}

class _DijkstraResult {
  final List<String> states; // each = "stopId::linePattern"
  final double totalMins;

  const _DijkstraResult({required this.states, required this.totalMins});
}

class _RawSeg {
  final List<String> stopIds;
  final String line;

  const _RawSeg({required this.stopIds, required this.line});
}

class _BuiltSeg {
  final RouteSegment seg;
  final double distKm;

  const _BuiltSeg({required this.seg, required this.distKm});
}

class _FareBlock {
  final FareSystem system;
  double distanceKm = 0;
  final List<int> segmentIdx = [];
  _FareBlock(this.system);
}
