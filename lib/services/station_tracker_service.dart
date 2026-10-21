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

  /// Within [StationTrackerService.arrivalRadius] — you are at the station.
  bool get isArrived => distanceMetres < StationTrackerService.arrivalRadius;

  /// Between arrival radius and [StationTrackerService.approachRadius].
  bool get isApproaching =>
      distanceMetres >= StationTrackerService.arrivalRadius &&
      distanceMetres < StationTrackerService.approachRadius;
}

enum TrackerState { idle, loading, active, error }

/// Why tracking could not start / stopped.
enum TrackerIssue { serviceOff, permissionDenied, permissionBlocked, noData, streamFailed }

// ── Route follower stop ───────────────────────────────────────────────────────

class TrackedStop {
  final String name;
  final String line;
  final String lineColor;
  double? latitude; // filled in after route load
  double? longitude;
  bool passed;
  bool isCurrent;

  /// True when the rider changes line at this stop.
  bool isInterchange;

  /// Line to change to at this stop (when [isInterchange]).
  String? changeTo;

  TrackedStop({
    required this.name,
    required this.line,
    required this.lineColor,
    this.latitude,
    this.longitude,
    this.passed = false,
    this.isCurrent = false,
    this.isInterchange = false,
    this.changeTo,
  });
}

// ── Main service ──────────────────────────────────────────────────────────────

/// GPS station proximity alerts and "follow my route" progress.
///
/// * Nearby mode: alerts once when approaching (< [approachRadius]) and once
///   when arriving (< [arrivalRadius]) at a station (10 min cool-down each).
/// * Route mode: ticks off stops as the phone passes within
///   [stopPassRadius]; notifies on interchanges, one stop before the
///   destination, and on arrival — then stops GPS automatically.
/// * On Android tracking keeps running in the background through a
///   foreground-service notification (geolocator).
/// Note: GPS is unreliable in underground sections, so progress may jump
/// several stops at once when the signal returns — that is expected.
class StationTrackerService extends ChangeNotifier {
  static const double arrivalRadius = 120;
  static const double approachRadius = 400;
  static const double stopPassRadius = 250;

  /// Fixes worse than this are ignored for route progress.
  static const double maxUsableAccuracy = 300;
  static const Duration notifyCooldown = Duration(minutes: 10);

  // ── State ──────────────────────────────────────────────────────────────────
  TrackerState _state = TrackerState.idle;
  String? _error;
  TrackerIssue? _issue;
  Position? _position;
  List<NearbyStation> _nearby = [];
  List<MetroStation> _allStations = [];

  // Route follower
  List<TrackedStop> _trackedStops = [];
  int _currentStopIndex = -1;
  String? _routeFrom;
  String? _routeTo;
  bool _loadingRoute = false;
  String? _routeError;
  bool _journeyComplete = false;
  bool _destinationNextNotified = false;

  // Notification cooldown: key → time last notified
  final Map<String, DateTime> _notifiedAt = {};

  StreamSubscription<Position>? _positionSub;

  // ── Getters ────────────────────────────────────────────────────────────────
  TrackerState get state => _state;
  String? get error => _error;
  TrackerIssue? get issue => _issue;
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

  /// Message when the last [loadRoute] failed.
  String? get routeError => _routeError;

  /// True once the destination of the followed route has been reached.
  bool get journeyComplete => _journeyComplete;

  /// Whether opening system settings can fix [issue].
  bool get canFixInSettings =>
      _issue == TrackerIssue.serviceOff || _issue == TrackerIssue.permissionBlocked;

  /// How many stops have been passed (including current).
  int get passedCount => _currentStopIndex < 0 ? 0 : _currentStopIndex + 1;

  /// Remaining stops after current.
  int get remainingStops {
    if (_currentStopIndex < 0) return _trackedStops.length;
    return (_trackedStops.length - 1 - _currentStopIndex).clamp(0, 9999);
  }

  // ── Tracking control ───────────────────────────────────────────────────────

  Future<void> startTracking() async {
    if (_state == TrackerState.active || _state == TrackerState.loading) return;

    _state = TrackerState.loading;
    _error = null;
    _issue = null;
    notifyListeners();

    // 1. Load stations once
    if (_allStations.isEmpty) {
      try {
        _allStations = await GTFSGraphService.getStations();
      } catch (e) {
        _setError(TrackerIssue.noData, 'Could not load station data. Please try again.');
        return;
      }
    }
    if (_allStations.isEmpty) {
      _setError(TrackerIssue.noData, 'No station data available.');
      return;
    }

    // 2. Check / request location permission
    try {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) {
        _setError(TrackerIssue.serviceOff, 'Location (GPS) is turned off. Turn it on to track stations.');
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        _setError(TrackerIssue.permissionBlocked,
            'Location access is blocked for Metromate. Allow it in Settings to use the tracker.');
        return;
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.unableToDetermine) {
        _setError(TrackerIssue.permissionDenied,
            'Location permission is needed to find stations near you. Tap Start to ask again.');
        return;
      }
    } catch (e) {
      _setError(TrackerIssue.streamFailed, 'Location is not available on this device.');
      return;
    }

