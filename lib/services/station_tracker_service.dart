import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/metro_station.dart';
import '../models/metro_route.dart';
import 'gtfs_graph_service.dart';
import 'notification_service.dart';

// ── Data classes ─────────────────────────────────────────────────────────────

class NearbyStation {
  final MetroStation station;
  final double distanceMetres;
  final int walkMinutes; // ~80 m/min walking speed

  const NearbyStation({
    required this.station,
    required this.distanceMetres,
    required this.walkMinutes,
  });

  /// < 100 m — you are here
  bool get isArrived => distanceMetres < 100;

  /// 100–300 m — approaching
  bool get isApproaching => distanceMetres >= 100 && distanceMetres < 300;
}

enum TrackerState { idle, loading, active, error }

// ── Route follower stop ───────────────────────────────────────────────────────

class TrackedStop {
  final String name;
  final String line;
  final String lineColor;
  double? latitude;   // mutable — filled in after route load
  double? longitude;
  bool passed;
  bool isCurrent;

  TrackedStop({
    required this.name,
    required this.line,
    required this.lineColor,
    this.latitude,
    this.longitude,
    this.passed = false,
    this.isCurrent = false,
  });
}

// ── Main service ──────────────────────────────────────────────────────────────

class StationTrackerService extends ChangeNotifier {
  // ── State ──────────────────────────────────────────────────────────────────
  TrackerState _state = TrackerState.idle;
  String? _error;
  Position? _position;
  List<NearbyStation> _nearby = [];
  List<MetroStation> _allStations = [];

  // Route follower
  List<TrackedStop> _trackedStops = [];
  int _currentStopIndex = -1; // index of current stop (-1 = not started)
  String? _routeFrom;
  String? _routeTo;
  bool _loadingRoute = false;

  // Notification cooldown: stationId → time last notified
  final Map<String, DateTime> _notifiedAt = {};

  StreamSubscription<Position>? _positionSub;

  // ── Getters ────────────────────────────────────────────────────────────────
  TrackerState get state => _state;
  String? get error => _error;
  Position? get position => _position;
  List<NearbyStation> get nearby => _nearby;
  NearbyStation? get nearest => _nearby.isNotEmpty ? _nearby.first : null;
  bool get isTracking => _state == TrackerState.active;
  bool get hasRoute => _trackedStops.isNotEmpty;
  List<TrackedStop> get trackedStops => _trackedStops;
  int get currentStopIndex => _currentStopIndex;
  String? get routeFrom => _routeFrom;
  String? get routeTo => _routeTo;
  bool get loadingRoute => _loadingRoute;

  /// How many stops have been passed (including current).
  int get passedCount => _currentStopIndex < 0 ? 0 : _currentStopIndex + 1;

  /// Remaining stops after current.
  int get remainingStops {
    if (_currentStopIndex < 0) return _trackedStops.length;
    return (_trackedStops.length - 1 - _currentStopIndex).clamp(0, 9999);
  }

  // ── Tracking control ───────────────────────────────────────────────────────

