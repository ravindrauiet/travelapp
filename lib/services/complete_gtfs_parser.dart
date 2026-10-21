import 'package:flutter/services.dart';
import '../models/metro_station.dart';

/// Complete GTFS Parser that uses stop_times.txt to get all stations
class CompleteGTFSParser {
  static List<MetroStation>? _stations;

  /// Load all metro stations from GTFS data using stop_times.txt
  static Future<List<MetroStation>> getAllStations() async {
    if (_stations != null) return _stations!;

    try {
      print('CompleteGTFS: Loading GTFS data...');
      
      // Load stops data
      final stopsData = await rootBundle.loadString('assets/gtfs_data/stops.txt');
      final stopsLines = stopsData.split('\n').where((line) => line.trim().isNotEmpty).toList();
      
      // Load routes data
      final routesData = await rootBundle.loadString('assets/gtfs_data/routes.txt');
      final routesLines = routesData.split('\n').where((line) => line.trim().isNotEmpty).toList();
      
      // Load stop_times data to get all stations that are actually served
      final stopTimesData = await rootBundle.loadString('assets/gtfs_data/stop_times.txt');
      final stopTimesLines = stopTimesData.split('\n').where((line) => line.trim().isNotEmpty).toList();
      
      // Load trips data to map trip_id to route_id
      final tripsData = await rootBundle.loadString('assets/gtfs_data/trips.txt');
      final tripsLines = tripsData.split('\n').where((line) => line.trim().isNotEmpty).toList();
      
      print('CompleteGTFS: Loaded ${stopsLines.length} stop lines, ${routesLines.length} route lines, ${stopTimesLines.length} stop_times lines, ${tripsLines.length} trips lines');
      
      // Parse stops into a map for quick lookup
      final stopsMap = <String, Map<String, String>>{};
      for (int i = 1; i < stopsLines.length; i++) {
        final stopParts = _parseCsvLine(stopsLines[i]);
        if (stopParts.length >= 6) {
          stopsMap[stopParts[0]] = {
            'id': stopParts[0],
            'name': stopParts[2],
            'lat': stopParts[4],
            'lon': stopParts[5],
          };
        }
      }
      
      // Parse routes: route_id -> line info (name and color)
      // Routes format: COLOR_Route Name (e.g., RED_Dilshad Garden to Rithala, VIOLET_Kashmere Gate to Badarpur Border)
      final routeToLineMap = <String, Map<String, String>>{};
      for (int i = 1; i < routesLines.length; i++) {
        final routeParts = _parseCsvLine(routesLines[i]);
        if (routeParts.length >= 4) {
          final routeId = routeParts[0];
          final routeLongName = routeParts[3];
          final upperName = routeLongName.toUpperCase();
          
          String lineName = 'Unknown Line';
          String lineColor = '#1976D2';
          
          if (upperName.startsWith('RED_')) {
            lineName = 'Red Line';
            lineColor = '#CC0000';
          } else if (upperName.startsWith('YELLOW_')) {
            lineName = 'Yellow Line';
            lineColor = '#FFD700';
          } else if (upperName.startsWith('BLUE_')) {
            lineName = 'Blue Line';
            lineColor = '#0066CC';
          } else if (upperName.startsWith('GREEN_')) {
            lineName = 'Green Line';
            lineColor = '#00AA00';
          } else if (upperName.startsWith('VIOLET_')) {
            lineName = 'Violet Line';
            lineColor = '#800080';
          } else if (upperName.startsWith('PINK_')) {
            lineName = 'Pink Line';
            lineColor = '#FF69B4';
          } else if (upperName.startsWith('MAGENTA_')) {
            lineName = 'Magenta Line';
            lineColor = '#FF00FF';
          } else if (upperName.startsWith('GRAY_')) {
            lineName = 'Gray Line';
            lineColor = '#808080';
          } else if (upperName.startsWith('AQUA_')) {
            lineName = 'Aqua Line';
            lineColor = '#00FFFF';
          } else if (upperName.startsWith('ORANGE/AIRPORT_') || upperName.startsWith('ORANGE_') || upperName.contains('AIRPORT_')) {
            lineName = 'Airport Express';
            lineColor = '#FF8C00';
          } else if (upperName.startsWith('RAPID_')) {
            lineName = 'Rapid Metro';
            lineColor = '#FF1493';
          }
          
          routeToLineMap[routeId] = {
            'lineName': lineName,
            'lineColor': lineColor,
          };
        }
      }
      
      // Parse trips: trip_id -> route_id
      final tripToRouteMap = <String, String>{};
      for (int i = 1; i < tripsLines.length; i++) {
        final tripParts = _parseCsvLine(tripsLines[i]);
        if (tripParts.length >= 3) {
          tripToRouteMap[tripParts[2]] = tripParts[0]; // trip_id -> route_id
        }
      }
      
      print('CompleteGTFS: Parsed ${stopsMap.length} stops, ${routeToLineMap.length} routes, ${tripToRouteMap.length} trips');
      
      // Map stop_id -> line info using stop_times -> trips -> routes
      // For stations on multiple lines (interchanges), use the most common line
      final stopLineCounts = <String, Map<String, int>>{}; // stopId -> lineName -> count
      for (int i = 1; i < stopTimesLines.length; i++) {
        final stopTimeParts = _parseCsvLine(stopTimesLines[i]);
        if (stopTimeParts.length >= 4) {
          final tripId = stopTimeParts[0]; // trip_id is at index 0
          final stopId = stopTimeParts[3]; // stop_id is at index 3
          
          // Get route_id from trip_id
          final routeId = tripToRouteMap[tripId];
          if (routeId == null) continue;
          
          // Get line info from route_id
          final lineInfo = routeToLineMap[routeId];
          if (lineInfo == null) continue;
          
          final lineName = lineInfo['lineName']!;
          
          // Count occurrences of each line for this stop
          if (!stopLineCounts.containsKey(stopId)) {
            stopLineCounts[stopId] = {};
          }
          stopLineCounts[stopId]![lineName] = (stopLineCounts[stopId]![lineName] ?? 0) + 1;
        }
      }
      
      // Determine the primary line for each stop (most common)
      final stopToLineMap = <String, Map<String, String>>{};
      for (final entry in stopLineCounts.entries) {
        final stopId = entry.key;
        final lineCounts = entry.value;
        
        // Find the line with the highest count
        String mostCommonLine = 'Unknown Line';
        int maxCount = 0;
        for (final lineEntry in lineCounts.entries) {
          if (lineEntry.value > maxCount) {
            maxCount = lineEntry.value;
            mostCommonLine = lineEntry.key;
          }
        }
        
        // Get the color for the most common line
        final lineColor = _getLineColorFromLineName(mostCommonLine);
        
        stopToLineMap[stopId] = {
          'lineName': mostCommonLine,
          'lineColor': lineColor,
        };
      }
      
      print('CompleteGTFS: Mapped ${stopToLineMap.length} stops to lines based on route data');
      
      // Get all unique stop IDs
      final servedStopIds = stopToLineMap.keys.toSet();
      
      print('CompleteGTFS: Found ${servedStopIds.length} unique stations served by metro');
      
      // Convert served stops to stations
      _stations = <MetroStation>[];
      for (final stopId in servedStopIds) {
        if (stopsMap.containsKey(stopId)) {
          final stopData = stopsMap[stopId]!;
          final stationName = stopData['name']!;
          final latitude = double.tryParse(stopData['lat']!) ?? 0.0;
          final longitude = double.tryParse(stopData['lon']!) ?? 0.0;
          
          // Get line info from route-based mapping
          final lineInfo = stopToLineMap[stopId];
          final lineName = lineInfo?['lineName'] ?? 'Unknown Line';
          final lineColor = lineInfo?['lineColor'] ?? '#1976D2';
          
          final station = MetroStation(
            id: stopId,
            name: stationName,
            line: lineName,
            lineColor: lineColor,
            latitude: latitude,
            longitude: longitude,
            facilities: _getStationFacilities(stationName),
            isInterchange: _isInterchangeStation(stationName),
            interchangeLines: _getInterchangeLines(stationName),
          );
          _stations!.add(station);
        }
      }
      
      print('CompleteGTFS: Successfully converted ${_stations!.length} stations');
      return _stations!;
    } catch (e) {
      print('CompleteGTFS: Error loading GTFS data: $e');
      return [];
    }
  }

