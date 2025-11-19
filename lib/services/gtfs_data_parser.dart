import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import '../models/gtfs_models.dart';
import '../models/metro_station.dart';
import '../models/metro_line.dart' as metro_line;

class GTFSDataParser {
  static const String _gtfsDataPath = 'assets/gtfs_data/';
  
  // Cache for parsed data
  static List<GTFSAgency>? _agencies;
  static List<GTFSStop>? _stops;
  static List<GTFSRoute>? _routes;
  static List<GTFSTrip>? _trips;
  static List<GTFSStopTime>? _stopTimes;
  static List<MetroStation>? _metroStations;
  static List<metro_line.MetroLine>? _metroLines;

  /// Parse GTFS data from local assets
  static Future<void> initializeGTFSData() async {
    try {
      await Future.wait([
        _parseAgencies(),
        _parseStops(),
        _parseRoutes(),
        _parseTrips(),
        _parseStopTimes(),
      ]);
      
      // Convert GTFS data to app models
      await _convertToMetroModels();
      
      print('GTFS data initialized successfully');
    } catch (e) {
      print('Error initializing GTFS data: $e');
      rethrow;
    }
  }

  /// Parse agency.txt
  static Future<List<GTFSAgency>> _parseAgencies() async {
    if (_agencies != null) return _agencies!;
    
    try {
      final data = await rootBundle.loadString('$_gtfsDataPath/agency.txt');
      final csvData = const CsvToListConverter().convert(data);
      
      if (csvData.isNotEmpty) {
        final headers = csvData[0].map((e) => e.toString()).toList();
        _agencies = csvData.skip(1).map((row) {
          final rowMap = <String, String>{};
          for (int i = 0; i < headers.length && i < row.length; i++) {
            rowMap[headers[i]] = row[i].toString();
          }
          return GTFSAgency.fromCsv(rowMap);
        }).toList();
      }
      
      return _agencies ?? [];
    } catch (e) {
      print('Error parsing agencies: $e');
      return [];
    }
  }

  /// Parse stops.txt
  static Future<List<GTFSStop>> _parseStops() async {
    if (_stops != null) return _stops!;
    
    try {
      print('GTFS: Loading stops.txt...');
      final data = await rootBundle.loadString('$_gtfsDataPath/stops.txt');
      final csvData = const CsvToListConverter().convert(data);
      
      print('GTFS: Parsed ${csvData.length} rows from stops.txt');
      
      if (csvData.isNotEmpty) {
        final headers = csvData[0].map((e) => e.toString()).toList();
        print('GTFS: Headers: $headers');
        
        _stops = csvData.skip(1).map((row) {
          final rowMap = <String, String>{};
          for (int i = 0; i < headers.length && i < row.length; i++) {
            rowMap[headers[i]] = row[i].toString();
          }
          return GTFSStop.fromCsv(rowMap);
        }).toList();
        
        print('GTFS: Successfully parsed ${_stops!.length} stops');
      }
      
      return _stops ?? [];
    } catch (e) {
      print('Error parsing stops: $e');
      return [];
    }
  }

  /// Parse routes.txt
  static Future<List<GTFSRoute>> _parseRoutes() async {
    if (_routes != null) return _routes!;
    
    try {
      print('GTFS: Loading routes.txt...');
      final data = await rootBundle.loadString('$_gtfsDataPath/routes.txt');
      final csvData = const CsvToListConverter().convert(data);
      
      print('GTFS: Parsed ${csvData.length} rows from routes.txt');
      
      if (csvData.isNotEmpty) {
        final headers = csvData[0].map((e) => e.toString()).toList();
        print('GTFS: Route headers: $headers');
        
        _routes = csvData.skip(1).map((row) {
          final rowMap = <String, String>{};
          for (int i = 0; i < headers.length && i < row.length; i++) {
            rowMap[headers[i]] = row[i].toString();
          }
          return GTFSRoute.fromCsv(rowMap);
        }).toList();
        
        print('GTFS: Successfully parsed ${_routes!.length} routes');
      }
      
      return _routes ?? [];
    } catch (e) {
      print('Error parsing routes: $e');
      return [];
    }
  }

