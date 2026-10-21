import 'package:flutter/material.dart';
import '../models/metro_station.dart';
import '../models/metro_route.dart';
import '../services/metro_service.dart';

class MetroProvider extends ChangeNotifier {
  final MetroService _metroService = MetroService();

  List<MetroStation> _stations = [];
  List<MetroRoute> _routes = [];
  List<MetroUpdate> _liveUpdates = [];
  bool _isLoading = false;
  String? _error;
  RouteFailure? _routeFailure;

  List<MetroStation> get stations => _stations;
  List<MetroRoute> get routes => _routes;
  List<MetroUpdate> get liveUpdates => _liveUpdates;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Reason the last [findRoute] / [calculateFare] call failed (null on success).
  RouteFailure? get routeFailure => _routeFailure;

  Future<void> loadStations() async {
    if (_stations.isNotEmpty) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stations = await _metroService.getStations();
      if (_stations.isEmpty) _error = 'No metro station data available.';
    } catch (e) {
      debugPrint('MetroProvider: Error loading stations: $e');
      _error = 'Could not load metro stations. Please try again.';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadLiveUpdates() async {
    try {
      _liveUpdates = await _metroService.getLiveUpdates();
    } catch (_) {
      _liveUpdates = [];
    }
    notifyListeners();
  }

  /// Finds the fastest route. On failure returns an empty list and sets
  /// [error] (user-friendly message) and [routeFailure].
  Future<List<MetroRoute>> findRoute(String fromStation, String toStation) async {
    _error = null;
    _routeFailure = null;
    try {
      _routes = await _metroService.findRoute(fromStation, toStation);
    } on RouteSearchException catch (e) {
      _routes = [];
      _error = e.message;
      _routeFailure = e.reason;
    } catch (e) {
      _routes = [];
      _error = 'Something went wrong while finding a route. Please try again.';
      _routeFailure = RouteFailure.dataUnavailable;
    }
    notifyListeners();
    return _routes;
  }

  /// Fare for the fastest route between two stations (same computation the
  /// route finder uses). Returns null and sets [error] on failure.
  Future<Map<String, dynamic>?> calculateFare(String fromStation, String toStation) async {
    _error = null;
    _routeFailure = null;
    try {
      return await _metroService.calculateFare(fromStation, toStation);
    } on RouteSearchException catch (e) {
      _error = e.message;
      _routeFailure = e.reason;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Could not calculate the fare. Please try again.';
      _routeFailure = RouteFailure.dataUnavailable;
      notifyListeners();
      return null;
    }
  }

  List<MetroStation> findNearestStations(double latitude, double longitude, {int limit = 5}) {
    return _metroService.findNearestStations(latitude, longitude, limit: limit);
  }

  void clearError() {
    _error = null;
    _routeFailure = null;
    notifyListeners();
  }
}
