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

  List<MetroStation> get stations => _stations;
  List<MetroRoute> get routes => _routes;
  List<MetroUpdate> get liveUpdates => _liveUpdates;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadStations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('MetroProvider: Starting to load stations...');
      _stations = await _metroService.getStations();
      print('MetroProvider: Loaded ${_stations.length} stations');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('MetroProvider: Error loading stations: $e');
      _error = 'Error loading metro stations: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLiveUpdates() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _liveUpdates = await _metroService.getLiveUpdates();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error loading live updates: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<MetroRoute>> findRoute(String fromStation, String toStation) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _routes = await _metroService.findRoute(fromStation, toStation);
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

  Future<Map<String, dynamic>?> calculateFare(String fromStation, String toStation) async {
    try {
      return await _metroService.calculateFare(fromStation, toStation);
    } catch (e) {
      _error = 'Error calculating fare: $e';
      notifyListeners();
      return null;
    }
  }

  List<MetroStation> findNearestStations(double latitude, double longitude, {int limit = 5}) {
    return _metroService.findNearestStations(latitude, longitude, limit: limit);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