  /// Parse trips.txt
  static Future<List<GTFSTrip>> _parseTrips() async {
    if (_trips != null) return _trips!;
    
    try {
      final data = await rootBundle.loadString('$_gtfsDataPath/trips.txt');
      final csvData = const CsvToListConverter().convert(data);
      
      if (csvData.isNotEmpty) {
        final headers = csvData[0].map((e) => e.toString()).toList();
        _trips = csvData.skip(1).map((row) {
          final rowMap = <String, String>{};
          for (int i = 0; i < headers.length && i < row.length; i++) {
            rowMap[headers[i]] = row[i].toString();
          }
          return GTFSTrip.fromCsv(rowMap);
        }).toList();
        
        print('Successfully loaded ${_trips!.length} trips from GTFS data');
      }
      
      return _trips ?? [];
    } catch (e) {
      print('Error parsing trips: $e');
      return [];
    }
  }

  /// Parse stop_times.txt
  static Future<List<GTFSStopTime>> _parseStopTimes() async {
    if (_stopTimes != null) return _stopTimes!;
    
    try {
      final data = await rootBundle.loadString('$_gtfsDataPath/stop_times.txt');
      final csvData = const CsvToListConverter().convert(data);
      
      if (csvData.isNotEmpty) {
        final headers = csvData[0].map((e) => e.toString()).toList();
        _stopTimes = csvData.skip(1).map((row) {
          final rowMap = <String, String>{};
          for (int i = 0; i < headers.length && i < row.length; i++) {
            rowMap[headers[i]] = row[i].toString();
          }
          return GTFSStopTime.fromCsv(rowMap);
        }).toList();
        
        print('Successfully loaded ${_stopTimes!.length} stop times from GTFS data');
      }
      
      return _stopTimes ?? [];
    } catch (e) {
      print('Error parsing stop times: $e');
      return [];
    }
  }