  /// Parse a CSV line properly handling commas within quotes
  static List<String> _parseCsvLine(String line) {
    final result = <String>[];
    var current = '';
    var inQuotes = false;
    
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current.trim());
        current = '';
      } else {
        current += char;
      }
    }
    result.add(current.trim());
    return result;
  }

  /// Get line color from line name
  static String _getLineColorFromLineName(String lineName) {
    switch (lineName) {
      case 'Red Line':
        return '#CC0000';
      case 'Yellow Line':
        return '#FFD700';
      case 'Blue Line':
        return '#0066CC';
      case 'Green Line':
        return '#00AA00';
      case 'Violet Line':
        return '#800080';
      case 'Pink Line':
        return '#FF69B4';
      case 'Magenta Line':
        return '#FF00FF';
      case 'Gray Line':
        return '#808080';
      case 'Aqua Line':
        return '#00FFFF';
      case 'Airport Express':
        return '#FF8C00';
      case 'Rapid Metro':
        return '#FF1493';
      default:
        return '#1976D2';
    }
  }

  /// Check if station is an interchange
  static bool _isInterchangeStation(String stationName) {
    return stationName == 'Rajiv Chowk' ||
           stationName == 'Kashmere Gate' ||
           stationName == 'Mandi House' ||
           stationName == 'Yamuna Bank' ||
           stationName == 'Botanical Garden' ||
           stationName == 'Welcome' ||
           stationName == 'Inderlok' ||
           stationName == 'Netaji Subash Place' ||
           stationName == 'Rajouri Garden' ||
           stationName == 'Azadpur' ||
           stationName == 'INA' ||
           stationName == 'Hauz Khas' ||
           stationName == 'New Delhi';
  }

  /// Get interchange lines for a station
  static List<String> _getInterchangeLines(String stationName) {
    switch (stationName) {
      case 'Rajiv Chowk':
        return ['Blue Line', 'Yellow Line'];
      case 'Kashmere Gate':
        return ['Red Line', 'Yellow Line', 'Violet Line'];
      case 'Mandi House':
        return ['Blue Line', 'Violet Line'];
      case 'Yamuna Bank':
        return ['Blue Line', 'Blue Line Branch'];
      case 'Botanical Garden':
        return ['Blue Line', 'Magenta Line'];
      case 'Welcome':
        return ['Red Line', 'Pink Line'];
      case 'Inderlok':
        return ['Red Line', 'Green Line'];
      case 'Netaji Subash Place':
        return ['Red Line', 'Pink Line'];
      case 'Rajouri Garden':
        return ['Blue Line', 'Pink Line'];
      case 'Azadpur':
        return ['Yellow Line', 'Pink Line'];
      case 'INA':
        return ['Yellow Line', 'Pink Line'];
      case 'Hauz Khas':
        return ['Yellow Line', 'Magenta Line'];
      case 'New Delhi':
        return ['Yellow Line', 'Airport Express'];
      default:
        return [];
    }
  }

  /// Get station facilities
  static List<String> _getStationFacilities(String stationName) {
    final facilities = <String>[];
    
    if (stationName.contains('SECTOR') || 
        stationName == 'Rajiv Chowk' ||
        stationName == 'Kashmere Gate' ||
        stationName == 'New Delhi') {
      facilities.addAll(['Parking', 'ATM', 'Food Court']);
    } else if (stationName.contains('GARDEN') ||
               stationName.contains('NAGAR') ||
               stationName.contains('PLACE')) {
      facilities.addAll(['Parking', 'ATM']);
    } else {
      facilities.add('Parking');
    }
    
    return facilities;
  }

  /// Clear cache - call this if you want to reload with updated route data
  static void clearCache() {
    _stations = null;
    print('CompleteGTFS: Cache cleared');
  }
}
