import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/metro_line.dart';
import '../models/bus_route.dart';
import 'gtfs_data_parser.dart';

class MapService {
  static List<MetroLine>? _metroLines;
  static List<BusRoute>? _busRoutes;

  static Future<List<MetroLine>> getMetroLines() async {
    if (_metroLines != null) return _metroLines!;
    
    try {
      // Use accurate GTFS data parser
      _metroLines = await GTFSDataParser.getMetroLines();
      return _metroLines!;
    } catch (e) {
      print('Error loading metro data: $e');
      return [];
    }
  }

  static Future<List<BusRoute>> getBusRoutes() async {
    if (_busRoutes != null) return _busRoutes!;
    
    try {
      final String response = await rootBundle.loadString('assets/data/delhi_bus_routes_2025.json');
      final Map<String, dynamic> data = json.decode(response);
      
      _busRoutes = (data['routes'] as List)
          .map((routeData) => BusRoute.fromJson(routeData))
          .toList();
      
      return _busRoutes!;
    } catch (e) {
      print('Error loading bus data: $e');
      return [];
    }
  }

  static Future<List<MetroStation>> getAllMetroStations() async {
    final lines = await getMetroLines();
    final stations = <MetroStation>[];
    
    for (final line in lines) {
      stations.addAll(line.stations);
    }
    
    return stations;
  }

  static Future<List<BusStop>> getAllBusStops() async {
    final routes = await getBusRoutes();
    final stops = <BusStop>[];
    
    for (final route in routes) {
      stops.addAll(route.stops);
    }
    
    return stops;
  }

  static Future<List<MetroStation>> findNearestMetroStations(
    double latitude, 
    double longitude, 
    {int limit = 5}
  ) async {
    final stations = await getAllMetroStations();
    
    // Calculate distances and sort
    stations.sort((a, b) {
      final distanceA = _calculateDistance(latitude, longitude, a.latitude, a.longitude);
      final distanceB = _calculateDistance(latitude, longitude, b.latitude, b.longitude);
      return distanceA.compareTo(distanceB);
    });
    
    return stations.take(limit).toList();
  }

  static Future<List<BusStop>> findNearestBusStops(
    double latitude, 
    double longitude, 
    {int limit = 5}
  ) async {
    final stops = await getAllBusStops();
    
    // Calculate distances and sort
    stops.sort((a, b) {
      final distanceA = _calculateDistance(latitude, longitude, a.latitude, a.longitude);
      final distanceB = _calculateDistance(latitude, longitude, b.latitude, b.longitude);
      return distanceA.compareTo(distanceB);
    });
    
    return stops.take(limit).toList();
  }

  static Future<List<MetroStation>> findRoute(
    String fromStationId, 
    String toStationId
  ) async {
    final lines = await getMetroLines();
    final allStations = await getAllMetroStations();
    
    // Find stations
    final fromStation = allStations.firstWhere(
      (station) => station.id == fromStationId,
      orElse: () => throw Exception('From station not found'),
    );
    
    final toStation = allStations.firstWhere(
      (station) => station.id == toStationId,
      orElse: () => throw Exception('To station not found'),
    );
    
    // Simple route finding algorithm
    return _findSimpleRoute(fromStation, toStation, lines);
  }

  static List<MetroStation> _findSimpleRoute(
    MetroStation from, 
    MetroStation to, 
    List<MetroLine> lines
  ) {
    // Find which lines the stations are on
    final fromLine = lines.firstWhere((line) => 
      line.stations.any((station) => station.id == from.id));
    final toLine = lines.firstWhere((line) => 
      line.stations.any((station) => station.id == to.id));
    
    if (fromLine.id == toLine.id) {
      // Same line - direct route
      return _getDirectRoute(from, to, fromLine);
    } else {
      // Different lines - need to find interchange
      return _getRouteWithInterchange(from, to, fromLine, toLine, lines);
    }
  }

  static List<MetroStation> _getDirectRoute(
    MetroStation from, 
    MetroStation to, 
    MetroLine line
  ) {
    final fromIndex = line.stations.indexWhere((s) => s.id == from.id);
    final toIndex = line.stations.indexWhere((s) => s.id == to.id);
    
    if (fromIndex == -1 || toIndex == -1) return [];
    
    if (fromIndex < toIndex) {
      return line.stations.sublist(fromIndex, toIndex + 1);
    } else {
      return line.stations.sublist(toIndex, fromIndex + 1).reversed.toList();
    }
  }

  static List<MetroStation> _getRouteWithInterchange(
    MetroStation from, 
    MetroStation to, 
    MetroLine fromLine, 
    MetroLine toLine, 
    List<MetroLine> lines
  ) {
    // Find common interchange stations
    final interchanges = fromLine.stations
        .where((station) => station.isInterchange)
        .where((station) => toLine.stations.any((s) => s.id == station.id))
        .toList();
    
    if (interchanges.isEmpty) return [];
    
    // Use first interchange found
    final interchange = interchanges.first;
    
    final route1 = _getDirectRoute(from, interchange, fromLine);
    final route2 = _getDirectRoute(interchange, to, toLine);
    
    // Combine routes (remove duplicate interchange)
    final combinedRoute = [...route1, ...route2.skip(1)];
    return combinedRoute;
  }

  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = 
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * 
        sin(dLon / 2) * sin(dLon / 2);
    
    final double c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }
}
