import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/metro_station.dart';
import '../models/metro_line.dart' as metro_line;

/// Metro Data Parser for reading from existing JSON files
/// Uses the data from assets/data/ folder instead of GTFS files
class MetroDataParser {
  static const String _dataPath = 'assets/data/';
  
  // Cache for parsed data
  static List<MetroStation>? _stations;
  static List<metro_line.MetroLine>? _metroLines;
  static List<BusRoute>? _busRoutes;

  /// Load metro stations from metro_stations.json
  static Future<List<MetroStation>> getMetroStations() async {
    if (_stations != null) return _stations!;
    
    try {
      final data = await rootBundle.loadString('${_dataPath}metro_stations.json');
      final jsonData = json.decode(data);
      
      _stations = (jsonData['stations'] as List).map((stationJson) {
        return MetroStation.fromJson(stationJson);
      }).toList();
      
      print('Successfully loaded ${_stations!.length} metro stations from JSON data');
      return _stations!;
    } catch (e) {
      print('Error loading metro stations: $e');
      return [];
    }
  }

  /// Load metro lines from delhi_metro_2025.json
  static Future<List<metro_line.MetroLine>> getMetroLines() async {
    if (_metroLines != null) return _metroLines!;
    
    try {
      print('MetroDataParser: Loading metro lines from JSON...');
      final data = await rootBundle.loadString('${_dataPath}delhi_metro_2025.json');
      final jsonData = json.decode(data);
      
      print('MetroDataParser: Found ${(jsonData['lines'] as List).length} lines in JSON');
      
      _metroLines = (jsonData['lines'] as List).map((lineJson) {
        final stations = (lineJson['stations'] as List).map((stationJson) {
          return MetroStation(
            id: stationJson['id'],
            name: stationJson['name'],
            line: lineJson['name'],
            lineColor: lineJson['color'],
            latitude: stationJson['lat'],
            longitude: stationJson['lng'],
            facilities: [], // Default empty facilities
            isInterchange: stationJson['interchange'] ?? false,
            interchangeLines: [], // Will be populated based on interchange status
          );
        }).toList();
        
        print('MetroDataParser: Line ${lineJson['name']} has ${stations.length} stations');
        
        return metro_line.MetroLine(
          id: lineJson['id'],
          name: lineJson['name'],
          color: lineJson['color'],
          stations: stations.map((s) => metro_line.MetroStation(
            id: s.id,
            name: s.name,
            latitude: s.latitude,
            longitude: s.longitude,
            isInterchange: s.isInterchange,
          )).toList(),
        );
      }).toList();
      
      // Update interchange lines for stations
      _updateInterchangeLines();
      
      print('Successfully loaded ${_metroLines!.length} metro lines from JSON data');
      return _metroLines!;
    } catch (e) {
      print('Error loading metro lines: $e');
      return [];
    }
  }

  /// Load bus routes from delhi_bus_routes_2025.json
  static Future<List<BusRoute>> getBusRoutes() async {
    if (_busRoutes != null) return _busRoutes!;
    
    try {
      final data = await rootBundle.loadString('${_dataPath}delhi_bus_routes_2025.json');
      final jsonData = json.decode(data);
      
      _busRoutes = (jsonData['routes'] as List).map((routeJson) {
        return BusRoute.fromJson(routeJson);
      }).toList();
      
      print('Successfully loaded ${_busRoutes!.length} bus routes from JSON data');
      return _busRoutes!;
    } catch (e) {
      print('Error loading bus routes: $e');
      return [];
    }
  }

  /// Update interchange lines for stations based on their interchange status
  static void _updateInterchangeLines() {
    if (_metroLines == null) return;
    
    // Create a map of station names to their lines
    final stationToLines = <String, List<String>>{};
    
    for (final line in _metroLines!) {
      for (final station in line.stations) {
        if (station.isInterchange) {
          stationToLines[station.name] ??= [];
          stationToLines[station.name]!.add(line.name);
        }
      }
    }
    
    // Note: The metro_line.MetroStation doesn't have interchangeLines property
    // This is just for compatibility with the main MetroStation class
    print('MetroDataParser: Found ${stationToLines.length} interchange stations');
  }