    // 3. Notification permission (alerts are optional; tracking works without)
    await NotificationService.requestPermission();

    // 4. Initial fix, then stream
    try {
      _position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (_) {
      // Non-fatal — the stream will deliver a fix shortly.
    }

    _positionSub = Geolocator.getPositionStream(locationSettings: _locationSettings()).listen(
      _onPosition,
      onError: (Object e) {
        _positionSub?.cancel();
        _positionSub = null;
        if (e is LocationServiceDisabledException) {
          _setError(TrackerIssue.serviceOff, 'Location (GPS) was turned off. Turn it on and tap Start.');
        } else if (e is PermissionDeniedException) {
          _setError(TrackerIssue.permissionBlocked, 'Location permission was revoked. Allow it in Settings.');
        } else {
          _setError(TrackerIssue.streamFailed, 'Lost the GPS signal. Tap Start to try again.');
        }
      },
    );

    _state = TrackerState.active;
    if (_position != null) _recalculate(_position!);
    notifyListeners();
  }

  LocationSettings _locationSettings() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
        intervalDuration: const Duration(seconds: 5),
        // Keeps GPS updates (and alerts) flowing while the app is in the
        // background; shows a persistent notification while tracking.
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Metromate is tracking your metro trip',
          notificationText: 'Station alerts are on. Open the app and tap Stop to end.',
          notificationChannelName: 'Station tracking',
          notificationIcon: AndroidResource(name: 'ic_notification', defType: 'drawable'),
          enableWakeLock: true,
        ),
      );
    }
    return const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 20);
  }

  /// Stops GPS. Route progress is kept so the timeline stays visible.
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
    _issue = null;
    _state = TrackerState.idle;
    notifyListeners();
  }

  /// Opens the system page that fixes the current [issue].
  Future<void> openSettings() async {
    try {
      if (_issue == TrackerIssue.serviceOff) {
        await Geolocator.openLocationSettings();
      } else {
        await Geolocator.openAppSettings();
      }
    } catch (e) {
      debugPrint('StationTrackerService.openSettings: $e');
    }
  }

  // ── Route follower ─────────────────────────────────────────────────────────

  /// Load the route from [fromName] → [toName] and build [trackedStops].
  Future<void> loadRoute(String fromName, String toName) async {
    _loadingRoute = true;
    _routeFrom = fromName;
    _routeTo = toName;
    _routeError = null;
    _trackedStops = [];
    _currentStopIndex = -1;
    _journeyComplete = false;
    _destinationNextNotified = false;
    notifyListeners();

    try {
      if (fromName.trim().toLowerCase() == toName.trim().toLowerCase()) {
        _routeError = 'Starting and destination station are the same.';
      } else {
        final routes = await GTFSGraphService.findRoute(
          fromName: fromName,
          toName: toName,
          travelTime: DateTime.now(),
          isSmartCard: false,
        );
        if (routes.isEmpty) {
          _routeError = 'No metro route found between $fromName and $toName.';
        } else {
          if (_allStations.isEmpty) _allStations = await GTFSGraphService.getStations();
          setRoute(routes.first);
          if (_position != null) _advanceRoute(_position!);
        }
      }
    } on StationNotFoundException catch (e) {
      _routeError = 'Unknown station: ${e.name}';
    } catch (e) {
      debugPrint('StationTrackerService.loadRoute error: $e');
      _routeError = 'Could not build the route. Please try again.';
    }

    _loadingRoute = false;
    notifyListeners();
  }

  /// Uses [route] as the followed route (also used by tests).
  @visibleForTesting
  void setRoute(MetroRoute route, {List<MetroStation>? stations}) {
    if (stations != null) _allStations = stations;
    _trackedStops = _buildTrackedStops(route);
    _currentStopIndex = -1;
    _journeyComplete = false;
    _destinationNextNotified = false;
    _enrichStopCoords();
  }

  void clearRoute() {
    _trackedStops = [];
    _currentStopIndex = -1;
    _routeFrom = null;
    _routeTo = null;
    _routeError = null;
    _journeyComplete = false;
    notifyListeners();
  }

  // ── Position handling ──────────────────────────────────────────────────────

  void _onPosition(Position pos) {
    _position = pos;
    _recalculate(pos);
  }

  /// Feed a position fix (exposed for tests).
  @visibleForTesting
  void handlePosition(Position pos) => _onPosition(pos);

  void _recalculate(Position pos) {
    if (_allStations.isEmpty) return;

    final list = _allStations.map((s) {
      final d = Geolocator.distanceBetween(pos.latitude, pos.longitude, s.latitude, s.longitude);
      return NearbyStation(station: s, distanceMetres: d, walkMinutes: (d / 80).ceil());
    }).toList()
      ..sort((a, b) => a.distanceMetres.compareTo(b.distanceMetres));

    _nearby = list.take(15).toList();

    if (_trackedStops.isNotEmpty && !_journeyComplete) {
      _advanceRoute(pos);
    } else if (_trackedStops.isEmpty) {
      // Station proximity alerts only when not following a route (while
      // riding, every station passed would otherwise trigger an alert).
      _maybeNotifyNearby();
    }

    notifyListeners();
  }

  bool _cooledDown(String key) {
    final last = _notifiedAt[key];
    return last == null || DateTime.now().difference(last) >= notifyCooldown;
  }

  void _maybeNotifyNearby() {
    if (_nearby.isEmpty) return;
    final top = _nearby.first;
    final id = top.station.id;

    if (top.isArrived) {
      if (_cooledDown('arrive_$id')) {
        NotificationService.showArrivedAtStation(top.station.name);
        _notifiedAt['arrive_$id'] = DateTime.now();
        _notifiedAt['approach_$id'] = DateTime.now(); // no "approaching" after arriving
      }
    } else if (top.isApproaching) {
      if (_cooledDown('approach_$id')) {
        NotificationService.showApproachingStation(top.station.name, top.distanceMetres.round());
        _notifiedAt['approach_$id'] = DateTime.now();
      }
    }
  }

  void _advanceRoute(Position pos) {
    if (_trackedStops.isEmpty || _journeyComplete) return;
    if (pos.accuracy > maxUsableAccuracy) return; // too vague to tick off stops

    // Closest stop ahead (never go backwards).
    final startFrom = _currentStopIndex + 1;
    int? hit;
    double best = double.infinity;
    for (int i = startFrom; i < _trackedStops.length; i++) {
      final stop = _trackedStops[i];
      if (stop.latitude == null || stop.longitude == null) continue;
      final d = Geolocator.distanceBetween(pos.latitude, pos.longitude, stop.latitude!, stop.longitude!);
      if (d < stopPassRadius && d < best) {
        best = d;
        hit = i;
      }
    }
    if (hit == null) return;

    for (int j = 0; j <= hit; j++) {
      _trackedStops[j].passed = true;
      _trackedStops[j].isCurrent = false;
    }
    _trackedStops[hit].isCurrent = true;
    _currentStopIndex = hit;
    final stop = _trackedStops[hit];
    final last = _trackedStops.length - 1;

    if (hit == last) {
      _journeyComplete = true;
      NotificationService.showDestinationReached(stop.name);
      // Destination reached — stop GPS to save battery, keep the timeline.
      _positionSub?.cancel();
      _positionSub = null;
      _state = TrackerState.idle;
      return;
    }

    if (stop.isInterchange && stop.changeTo != null) {
      NotificationService.showInterchangeAlert(stop.name, stop.changeTo!);
    } else if (hit == last - 1 && !_destinationNextNotified) {
      _destinationNextNotified = true;
      NotificationService.showDestinationNext(_trackedStops[last].name);
    } else {
      NotificationService.showRouteProgress(
        currentStation: stop.name,
        nextStation: _trackedStops[hit + 1].name,
        remainingStations: remainingStops,
      );
    }
  }

  List<TrackedStop> _buildTrackedStops(MetroRoute route) {
    final stops = <TrackedStop>[];
    final segs = route.segments;
    for (int s = 0; s < segs.length; s++) {
      final seg = segs[s];
      final isWalk = seg.line == GTFSGraphService.walkLine;
      if (isWalk) {
        // Mark the stop before the walk as the change point.
        if (stops.isNotEmpty) {
          final next = s + 1 < segs.length ? segs[s + 1] : null;
          stops.last
            ..isInterchange = true
            ..changeTo = next != null ? '${next.line} at ${seg.toStation} (walk)' : null;
        }
        continue;
      }
      if (stops.isEmpty || stops.last.name != seg.fromStation) {
        stops.add(TrackedStop(name: seg.fromStation, line: seg.line, lineColor: seg.lineColor));
      }
      for (final mid in seg.intermediateStations) {
        stops.add(TrackedStop(name: mid, line: seg.line, lineColor: seg.lineColor));
      }
      stops.add(TrackedStop(name: seg.toStation, line: seg.line, lineColor: seg.lineColor));
      final next = s + 1 < segs.length ? segs[s + 1] : null;
      if (next != null && next.line != GTFSGraphService.walkLine) {
        stops.last
          ..isInterchange = true
          ..changeTo = next.line == seg.line ? '${next.line} train towards ${next.toStation}' : next.line;
      }
    }
    return stops;
  }

  void _enrichStopCoords() {
    final nameToStation = <String, MetroStation>{
      for (final s in _allStations) s.name.toLowerCase(): s,
    };
    for (final stop in _trackedStops) {
      final match = nameToStation[stop.name.toLowerCase()];
      if (match != null) {
        stop.latitude = match.latitude;
        stop.longitude = match.longitude;
      }
    }
  }

  void _setError(TrackerIssue issue, String msg) {
    _issue = issue;
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
