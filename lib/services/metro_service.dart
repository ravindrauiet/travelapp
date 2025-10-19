import 'dart:math';
import '../models/metro_station.dart';
import '../models/metro_route.dart';
import 'gtfs_data_parser.dart';
import 'metro_data_parser.dart';
import 'simple_gtfs_parser.dart';
import 'working_gtfs_parser.dart';
import 'complete_gtfs_parser.dart';
import 'accurate_fare_calculator.dart';
import 'accurate_route_finder.dart';

class MetroService {
  // Use GTFS data instead of hardcoded stations
  static List<MetroStation>? _stations;

  Future<List<MetroStation>> getStations() async {
    // Load accurate GTFS data if not already loaded
    if (_stations == null) {
      print('MetroService: Starting to load stations...');
      
      try {
        // Try to load from complete GTFS data first
        print('MetroService: Attempting to load complete GTFS data...');
        _stations = await CompleteGTFSParser.getAllStations();
        if (_stations != null && _stations!.isNotEmpty) {
          print('MetroService: Successfully loaded ${_stations!.length} stations from complete GTFS data');
          return _stations!;
        } else {
          print('MetroService: Complete GTFS data returned empty or null');
        }
      } catch (e) {
        print('MetroService: Complete GTFS data loading failed: $e');
      }
      
      try {
        // Try to load from complex GTFS data
        print('MetroService: Attempting to load complex GTFS data...');
        _stations = await GTFSDataParser.getMetroStations();
        if (_stations != null && _stations!.isNotEmpty) {
          print('MetroService: Successfully loaded ${_stations!.length} stations from complex GTFS data');
          return _stations!;
        } else {
          print('MetroService: Complex GTFS data returned empty or null');
        }
      } catch (e) {
        print('MetroService: Complex GTFS data loading failed: $e');
      }
      
      // Fallback to JSON data if GTFS fails
      try {
        print('MetroService: Falling back to JSON data...');
        _stations = await MetroDataParser.getAllStations();
        if (_stations != null && _stations!.isNotEmpty) {
          print('MetroService: Successfully loaded ${_stations!.length} stations from JSON data (fallback)');
          return _stations!;
        } else {
          print('MetroService: JSON data also returned empty or null');
        }
      } catch (e) {
        print('MetroService: JSON data loading also failed: $e');
      }
    }
    
    print('MetroService: Returning ${_stations?.length ?? 0} stations');
    return _stations ?? [];
  }

  Future<List<MetroUpdate>> getLiveUpdates() async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));
    
    return [
      MetroUpdate(
        id: '1',
        stationId: '1',
        stationName: 'Dwarka Sector 21',
        message: 'Normal service on Blue Line',
        type: 'delay',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        severity: 'low',
      ),
      MetroUpdate(
        id: '2',
        stationId: '31',
        stationName: 'Kashmere Gate',
        message: 'Crowded platform, expect delays',
        type: 'delay',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        severity: 'medium',
      ),
      MetroUpdate(
        id: '3',
        stationId: '55',
        stationName: 'Rajiv Chowk',
        message: 'Maintenance work on Platform 2',
        type: 'maintenance',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        severity: 'high',
      ),
    ];
  }

  /// Find optimal route between two stations using accurate algorithms
  Future<List<MetroRoute>> findRoute(String fromStation, String toStation) async {
    if (_stations == null) {
      await getStations(); // This will load stations with fallback
    }
    
    final stations = _stations ?? [];
    
    // Use accurate route finder with Dijkstra's algorithm
    return await AccurateRouteFinder.findOptimalRoute(
      fromStationName: fromStation,
      toStationName: toStation,
      stations: stations,
      travelTime: DateTime.now(),
      isSmartCard: true, // Default to smart card for better pricing
    );
  }
  
  /// Calculate number of stations between two stations on the same line
  int _calculateStationsBetween(MetroStation from, MetroStation to, List<MetroStation> allStations) {
    if (from.line != to.line) return 0;
    
    final stationsOnLine = allStations.where((s) => s.line == from.line).toList();
    final fromIndex = stationsOnLine.indexWhere((s) => s.id == from.id);
    final toIndex = stationsOnLine.indexWhere((s) => s.id == to.id);
    
    if (fromIndex == -1 || toIndex == -1) return 0;
    
    return (toIndex - fromIndex).abs() + 1;
  }

  /// Calculate accurate fare between two stations using official DMRC rates
  Future<double?> calculateFare(String fromStation, String toStation) async {
    if (_stations == null) {
      await getStations(); // This will load stations with fallback
    }
    
    if (_stations == null || _stations!.isEmpty) {
      print('No stations available for fare calculation');
      return null;
    }
    
    try {
      final from = _stations!.firstWhere((s) => s.name.toLowerCase().contains(fromStation.toLowerCase()));
      final to = _stations!.firstWhere((s) => s.name.toLowerCase().contains(toStation.toLowerCase()));
    
      // Calculate distance using accurate method
      final distance = AccurateFareCalculator.calculateDistance(
        from.latitude, from.longitude, 
        to.latitude, to.longitude
      );
      
      // Use accurate fare calculator with official August 2025 rates
      final fareResult = AccurateFareCalculator.calculateFare(
        distance: distance,
        travelTime: DateTime.now(),
        isSmartCard: true,
        isAirportExpress: from.line == 'Airport Express' || to.line == 'Airport Express',
      );
      
      return fareResult.finalFare.toDouble();
    } catch (e) {
      print('Error calculating fare: $e');
      return null;
    }
  }

  List<MetroStation> findNearestStations(double latitude, double longitude, {int limit = 5}) {
    if (_stations == null) return [];
    
    final stationsWithDistance = _stations!.map((station) {
      final distance = _calculateDistance(latitude, longitude, station.latitude, station.longitude);
      return MapEntry(station, distance);
    }).toList();
    
    stationsWithDistance.sort((a, b) => a.value.compareTo(b.value));
    
    return stationsWithDistance.take(limit).map((entry) => entry.key).toList();
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }
}