  Future<void> startTracking() async {
    if (_state == TrackerState.active) return;

    _state = TrackerState.loading;
    _error = null;
    notifyListeners();

    // 1. Load stations once
    if (_allStations.isEmpty) {
      try {
        _allStations = await GTFSGraphService.getStations();
      } catch (e) {
        _setError('Could not load station data: $e');
        return;
      }
    }
    if (_allStations.isEmpty) {
      _setError('No station data available');
      return;
    }

    // 2. Check / request location permission
    bool serviceOn = await Geolocator.isLocationServiceEnabled();
    if (!serviceOn) {
      _setError('Location services are disabled.\nPlease enable GPS.');
      return;
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      _setError('Location permission denied.\nGo to Settings → App → Location.');
      return;
    }

    // 3. Request notification permission (non-blocking)
    await NotificationService.requestPermission();

    // 4. Get initial position, then stream
    try {
      _position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _recalculate(_position!);
    } catch (_) {
      // Non-fatal — stream will fill position shortly
    }

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20, // fire when user moves ≥20 m
      ),
    ).listen(
      _onPosition,
      onError: (e) => _setError('Location stream error: $e'),
    );

    _state = TrackerState.active;
    notifyListeners();
  }

  void stopTracking() {
    _positionSub?.cancel();
    _positionSub = null;
    _state = TrackerState.idle;
    _position = null;
    _nearby = [];
    _notifiedAt.clear();
    NotificationService.cancelAll();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    _state = TrackerState.idle;
    notifyListeners();
  }

  // ── Route follower ─────────────────────────────────────────────────────────

  /// Load the route from [fromName] → [toName] and build [trackedStops].
  Future<void> loadRoute(String fromName, String toName) async {
    _loadingRoute = true;
    _routeFrom = fromName;
    _routeTo = toName;
    _trackedStops = [];
    _currentStopIndex = -1;
    notifyListeners();

    try {
      final routes = await GTFSGraphService.findRoute(
        fromName: fromName,
        toName: toName,
        travelTime: DateTime.now(),
        isSmartCard: true,
      );

      if (routes.isEmpty) {
        _loadingRoute = false;
        notifyListeners();
        return;
      }

      _trackedStops = _buildTrackedStops(routes.first);
      _currentStopIndex = -1;

      // Map station names → coordinates
      _enrichStopCoords();
    } catch (e) {
      debugPrint('StationTrackerService.loadRoute error: $e');
    }

    _loadingRoute = false;
    notifyListeners();
  }

  void clearRoute() {
    _trackedStops = [];
    _currentStopIndex = -1;
    _routeFrom = null;
    _routeTo = null;
    notifyListeners();
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  void _onPosition(Position pos) {
    _position = pos;
    _recalculate(pos);
  }

  void _recalculate(Position pos) {
    if (_allStations.isEmpty) return;

    // Build sorted nearby list
    final list = _allStations.map((s) {
      final d = Geolocator.distanceBetween(
          pos.latitude, pos.longitude, s.latitude, s.longitude);
      return NearbyStation(
        station: s,
        distanceMetres: d,
        walkMinutes: (d / 80).ceil(),
      );
    }).toList()
      ..sort((a, b) => a.distanceMetres.compareTo(b.distanceMetres));

    _nearby = list.take(15).toList();

    // Fire notifications
    _maybeNotify();

    // Advance route follower
    if (_trackedStops.isNotEmpty) {
      _advanceRoute(pos);
    }

    notifyListeners();
  }

  void _maybeNotify() {
    if (_nearby.isEmpty) return;
    final top = _nearby.first;
    final id = top.station.id;
    final now = DateTime.now();

    // Cooldown: don't re-notify same station within 3 minutes
    final lastTime = _notifiedAt[id];
    if (lastTime != null && now.difference(lastTime).inMinutes < 3) return;

    if (top.isArrived) {
      NotificationService.showArrivedAtStation(top.station.name);
      _notifiedAt[id] = now;
    } else if (top.isApproaching) {
      NotificationService.showApproachingStation(
          top.station.name, top.distanceMetres.round());
      _notifiedAt['${id}_approach'] = now;
    }
  }

  void _advanceRoute(Position pos) {
    // Scan from currentStopIndex+1 forward to find if user reached next stop
    final startFrom = (_currentStopIndex + 1).clamp(0, _trackedStops.length - 1);

    for (int i = startFrom; i < _trackedStops.length; i++) {
      final stop = _trackedStops[i];
      if (stop.latitude == null || stop.longitude == null) continue;

      final d = Geolocator.distanceBetween(
          pos.latitude, pos.longitude, stop.latitude!, stop.longitude!);

      if (d < 200) {
        // Mark everything up to (and including) i as passed
        for (int j = 0; j <= i; j++) {
          _trackedStops[j].passed = true;
          _trackedStops[j].isCurrent = false;
        }
        _trackedStops[i].isCurrent = true;

        if (i > _currentStopIndex) {
          _currentStopIndex = i;

          // Show route progress notification
          final next = i + 1 < _trackedStops.length
              ? _trackedStops[i + 1].name
              : 'Destination';
          NotificationService.showRouteProgress(
            currentStation: stop.name,
            nextStation: next,
            remainingStations: remainingStops,
          );
        }
        break;
      }
    }
  }

  List<TrackedStop> _buildTrackedStops(MetroRoute route) {
    final stops = <TrackedStop>[];
    for (final seg in route.segments) {
      // First station of segment (skip if duplicate from previous segment)
      if (stops.isEmpty || stops.last.name != seg.fromStation) {
        stops.add(TrackedStop(
          name: seg.fromStation,
          line: seg.line,
          lineColor: seg.lineColor,
        ));
      }
      for (final mid in seg.intermediateStations) {
        stops.add(TrackedStop(
          name: mid,
          line: seg.line,
          lineColor: seg.lineColor,
        ));
      }
      stops.add(TrackedStop(
        name: seg.toStation,
        line: seg.line,
        lineColor: seg.lineColor,
      ));
    }
    return stops;
  }

  void _enrichStopCoords() {
    final nameToStation = <String, MetroStation>{};
    for (final s in _allStations) {
      nameToStation[s.name.toLowerCase()] = s;
    }
    for (final stop in _trackedStops) {
      final match = nameToStation[stop.name.toLowerCase()];
      if (match != null) {
        stop.latitude = match.latitude;
        stop.longitude = match.longitude;
      }
    }
  }

  void _setError(String msg) {
    _error = msg;
    _state = TrackerState.error;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }
}
