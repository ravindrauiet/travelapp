import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bus_network.dart';
import '../services/bus_network_service.dart';
import '../services/gtfs_service.dart';

enum BusDataStatus { idle, loading, ready, error }

/// One route number (all its directions) summarised for lists.
class BusRouteSummary {
  const BusRouteSummary({
    required this.number,
    required this.line,
    required this.dailyTrips,
    required this.termini,
    this.headwayMinutes,
  });

  final String number;

  /// The direction with the most trips — the one to open by default.
  final BusLine line;

  /// Scheduled trips per day across all directions.
  final int dailyTrips;
  final int? headwayMinutes;
  final String termini;
}

/// Result of the combined route-number + stop-name search.
class BusSearchResults {
  const BusSearchResults({this.routes = const [], this.places = const []});

  final List<BusRouteSummary> routes;
  final List<BusPlace> places;

  bool get isEmpty => routes.isEmpty && places.isEmpty;
}

/// A served stop near a coordinate, one per [BusPlace] (closest bay wins).
class NearbyBusStop {
  const NearbyBusStop({required this.place, required this.stop, required this.distanceKm});

  final BusPlace place;
  final BusStopInfo stop;
  final double distanceKm;

  int get distanceMeters => (distanceKm * 1000).round();
  int get walkMinutes => BusProvider.walkMinutes(distanceKm);
}

class BusRecentSearch {
  const BusRecentSearch(this.from, this.to);

  final String from;
  final String to;

  String encode() => '$from\u0000$to';

  static BusRecentSearch? decode(String raw) {
    final parts = raw.split('\u0000');
    if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) return null;
    return BusRecentSearch(parts[0], parts[1]);
  }

  @override
  bool operator ==(Object other) => other is BusRecentSearch && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

typedef LiveVehicleFetcher = Future<List<Object>> Function(String routeId);

/// App-wide access to the offline Delhi bus network ([BusNetworkService]) with
/// loading/error state, search helpers, recent trips and live-bus counts.
///
/// Timetable times from the feed are schedule estimates, not live predictions.
class BusProvider extends ChangeNotifier {
  BusProvider({
    BusNetworkService? network,
    Future<void> Function()? loader,
    LiveVehicleFetcher? liveVehicleFetcher,
  })  : network = network ?? BusNetworkService.instance,
        _loader = loader,
        _liveFetcher = liveVehicleFetcher ?? GTFSService.getVehiclesForRoute;

  static const String recentSearchesKey = 'bus_recent_searches';
  static const int maxRecentSearches = 6;

  /// Average walking speed used for walk-time estimates (metres per minute).
  static const double walkMetersPerMinute = 80;

  final BusNetworkService network;
  final Future<void> Function()? _loader;
  final LiveVehicleFetcher _liveFetcher;

  BusDataStatus _status = BusDataStatus.idle;
  String? _error;
  Future<void>? _loading;
  List<BusRouteSummary>? _popular;
  int? _dailyTrips;
  final Map<BusPlace, List<String>> _numbersAtPlace = {};
  List<BusRecentSearch> _recent = const [];
  bool _recentLoaded = false;

  BusDataStatus get status => network.isLoaded ? BusDataStatus.ready : _status;
  bool get isReady => status == BusDataStatus.ready;
  bool get isLoading => status == BusDataStatus.loading || status == BusDataStatus.idle;
  bool get hasError => status == BusDataStatus.error;
  String? get error => hasError ? _error : null;

  // ── Loading ──────────────────────────────────────────────────────────────

  /// Loads the network once; safe to call from every screen's initState.
  Future<void> ensureLoaded() {
    if (network.isLoaded) {
      _status = BusDataStatus.ready;
      return Future.value();
    }
    return _loading ??= _load();
  }

  Future<void> _load() async {
    _status = BusDataStatus.loading;
    _error = null;
    // Don't notify synchronously: callers may be mid-build.
    scheduleMicrotask(notifyListeners);
    try {
      await (_loader ?? network.ensureLoaded)();
      _status = BusDataStatus.ready;
    } catch (e) {
      _status = BusDataStatus.error;
      _error = 'Could not load the bus network. Please try again.';
      debugPrint('BusProvider: load failed: $e');
    } finally {
      _loading = null;
      notifyListeners();
    }
  }

