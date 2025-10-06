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
      final data = await rootBundle.loadString('$_gtfsDataPath/stops.txt');
      final csvData = const CsvToListConverter().convert(data);
      
      if (csvData.isNotEmpty) {
        final headers = csvData[0].map((e) => e.toString()).toList();
        _stops = csvData.skip(1).map((row) {
          final rowMap = <String, String>{};
          for (int i = 0; i < headers.length && i < row.length; i++) {
            rowMap[headers[i]] = row[i].toString();
          }
          return GTFSStop.fromCsv(rowMap);
        }).toList();
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
      final data = await rootBundle.loadString('$_gtfsDataPath/routes.txt');
      final csvData = const CsvToListConverter().convert(data);
      
      if (csvData.isNotEmpty) {
        final headers = csvData[0].map((e) => e.toString()).toList();
        _routes = csvData.skip(1).map((row) {
          final rowMap = <String, String>{};
          for (int i = 0; i < headers.length && i < row.length; i++) {
            rowMap[headers[i]] = row[i].toString();
          }
          return GTFSRoute.fromCsv(rowMap);
        }).toList();
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
    
    final stops = await _parseStops();
    final routes = await _parseRoutes();
    final trips = await _parseTrips();
    
    // Create a mapping of stop IDs to their routes
    final stopToRouteMap = <String, String>{};
    
    // Map stops to routes based on trip data
    for (final trip in trips) {
      final route = routes.firstWhere(
        (r) => r.routeId == trip.routeId,
        orElse: () => routes.first,
      );
      
      // Extract line name from route long name
      String lineName = route.routeLongName;
      if (lineName.contains('RED')) {
        lineName = 'Red Line';
      } else if (lineName.contains('YELLOW')) {
        lineName = 'Yellow Line';
      } else if (lineName.contains('BLUE')) {
        lineName = 'Blue Line';
      } else if (lineName.contains('GREEN')) {
        lineName = 'Green Line';
      } else if (lineName.contains('VIOLET')) {
        lineName = 'Violet Line';
      } else if (lineName.contains('PINK')) {
        lineName = 'Pink Line';
      } else if (lineName.contains('MAGENTA')) {
        lineName = 'Magenta Line';
      } else if (lineName.contains('GRAY')) {
        lineName = 'Gray Line';
      } else if (lineName.contains('AQUA')) {
        lineName = 'Aqua Line';
      } else if (lineName.contains('ORANGE') || lineName.contains('AIRPORT')) {
        lineName = 'Airport Express';
      } else if (lineName.contains('RAPID')) {
        lineName = 'Rapid Metro';
      }
      
      stopToRouteMap[trip.tripId] = lineName;
    }
    
    _metroStations = stops.map((stop) {
      // Determine line name and color based on stop characteristics
      String lineName = 'Unknown Line';
      String lineColor = '#1976D2';
      
      // Map based on station names and known patterns
      if (stop.stopName.contains('Dwarka') || 
          stop.stopName.contains('Noida') ||
          stop.stopName.contains('Vaishali') ||
          stop.stopName.contains('Yamuna Bank') ||
          stop.stopName.contains('Akshardham') ||
          stop.stopName.contains('Mayur Vihar') ||
          stop.stopName.contains('Botanical Garden')) {
        lineName = 'Blue Line';
        lineColor = '#0066CC';
      } else if (stop.stopName.contains('Rithala') ||
                 stop.stopName.contains('Dilshad Garden') ||
                 stop.stopName.contains('Welcome') ||
                 stop.stopName.contains('Kashmere Gate') ||
                 stop.stopName.contains('Tis Hazari') ||
                 stop.stopName.contains('Pul Bangash') ||
                 stop.stopName.contains('Inderlok') ||
                 stop.stopName.contains('Rohini') ||
                 stop.stopName.contains('Shaheed Sthal')) {
        lineName = 'Red Line';
        lineColor = '#CC0000';
      } else if (stop.stopName.contains('Samaypur Badli') ||
                 stop.stopName.contains('HUDA City Centre') ||
                 stop.stopName.contains('Qutab Minar') ||
                 stop.stopName.contains('Hauz Khas') ||
                 stop.stopName.contains('AIIMS') ||
                 stop.stopName.contains('Rajiv Chowk') ||
                 stop.stopName.contains('New Delhi') ||
                 stop.stopName.contains('Chandni Chowk') ||
                 stop.stopName.contains('Civil Lines') ||
                 stop.stopName.contains('Vishwavidyalaya') ||
                 stop.stopName.contains('Azadpur')) {
        lineName = 'Yellow Line';
        lineColor = '#FFD700';
      } else if (stop.stopName.contains('Brigadier Hoshiyar Singh') ||
                 stop.stopName.contains('Kirti Nagar')) {
        lineName = 'Green Line';
        lineColor = '#00AA00';
      } else if (stop.stopName.contains('Raja Nahar Singh') ||
                 stop.stopName.contains('Badarpur')) {
        lineName = 'Violet Line';
        lineColor = '#800080';
      } else if (stop.stopName.contains('Shiv Vihar') ||
                 stop.stopName.contains('Majlis Park')) {
        lineName = 'Pink Line';
        lineColor = '#FF69B4';
      } else if (stop.stopName.contains('Janak Puri West') ||
                 stop.stopName.contains('Botanical Garden')) {
        lineName = 'Magenta Line';
        lineColor = '#FF00FF';
      } else if (stop.stopName.contains('Dhansa') ||
                 stop.stopName.contains('Najafgarh')) {
        lineName = 'Gray Line';
        lineColor = '#808080';
      } else if (stop.stopName.contains('Depot Station') ||
                 stop.stopName.contains('Noida Sector 142')) {
        lineName = 'Aqua Line';
        lineColor = '#00FFFF';
      } else if (stop.stopName.contains('IGI Airport') ||
                 stop.stopName.contains('Delhi Aerocity')) {
        lineName = 'Airport Express';
        lineColor = '#FF8C00';
      } else if (stop.stopName.contains('Rapid') ||
                 stop.stopName.contains('Phase')) {
        lineName = 'Rapid Metro';
        lineColor = '#FF1493';
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

  /// Clear all cached data
  static void clearCache() {
    _agencies = null;
    _stops = null;
    _routes = null;
    _trips = null;
    _stopTimes = null;
    _metroStations = null;
    _metroLines = null;
  }
}