  /// Get all stations from all lines
  static Future<List<MetroStation>> getAllStations() async {
    print('MetroDataParser: Getting all stations...');
    final lines = await getMetroLines();
    final allStations = <MetroStation>[];
    
    for (final line in lines) {
      // Convert metro_line.MetroStation to MetroStation
      for (final station in line.stations) {
        allStations.add(MetroStation(
          id: station.id,
          name: station.name,
          line: line.name,
          lineColor: line.color,
          latitude: station.latitude,
          longitude: station.longitude,
          facilities: [], // Default empty facilities
          isInterchange: station.isInterchange,
          interchangeLines: [], // Will be populated based on interchange status
        ));
      }
    }
    
    print('MetroDataParser: Returning ${allStations.length} stations from ${lines.length} lines');
    return allStations;
  }

  /// Find station by name
  static Future<MetroStation?> findStationByName(String name) async {
    final stations = await getAllStations();
    
    try {
      return stations.firstWhere(
        (s) => s.name.toLowerCase().contains(name.toLowerCase()),
      );
    } catch (e) {
      return null;
    }
  }

  /// Find stations by line
  static Future<List<MetroStation>> getStationsByLine(String lineName) async {
    final lines = await getMetroLines();
    
    for (final line in lines) {
      if (line.name.toLowerCase() == lineName.toLowerCase()) {
        // Convert metro_line.MetroStation to MetroStation
        return line.stations.map((station) => MetroStation(
          id: station.id,
          name: station.name,
          line: line.name,
          lineColor: line.color,
          latitude: station.latitude,
          longitude: station.longitude,
          facilities: [],
          isInterchange: station.isInterchange,
          interchangeLines: [],
        )).toList();
      }
    }
    
    return [];
  }

  /// Get interchange stations
  static Future<List<MetroStation>> getInterchangeStations() async {
    final stations = await getAllStations();
    return stations.where((s) => s.isInterchange).toList();
  }

  /// Clear cache (useful for testing or data updates)
  static void clearCache() {
    _stations = null;
    _metroLines = null;
    _busRoutes = null;
  }
}

/// Bus Route model for bus data
class BusRoute {
  final String id;
  final String number;
  final String name;
  final List<BusStop> stops;
  final String frequency;
  final String operatingHours;
  final String fromLocation;
  final String toLocation;
  final double totalDistance;
  final int totalTime;
  final double fare;
  final String firstBus;
  final String lastBus;

  BusRoute({
    required this.id,
    required this.number,
    required this.name,
    required this.stops,
    required this.frequency,
    required this.operatingHours,
    required this.fromLocation,
    required this.toLocation,
    required this.totalDistance,
    required this.totalTime,
    required this.fare,
    required this.firstBus,
    required this.lastBus,
  });

  factory BusRoute.fromJson(Map<String, dynamic> json) {
    return BusRoute(
      id: json['id'],
      number: json['number'],
      name: json['name'],
      stops: (json['stops'] as List).map((stop) => BusStop.fromJson(stop)).toList(),
      frequency: json['frequency'],
      operatingHours: json['operating_hours'],
      fromLocation: json['from_location'],
      toLocation: json['to_location'],
      totalDistance: (json['total_distance'] as num).toDouble(),
      totalTime: json['total_time'],
      fare: (json['fare'] as num).toDouble(),
      firstBus: json['first_bus'],
      lastBus: json['last_bus'],
    );
  }
}

/// Bus Stop model
class BusStop {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  BusStop({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  factory BusStop.fromJson(Map<String, dynamic> json) {
    return BusStop(
      id: json['id'],
      name: json['name'],
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lng'] as num).toDouble(),
    );
  }
}