  /// Convert GTFS data to MetroStation models
  static Future<List<MetroStation>> _convertToMetroStations() async {
    if (_metroStations != null) return _metroStations!;
    
    print('GTFS: Converting to metro stations...');
    final stops = await _parseStops();
    final routes = await _parseRoutes();
    final trips = await _parseTrips();
    final stopTimes = await _parseStopTimes();
    
    print('GTFS: Have ${stops.length} stops, ${routes.length} routes, ${trips.length} trips, ${stopTimes.length} stop times');
    
    // Create mapping: route_id -> line info (name and color)
    // Routes format: COLOR_Route Name (e.g., RED_Dilshad Garden to Rithala, VIOLET_Kashmere Gate to Badarpur Border)
    final routeToLineMap = <String, Map<String, String>>{};
    for (final route in routes) {
      final routeLongName = route.routeLongName.toUpperCase();
      
      String lineName = 'Unknown Line';
      String lineColor = '#1976D2';
      
      // Check based on route long name format: COLOR_Route Description
      if (routeLongName.startsWith('RED_')) {
        lineName = 'Red Line';
        lineColor = '#CC0000';
      } else if (routeLongName.startsWith('YELLOW_')) {
        lineName = 'Yellow Line';
        lineColor = '#FFD700';
      } else if (routeLongName.startsWith('BLUE_')) {
        lineName = 'Blue Line';
        lineColor = '#0066CC';
      } else if (routeLongName.startsWith('GREEN_')) {
        lineName = 'Green Line';
        lineColor = '#00AA00';
      } else if (routeLongName.startsWith('VIOLET_')) {
        lineName = 'Violet Line';
        lineColor = '#800080';
      } else if (routeLongName.startsWith('PINK_')) {
        lineName = 'Pink Line';
        lineColor = '#FF69B4';
      } else if (routeLongName.startsWith('MAGENTA_')) {
        lineName = 'Magenta Line';
        lineColor = '#FF00FF';
      } else if (routeLongName.startsWith('GRAY_')) {
        lineName = 'Gray Line';
        lineColor = '#808080';
      } else if (routeLongName.startsWith('AQUA_')) {
        lineName = 'Aqua Line';
        lineColor = '#00FFFF';
      } else if (routeLongName.startsWith('ORANGE/AIRPORT_') || routeLongName.startsWith('ORANGE_') || routeLongName.contains('AIRPORT_')) {
        lineName = 'Airport Express';
        lineColor = '#FF8C00';
      } else if (routeLongName.startsWith('RAPID_')) {
        lineName = 'Rapid Metro';
        lineColor = '#FF1493';
      }
      
      routeToLineMap[route.routeId] = {
        'lineName': lineName,
        'lineColor': lineColor,
      };
    }
    
    // Create mapping: trip_id -> route_id
    final tripToRouteMap = <String, String>{};
    for (final trip in trips) {
      tripToRouteMap[trip.tripId] = trip.routeId;
    }
    
    // Create mapping: stop_id -> line info (using stop_times to link stops to trips to routes)
    // For stations on multiple lines (interchanges), use the most common line
    final stopLineCounts = <String, Map<String, int>>{}; // stopId -> lineName -> count
    for (final stopTime in stopTimes) {
      final tripId = stopTime.tripId;
      final stopId = stopTime.stopId;
      
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
    
    print('GTFS: Mapped ${stopToLineMap.length} stops to lines based on route data');
    
    _metroStations = stops.map((stop) {
      // Get line info from route-based mapping
      final lineInfo = stopToLineMap[stop.stopId];
      String lineName = lineInfo?['lineName'] ?? 'Unknown Line';
      String lineColor = lineInfo?['lineColor'] ?? '#1976D2';
      
      // Fallback to route-based detection if mapping not found
      if (lineName == 'Unknown Line') {
        // Try to find a route that serves this stop
        for (final stopTime in stopTimes.where((st) => st.stopId == stop.stopId)) {
          final routeId = tripToRouteMap[stopTime.tripId];
          if (routeId != null) {
            final routeLineInfo = routeToLineMap[routeId];
            if (routeLineInfo != null) {
              lineName = routeLineInfo['lineName']!;
              lineColor = routeLineInfo['lineColor']!;
              break;
            }
          }
        }
      }

      // Determine if it's an interchange station
      bool isInterchange = stop.stopName == 'Rajiv Chowk' ||
                          stop.stopName == 'Kashmere Gate' ||
                          stop.stopName == 'Mandi House' ||
                          stop.stopName == 'Yamuna Bank' ||
                          stop.stopName == 'Botanical Garden' ||
                          stop.stopName == 'Welcome' ||
                          stop.stopName == 'Inderlok' ||
                          stop.stopName == 'Netaji Subash Place' ||
                          stop.stopName == 'Rajouri Garden' ||
                          stop.stopName == 'Azadpur' ||
                          stop.stopName == 'INA' ||
                          stop.stopName == 'Hauz Khas' ||
                          stop.stopName == 'New Delhi';

      // Determine interchange lines
      List<String> interchangeLines = [];
      if (isInterchange) {
        if (stop.stopName == 'Rajiv Chowk') {
          interchangeLines = ['Blue Line', 'Yellow Line'];
        } else if (stop.stopName == 'Kashmere Gate') {
          interchangeLines = ['Red Line', 'Yellow Line', 'Violet Line'];
        } else if (stop.stopName == 'Mandi House') {
          interchangeLines = ['Blue Line', 'Violet Line'];
        } else if (stop.stopName == 'Yamuna Bank') {
          interchangeLines = ['Blue Line', 'Blue Line Branch'];
        } else if (stop.stopName == 'Botanical Garden') {
          interchangeLines = ['Blue Line', 'Magenta Line'];
        } else if (stop.stopName == 'Welcome') {
          interchangeLines = ['Red Line', 'Pink Line'];
        } else if (stop.stopName == 'Inderlok') {
          interchangeLines = ['Red Line', 'Green Line'];
        } else if (stop.stopName == 'Netaji Subash Place') {
          interchangeLines = ['Red Line', 'Pink Line'];
        } else if (stop.stopName == 'Rajouri Garden') {
          interchangeLines = ['Blue Line', 'Pink Line'];
        } else if (stop.stopName == 'Azadpur') {
          interchangeLines = ['Yellow Line', 'Pink Line'];
        } else if (stop.stopName == 'INA') {
          interchangeLines = ['Yellow Line', 'Pink Line'];
        } else if (stop.stopName == 'Hauz Khas') {
          interchangeLines = ['Yellow Line', 'Magenta Line'];
        } else if (stop.stopName == 'New Delhi') {
          interchangeLines = ['Yellow Line', 'Airport Express'];
        }
      }

      return MetroStation(
        id: stop.stopId,
        name: stop.stopName,
        line: lineName,
        lineColor: lineColor,
        latitude: stop.stopLat,
        longitude: stop.stopLon,
        facilities: _getStationFacilities(stop),
        isInterchange: isInterchange,
        interchangeLines: interchangeLines,
      );
    }).toList();

    print('Successfully converted ${_metroStations!.length} stops to metro stations');
    return _metroStations!;
  }

  /// Convert GTFS data to MetroLine models
  static Future<List<metro_line.MetroLine>> _convertToMetroLines() async {
    if (_metroLines != null) return _metroLines!;
    
    final routes = await _parseRoutes();
    final stations = await _convertToMetroStations();
    
    // Group stations by line
    final stationsByLine = <String, List<metro_line.MetroStation>>{};
    for (final station in stations) {
      if (!stationsByLine.containsKey(station.line)) {
        stationsByLine[station.line] = [];
      }
      stationsByLine[station.line]!.add(metro_line.MetroStation(
        id: station.id,
        name: station.name,
        latitude: station.latitude,
        longitude: station.longitude,
        isInterchange: station.isInterchange,
      ));
    }
    
    _metroLines = stationsByLine.entries.map((entry) {
      final lineName = entry.key;
      final lineStations = entry.value;
      
      // Find the corresponding route for this line
      final route = routes.firstWhere(
        (r) => r.routeLongName.contains(lineName.split(' ')[0].toUpperCase()),
        orElse: () => routes.first,
      );
      
      // Determine line color
      String lineColor = '#1976D2';
      if (lineName.contains('Red')) {
        lineColor = '#CC0000';
      } else if (lineName.contains('Yellow')) {
        lineColor = '#FFD700';
      } else if (lineName.contains('Blue')) {
        lineColor = '#0066CC';
      } else if (lineName.contains('Green')) {
        lineColor = '#00AA00';
      } else if (lineName.contains('Violet')) {
        lineColor = '#800080';
      } else if (lineName.contains('Pink')) {
        lineColor = '#FF69B4';
      } else if (lineName.contains('Magenta')) {
        lineColor = '#FF00FF';
      } else if (lineName.contains('Gray')) {
        lineColor = '#808080';
      } else if (lineName.contains('Aqua')) {
        lineColor = '#00FFFF';
      } else if (lineName.contains('Airport')) {
        lineColor = '#FF8C00';
      } else if (lineName.contains('Rapid')) {
        lineColor = '#FF1493';
      }
      
      return metro_line.MetroLine(
        id: route.routeId,
        name: lineName,
        color: lineColor,
        stations: lineStations,
      );
    }).toList();

    print('Successfully converted ${_metroLines!.length} routes to metro lines');
    return _metroLines!;
  }

  /// Convert GTFS data to app models
  static Future<void> _convertToMetroModels() async {
    await _convertToMetroStations();
    await _convertToMetroLines();
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

  /// Get station facilities based on GTFS data
  static List<String> _getStationFacilities(GTFSStop stop) {
    final facilities = <String>[];
    
    // Add facilities based on station characteristics
    if (stop.wheelchairBoarding == 1) {
      facilities.add('Wheelchair Accessible');
    }
    
    // Add common facilities for major stations
    if (stop.stopId.contains('SECTOR') || 
        stop.stopId == 'RAJIV_CHOWK' ||
        stop.stopId == 'KASHMERE_GATE' ||
        stop.stopId == 'NEW_DELHI') {
      facilities.addAll(['Parking', 'ATM', 'Food Court']);
    } else if (stop.stopId.contains('GARDEN') ||
               stop.stopId.contains('NAGAR') ||
               stop.stopId.contains('PLACE')) {
      facilities.addAll(['Parking', 'ATM']);
    } else {
      facilities.add('Parking');
    }
    
    return facilities;
  }

  /// Get metro stations
  static Future<List<MetroStation>> getMetroStations() async {
    if (_metroStations == null) {
      await initializeGTFSData();
    }
    return _metroStations ?? [];
  }

  /// Get metro lines
  static Future<List<metro_line.MetroLine>> getMetroLines() async {
    if (_metroLines == null) {
      await initializeGTFSData();
    }
    return _metroLines ?? [];
  }

  /// Get agencies
  static Future<List<GTFSAgency>> getAgencies() async {
    if (_agencies == null) {
      await initializeGTFSData();
    }
    return _agencies ?? [];
  }

  /// Get stops
  static Future<List<GTFSStop>> getStops() async {
    if (_stops == null) {
      await initializeGTFSData();
    }
    return _stops ?? [];
  }

  /// Get routes
  static Future<List<GTFSRoute>> getRoutes() async {
    if (_routes == null) {
      await initializeGTFSData();
    }
    return _routes ?? [];
  }

  /// Get trips
  static Future<List<GTFSTrip>> getTrips() async {
    if (_trips == null) {
      await initializeGTFSData();
    }
    return _trips ?? [];
  }

  /// Get stop times
  static Future<List<GTFSStopTime>> getStopTimes() async {
    if (_stopTimes == null) {
      await initializeGTFSData();
    }
    return _stopTimes ?? [];
  }

  /// Clear all cached data - call this if you want to reload with updated route data
  static void clearCache() {
    _agencies = null;
    _stops = null;
    _routes = null;
    _trips = null;
    _stopTimes = null;
    _metroStations = null;
    _metroLines = null;
    print('GTFSDataParser: Cache cleared');
  }
}