  // ── Network stats ────────────────────────────────────────────────────────

  int get routeCount => network.routeCount;
  int get stopCount => network.stopCount;

  /// Scheduled trips per day across every route and direction.
  int get dailyTrips => _dailyTrips ??= network.lines.fold<int>(0, (a, l) => a + l.tripCount);

  int routeCountForAgency(String agency) =>
      network.lines.where((l) => l.agency == agency).map((l) => l.number).toSet().length;

  // ── Routes ───────────────────────────────────────────────────────────────

  BusRouteSummary? summaryOf(String number) {
    final lines = network.linesByNumber(number);
    if (lines.isEmpty) return null;
    final main = lines.reduce((a, b) => b.tripCount > a.tripCount ? b : a);
    final headways = lines.map((l) => l.headwayMinutes).whereType<int>();
    return BusRouteSummary(
      number: main.number,
      line: main,
      dailyTrips: lines.fold(0, (a, l) => a + l.tripCount),
      headwayMinutes: headways.isEmpty ? null : headways.reduce((a, b) => a < b ? a : b),
      termini: network.terminiOf(main),
    );
  }

  /// Busiest route numbers by scheduled trips per day.
  List<BusRouteSummary> popularRoutes({int limit = 6}) {
    final all = _popular ??= () {
      final trips = <String, int>{};
      for (final l in network.lines) {
        trips[l.number] = (trips[l.number] ?? 0) + l.tripCount;
      }
      final numbers = trips.keys.toList()..sort((a, b) => trips[b]!.compareTo(trips[a]!));
      return numbers.take(20).map(summaryOf).whereType<BusRouteSummary>().toList();
    }();
    return all.take(limit).toList();
  }

  /// All directions/variants of a route number, UP before DOWN.
  List<BusLine> directionsOf(BusLine line) {
    final lines = [...network.linesByNumber(line.number)];
    if (lines.isEmpty) return [line];
    lines.sort((a, b) => _directionRank(a.direction).compareTo(_directionRank(b.direction)));
    return lines;
  }

  static int _directionRank(String d) {
    if (d.startsWith('UP')) return d == 'UP' ? 0 : 1;
    if (d.startsWith('DOWN')) return d == 'DOWN' ? 2 : 3;
    return 4;
  }

  // ── Search ───────────────────────────────────────────────────────────────

  /// Finds route numbers ("764", "534a") and stop names in one query.
  BusSearchResults search(String query, {int routeLimit = 6, int placeLimit = 8}) {
    final q = query.trim();
    if (q.isEmpty || !network.isLoaded) return const BusSearchResults();
    final looksLikeNumber = RegExp(r'\d').hasMatch(q);
    final routes = network
        .searchRoutes(q, limit: looksLikeNumber ? routeLimit : 3)
        .map((l) => summaryOf(l.number))
        .whereType<BusRouteSummary>()
        .toList();
    final places = network.searchPlaces(q, limit: placeLimit);
    return BusSearchResults(routes: routes, places: places);
  }

  /// Stop-name autocomplete, busiest stops first for equal matches.
  List<BusPlace> suggestPlaces(String query, {int limit = 8}) =>
      network.isLoaded ? network.searchPlaces(query, limit: limit) : const [];

  /// Turns typed text into a place: exact name, else the best search hit.
  BusPlace? resolvePlace(String text) {
    final t = text.trim();
    if (t.isEmpty || !network.isLoaded) return null;
    for (final p in network.places) {
      if (p.name.toLowerCase() == t.toLowerCase()) return p;
    }
    final hits = network.searchPlaces(t, limit: 1);
    return hits.isEmpty ? null : hits.first;
  }

  /// Distinct route numbers serving a place, sorted.
  List<String> routeNumbersAt(BusPlace place) => _numbersAtPlace[place] ??= () {
        final seen = <String>{};
        return [
          for (final l in network.linesAtPlace(place))
            if (seen.add(l.number)) l.number,
        ];
      }();

