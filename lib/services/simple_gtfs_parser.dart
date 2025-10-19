import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import '../models/metro_station.dart';

/// Simple GTFS Parser that directly converts GTFS data to MetroStation objects
class SimpleGTFSParser {
  static List<MetroStation>? _stations;

  /// Load all metro stations from GTFS data
  static Future<List<MetroStation>> getAllStations() async {
    if (_stations != null) return _stations!;

    try {
      print('SimpleGTFS: Loading GTFS data...');
      
      // Load stops
      final stopsData = await rootBundle.loadString('assets/gtfs_data/stops.txt');
      final stopsCsv = const CsvToListConverter().convert(stopsData);
      
      // Load routes
      final routesData = await rootBundle.loadString('assets/gtfs_data/routes.txt');
      final routesCsv = const CsvToListConverter().convert(routesData);
      
      print('SimpleGTFS: Loaded ${stopsCsv.length} stops and ${routesCsv.length} routes');
      
      // Create route mapping
      final routeMap = <String, Map<String, String>>{};
      for (int i = 1; i < routesCsv.length; i++) {
        final route = routesCsv[i];
        if (route.length >= 4) {
          routeMap[route[0].toString()] = {
            'id': route[0].toString(),
            'name': route[3].toString(),
            'color': _getLineColor(route[3].toString()),
          };
        }
      }
      
      // Convert stops to stations
      _stations = <MetroStation>[];
      for (int i = 1; i < stopsCsv.length; i++) {
        final stop = stopsCsv[i];
        if (stop.length >= 6) {
          final station = MetroStation(
            id: stop[0].toString(),
            name: stop[2].toString(),
            line: _getLineName(stop[2].toString()),
            lineColor: _getLineColor(_getLineName(stop[2].toString())),
            latitude: double.tryParse(stop[4].toString()) ?? 0.0,
            longitude: double.tryParse(stop[5].toString()) ?? 0.0,
            facilities: _getStationFacilities(stop[2].toString()),
            isInterchange: _isInterchangeStation(stop[2].toString()),
            interchangeLines: _getInterchangeLines(stop[2].toString()),
          );
          _stations!.add(station);
        }
      }
      
      print('SimpleGTFS: Successfully converted ${_stations!.length} stations');
      return _stations!;
    } catch (e) {
      print('SimpleGTFS: Error loading GTFS data: $e');
      return [];
    }
  }

  /// Determine line name based on station name
  static String _getLineName(String stationName) {
    if (stationName.contains('Dwarka') || 
        stationName.contains('Noida') ||
        stationName.contains('Vaishali') ||
        stationName.contains('Yamuna Bank') ||
        stationName.contains('Akshardham') ||
        stationName.contains('Mayur Vihar') ||
        stationName.contains('Botanical Garden')) {
      return 'Blue Line';
    } else if (stationName.contains('Rithala') ||
               stationName.contains('Dilshad Garden') ||
               stationName.contains('Welcome') ||
               stationName.contains('Kashmere Gate') ||
               stationName.contains('Tis Hazari') ||
               stationName.contains('Pul Bangash') ||
               stationName.contains('Inderlok') ||
               stationName.contains('Rohini') ||
               stationName.contains('Shaheed Sthal')) {
      return 'Red Line';
    } else if (stationName.contains('Samaypur Badli') ||
               stationName.contains('HUDA City Centre') ||
               stationName.contains('Qutab Minar') ||
               stationName.contains('Hauz Khas') ||
               stationName.contains('AIIMS') ||
               stationName.contains('Rajiv Chowk') ||
               stationName.contains('New Delhi') ||
               stationName.contains('Chandni Chowk') ||
               stationName.contains('Civil Lines') ||
               stationName.contains('Vishwavidyalaya') ||
               stationName.contains('Azadpur')) {
      return 'Yellow Line';
    } else if (stationName.contains('Brigadier Hoshiyar Singh') ||
               stationName.contains('Kirti Nagar')) {
      return 'Green Line';
    } else if (stationName.contains('Raja Nahar Singh') ||
               stationName.contains('Badarpur')) {
      return 'Violet Line';
    } else if (stationName.contains('Shiv Vihar') ||
               stationName.contains('Majlis Park')) {
      return 'Pink Line';
    } else if (stationName.contains('Janak Puri West') ||
               stationName.contains('Botanical Garden')) {
      return 'Magenta Line';
    } else if (stationName.contains('Dhansa') ||
               stationName.contains('Najafgarh')) {
      return 'Gray Line';
    } else if (stationName.contains('Depot Station') ||
               stationName.contains('Noida Sector 142')) {
      return 'Aqua Line';
    } else if (stationName.contains('IGI Airport') ||
               stationName.contains('Delhi Aerocity')) {
      return 'Airport Express';
    } else if (stationName.contains('Rapid') ||
               stationName.contains('Phase')) {
      return 'Rapid Metro';
    }
    return 'Unknown Line';
  }

  /// Get line color based on line name
  static String _getLineColor(String lineName) {
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

  /// Clear cache
  static void clearCache() {
    _stations = null;
  }
}
