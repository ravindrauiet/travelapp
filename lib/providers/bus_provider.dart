import 'package:flutter/material.dart';
import '../models/bus_station.dart';
import '../models/bus_route.dart';
import '../services/bus_service.dart';

class BusProvider extends ChangeNotifier {
  final BusService _busService = BusService();
  
  List<BusStation> _stations = [];
  List<BusRoute> _routes = [];
  List<BusTiming> _liveTimings = [];
  bool _isLoading = false;
  String? _error;

  List<BusStation> get stations => _stations;
  List<BusRoute> get routes => _routes;
  List<BusTiming> get liveTimings => _liveTimings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadStations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stations = await _busService.getStations();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error loading bus stations: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLiveTimings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _liveTimings = await _busService.getLiveTimings();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error loading live timings: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<BusRoute>> findRoute(String fromLocation, String toLocation) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _routes = await _busService.findRoute(fromLocation, toLocation);
      _isLoading = false;
      notifyListeners();
      return _routes;
    } catch (e) {
      _error = 'Error finding route: $e';
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  List<BusStation> findNearestStations(double latitude, double longitude, {int limit = 5}) {
    return _busService.findNearestStations(latitude, longitude, limit: limit);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