  int routeCountAt(BusPlace place) => routeNumbersAt(place).length;

  List<BusPlace>? _busiest;

  /// Places served by the most route numbers — good one-tap suggestions.
  List<BusPlace> busiestPlaces({int limit = 10}) {
    if (!network.isLoaded) return const [];
    final all = _busiest ??= (network.places.map((p) => (p, routeCountAt(p))).toList()
          ..sort((a, b) => b.$2.compareTo(a.$2)))
        .take(30)
        .map((e) => e.$1)
        .toList();
    return all.take(limit).toList();
  }

  // ── Journeys ─────────────────────────────────────────────────────────────

  /// Direct and one-change journeys. Yields a frame first so a spinner shows.
  Future<List<BusJourney>> findJourneys(BusPlace from, BusPlace to) async {
    await ensureLoaded();
    await Future<void>.delayed(const Duration(milliseconds: 16));
    return network.findJourneys(from, to);
  }

  // ── Nearby ───────────────────────────────────────────────────────────────

  /// Nearest served stops, one per place, closest first.
  List<NearbyBusStop> nearbyStops(double lat, double lon, {int limit = 12, double maxKm = 2}) {
    if (!network.isLoaded) return const [];
    final out = <NearbyBusStop>[];
    final seen = <BusPlace>{};
    for (final (stop, km) in network.nearestStops(lat, lon, limit: limit * 4, maxKm: maxKm)) {
      final place = network.placeOfStop(stop.id);
      if (place == null || !seen.add(place)) continue;
      out.add(NearbyBusStop(place: place, stop: stop, distanceKm: km));
      if (out.length >= limit) break;
    }
    return out;
  }

  static int walkMinutes(double km) => (km * 1000 / walkMetersPerMinute).ceil().clamp(1, 999);

  /// LocationProvider substitutes central Delhi when GPS throws; that is not
  /// the user's location, so screens must not present it as "near you".
  static bool isFallbackPosition(Position p) =>
      p.accuracy == 0 && p.latitude == 28.6139 && p.longitude == 77.2090;

  // ── Recent searches ──────────────────────────────────────────────────────

  List<BusRecentSearch> get recentSearches => _recent;

  Future<void> loadRecentSearches() async {
    if (_recentLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _recent = (prefs.getStringList(recentSearchesKey) ?? const [])
          .map(BusRecentSearch.decode)
          .whereType<BusRecentSearch>()
          .toList();
      _recentLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('BusProvider: could not read recent searches: $e');
    }
  }

  Future<void> addRecentSearch(String from, String to) async {
    final entry = BusRecentSearch(from, to);
    _recent = [entry, ..._recent.where((r) => r != entry)].take(maxRecentSearches).toList();
    notifyListeners();
    await _saveRecent();
  }

  Future<void> removeRecentSearch(BusRecentSearch entry) async {
    _recent = _recent.where((r) => r != entry).toList();
    notifyListeners();
    await _saveRecent();
  }

  Future<void> clearRecentSearches() async {
    _recent = const [];
    notifyListeners();
    await _saveRecent();
  }

  Future<void> _saveRecent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(recentSearchesKey, _recent.map((r) => r.encode()).toList());
    } catch (e) {
      debugPrint('BusProvider: could not save recent searches: $e');
    }
  }

  // ── Live vehicles ────────────────────────────────────────────────────────

  /// Live buses currently reporting on any direction of a route number, or
  /// null when realtime data is unavailable (offline, CORS on web, API down).
  Future<int?> liveBusCount(String number, {Duration timeout = const Duration(seconds: 12)}) async {
    final lines = network.linesByNumber(number);
    if (lines.isEmpty) return null;
    try {
      final results = await Future.wait(lines.map((l) => _liveFetcher('${l.id}'))).timeout(timeout);
      return results.fold<int>(0, (a, r) => a + r.length);
    } catch (e) {
      debugPrint('BusProvider: live buses unavailable for $number: $e');
      return null;
    }
  }
}
