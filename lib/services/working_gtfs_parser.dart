import 'package:flutter/services.dart';
import '../models/metro_station.dart';

/// Working GTFS Parser that properly reads and parses GTFS data
class WorkingGTFSParser {
  static List<MetroStation>? _stations;

  /// Load all metro stations from GTFS data
  static Future<List<MetroStation>> getAllStations() async {
    if (_stations != null) return _stations!;

    try {
      print('WorkingGTFS: Loading GTFS data...');
      
      // Load stops data
      final stopsData = await rootBundle.loadString('assets/gtfs_data/stops.txt');
      final stopsLines = stopsData.split('\n').where((line) => line.trim().isNotEmpty).toList();
      
      // Load routes data
      final routesData = await rootBundle.loadString('assets/gtfs_data/routes.txt');
      final routesLines = routesData.split('\n').where((line) => line.trim().isNotEmpty).toList();
      
      print('WorkingGTFS: Loaded ${stopsLines.length} stop lines and ${routesLines.length} route lines');
      
      // Parse routes
      final routeMap = <String, Map<String, String>>{};
      for (int i = 1; i < routesLines.length; i++) {
        final routeParts = _parseCsvLine(routesLines[i]);
        if (routeParts.length >= 4) {
          final routeId = routeParts[0];
          final routeLongName = routeParts[3];
          routeMap[routeId] = {
            'id': routeId,
            'name': routeLongName,
            'color': _getLineColorFromRouteName(routeLongName),
          };
        }
      }
      
      print('WorkingGTFS: Parsed ${routeMap.length} routes');
      
      // Parse stops and convert to stations
      _stations = <MetroStation>[];
      for (int i = 1; i < stopsLines.length; i++) {
        final stopParts = _parseCsvLine(stopsLines[i]);
        if (stopParts.length >= 6) {
          final stopId = stopParts[0];
          final stopName = stopParts[2];
          final latitude = double.tryParse(stopParts[4]) ?? 0.0;
          final longitude = double.tryParse(stopParts[5]) ?? 0.0;
          
          // Determine line from station name
          final lineName = _getLineNameFromStation(stopName);
          final lineColor = _getLineColorFromLineName(lineName);
          
          final station = MetroStation(
            id: stopId,
            name: stopName,
            line: lineName,
            lineColor: lineColor,
            latitude: latitude,
            longitude: longitude,
            facilities: _getStationFacilities(stopName),
            isInterchange: _isInterchangeStation(stopName),
            interchangeLines: _getInterchangeLines(stopName),
          );
          _stations!.add(station);
        }
      }
      
      print('WorkingGTFS: Successfully converted ${_stations!.length} stations');
      return _stations!;
    } catch (e) {
      print('WorkingGTFS: Error loading GTFS data: $e');
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

  /// Get line color from route name
  static String _getLineColorFromRouteName(String routeName) {
    if (routeName.contains('RED')) return '#CC0000';
    if (routeName.contains('YELLOW')) return '#FFD700';
    if (routeName.contains('BLUE')) return '#0066CC';
    if (routeName.contains('GREEN')) return '#00AA00';
    if (routeName.contains('VIOLET')) return '#800080';
    if (routeName.contains('PINK')) return '#FF69B4';
    if (routeName.contains('MAGENTA')) return '#FF00FF';
    if (routeName.contains('GRAY')) return '#808080';
    if (routeName.contains('AQUA')) return '#00FFFF';
    if (routeName.contains('ORANGE') || routeName.contains('AIRPORT')) return '#FF8C00';
    if (routeName.contains('RAPID')) return '#FF1493';
    return '#1976D2';
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

  /// Determine line name based on station name
  static String _getLineNameFromStation(String stationName) {
    // Red Line stations (Rithala to Dilshad Garden)
    if (stationName.contains('Rithala') ||
        stationName.contains('Rohini West') ||
        stationName.contains('Rohini East') ||
        stationName.contains('Pitampura') ||
        stationName.contains('Kohat Enclave') ||
        stationName.contains('Netaji Subash Place') ||
        stationName.contains('Keshav Puram') ||
        stationName.contains('Kanhaiya Nagar') ||
        stationName.contains('Inderlok') ||
        stationName.contains('Shastri Nagar') ||
        stationName.contains('Pratap Nagar') ||
        stationName.contains('Pul Bangash') ||
        stationName.contains('Tis Hazari') ||
        stationName.contains('Kashmere Gate') ||
        stationName.contains('Shastri Park') ||
        stationName.contains('Seelam Pur') ||
        stationName.contains('Welcome') ||
        stationName.contains('Shahdara') ||
        stationName.contains('Mansrover park') ||
        stationName.contains('Jhilmil') ||
        stationName.contains('Dilshad Garden') ||
        stationName.contains('Shaheed Sthal') ||
        stationName.contains('Hindon River') ||
        stationName.contains('Arthala') ||
        stationName.contains('Mohan Nagar') ||
        stationName.contains('Shyam Park') ||
        stationName.contains('Major Mohit Sharma') ||
        stationName.contains('Raj Bagh') ||
        stationName.contains('Shaheed Nagar')) {
      return 'Red Line';
    }
    
    // Yellow Line stations (Samaypur Badli to Huda City Centre)
    if (stationName.contains('Samaypur Badli') ||
        stationName.contains('Rohini Sector 18-19') ||
        stationName.contains('Haiderpur Badli Mor') ||
        stationName.contains('Jahangirpuri') ||
        stationName.contains('Adarsh Nagar') ||
        stationName.contains('Azadpur') ||
        stationName.contains('Model Town') ||
        stationName.contains('Guru Tegh Bahadur Nagar') ||
        stationName.contains('Vishwavidyalaya') ||
        stationName.contains('Vidhan Sabha') ||
        stationName.contains('Civil Lines') ||
        stationName.contains('Chandni Chowk') ||
        stationName.contains('Chawri Bazar') ||
        stationName.contains('New Delhi') ||
        stationName.contains('Rajiv Chowk') ||
        stationName.contains('Patel Chowk') ||
        stationName.contains('Central Secretariat') ||
        stationName.contains('Udyog Bhawan') ||
        stationName.contains('Lok Kalyan Marg') ||
        stationName.contains('Jorbagh') ||
        stationName.contains('Dilli Haat - INA') ||
        stationName.contains('AIIMS') ||
        stationName.contains('Green Park') ||
        stationName.contains('Hauz Khas') ||
        stationName.contains('Malviya Nagar') ||
        stationName.contains('Saket') ||
        stationName.contains('Qutab Minar') ||
        stationName.contains('Chhattarpur') ||
        stationName.contains('Sultanpur') ||
        stationName.contains('Ghitorni') ||
        stationName.contains('Arjan Garh') ||
        stationName.contains('Gurudronacharya') ||
        stationName.contains('Sikanderpur') ||
        stationName.contains('MG Road') ||
        stationName.contains('IFFCO Chowk') ||
        stationName.contains('Huda City Centre')) {
      return 'Yellow Line';
    }
    
    // Blue Line stations
    if (stationName.contains('Dwarka') ||
        stationName.contains('Noida') ||
        stationName.contains('Vaishali') ||
        stationName.contains('Yamuna Bank') ||
        stationName.contains('Akshardham') ||
        stationName.contains('Mayur Vihar') ||
        stationName.contains('Botanical Garden') ||
        stationName.contains('Kaushambi') ||
        stationName.contains('Anand Vihar') ||
        stationName.contains('Karkarduma') ||
        stationName.contains('Preet Vihar') ||
        stationName.contains('Nirman Vihar') ||
        stationName.contains('Laxmi Nagar') ||
        stationName.contains('Noida City Centre') ||
        stationName.contains('Golf Course') ||
        stationName.contains('New Ashok Nagar') ||
        stationName.contains('Mayur Vihar Ext') ||
        stationName.contains('Mayur Vihar-I') ||
        stationName.contains('Indraprastha') ||
        stationName.contains('Supreme Court') ||
        stationName.contains('Mandi House') ||
        stationName.contains('Barakhamba') ||
        stationName.contains('RK Ashram Marg') ||
        stationName.contains('Jhandewalan') ||
        stationName.contains('Karol Bagh') ||
        stationName.contains('Rajendra Place') ||
        stationName.contains('Patel Nagar') ||
        stationName.contains('Shadipur') ||
        stationName.contains('Kirti Nagar') ||
        stationName.contains('Moti Nagar') ||
        stationName.contains('Ramesh Nagar') ||
        stationName.contains('Rajouri Garden') ||
        stationName.contains('Tagore Garden') ||
        stationName.contains('Subash Nagar') ||
        stationName.contains('Tilak Nagar') ||
        stationName.contains('Janak Puri East') ||
        stationName.contains('Janak Puri West') ||
        stationName.contains('Uttam Nagar East') ||
        stationName.contains('Uttam Nagar West') ||
        stationName.contains('Nawada') ||
        stationName.contains('Dwarka Mor') ||
        stationName.contains('Noida Electronic City')) {
      return 'Blue Line';
    }
    
    // Green Line stations
    if (stationName.contains('Brigadier Hoshiyar Singh') ||
        stationName.contains('Kirti Nagar')) {
      return 'Green Line';
    }
    
    // Violet Line stations
    if (stationName.contains('Raja Nahar Singh') ||
        stationName.contains('Badarpur') ||
        stationName.contains('Sarai') ||
        stationName.contains('NHPC Chowk') ||
        stationName.contains('Mewala Maharajpur') ||
        stationName.contains('Sector-28') ||
        stationName.contains('Badkal Mor') ||
        stationName.contains('Old Faridabad') ||
        stationName.contains('Neelam Chowk Ajronda') ||
        stationName.contains('Bata Chowk') ||
        stationName.contains('Escorts Mujesar') ||
        stationName.contains('Sant Surdas') ||
        stationName.contains('Vinobapuri') ||
        stationName.contains('Ashram') ||
        stationName.contains('Sarai Kale Khan')) {
      return 'Violet Line';
    }
    
    // Pink Line stations
    if (stationName.contains('Shiv Vihar') ||
        stationName.contains('Majlis Park') ||
        stationName.contains('Shalimar Bagh') ||
        stationName.contains('Shakurpur') ||
        stationName.contains('Punjabi Bagh West') ||
        stationName.contains('ESI Basai Darapur') ||
        stationName.contains('Mayapuri') ||
        stationName.contains('Naraina Vihar') ||
        stationName.contains('Delhi Cantt') ||
        stationName.contains('Durgabai Deshmukh South Campus') ||
        stationName.contains('Nehru Enclave') ||
        stationName.contains('Greater Kailash') ||
        stationName.contains('Chirag Delhi') ||
        stationName.contains('Panchsheel Park') ||
        stationName.contains('IIT') ||
        stationName.contains('RK Puram') ||
        stationName.contains('Munirka') ||
        stationName.contains('Vasant Vihar') ||
        stationName.contains('Shankar Vihar') ||
        stationName.contains('Terminal 1- IGI Airport') ||
        stationName.contains('Sadar Bazar Contonment') ||
        stationName.contains('Palam') ||
        stationName.contains('Dashrath Puri') ||
        stationName.contains('Dabri Mor - Janakpuri South') ||
        stationName.contains('Mundka Industrial Area') ||
        stationName.contains('Ghevra Metro station') ||
        stationName.contains('Tikri Kalan') ||
        stationName.contains('Tikri Border') ||
        stationName.contains('Pandit Shree Ram Sharma') ||
        stationName.contains('Bahadurgarh City') ||
        stationName.contains('Sir Vishweshwaraiah Moti Bagh') ||
        stationName.contains('Bhikaji Cama Place') ||
        stationName.contains('Sarojini Nagar') ||
        stationName.contains('South Extension') ||
        stationName.contains('Trilokpuri Sanjay Lake') ||
        stationName.contains('East Vinod Nagar - Mayur Vihar-II') ||
        stationName.contains('Mandawali - West Vinod Nagar') ||
        stationName.contains('IP Extension') ||
        stationName.contains('Karkarduma Court') ||
        stationName.contains('Krishna Nagar') ||
        stationName.contains('East Azad Nagar') ||
        stationName.contains('Jafrabad') ||
        stationName.contains('Maujpur - Babarpur') ||
        stationName.contains('Gokulpuri') ||
        stationName.contains('Johri Enclave')) {
      return 'Pink Line';
    }
    
    // Magenta Line stations
    if (stationName.contains('Janak Puri West') ||
        stationName.contains('Botanical Garden')) {
      return 'Magenta Line';
    }
    
    // Gray Line stations
    if (stationName.contains('Dhansa') ||
        stationName.contains('Najafgarh') ||
        stationName.contains('Nangli')) {
      return 'Gray Line';
    }
    
    // Aqua Line stations
    if (stationName.contains('Noida Sector 51') ||
        stationName.contains('Noida Sector 50') ||
        stationName.contains('Noida Sector 76') ||
        stationName.contains('Noida Sector 101') ||
        stationName.contains('Noida Sector 81') ||
        stationName.contains('NSEZ') ||
        stationName.contains('Noida Sector 83') ||
        stationName.contains('Noida Sector 137') ||
        stationName.contains('Noida Sector 142') ||
        stationName.contains('Noida Sector 143') ||
        stationName.contains('Noida Sector 144') ||
        stationName.contains('Noida Sector 145') ||
        stationName.contains('Noida Sector 146') ||
        stationName.contains('Noida Sector 147') ||
        stationName.contains('Noida Sector 148') ||
        stationName.contains('Knowledge Park') ||
        stationName.contains('Pari Chowk') ||
        stationName.contains('Alpha 1') ||
        stationName.contains('Delta 1') ||
        stationName.contains('GNIDA Office') ||
        stationName.contains('Depot Station')) {
      return 'Aqua Line';
    }
    
    // Airport Express stations
    if (stationName.contains('IGI Airport') ||
        stationName.contains('Delhi Aerocity') ||
        stationName.contains('Dhaula Kuan') ||
        stationName.contains('Shivaji Stadium')) {
      return 'Airport Express';
    }
    
    // Rapid Metro stations
    if (stationName.contains('Rapid Metro') ||
        stationName.contains('Phase 2') ||
        stationName.contains('Phase 3') ||
        stationName.contains('Belvedere Towers') ||
        stationName.contains('Cyber City') ||
        stationName.contains('Moulsari Avenue') ||
        stationName.contains('Phase-I') ||
        stationName.contains('Sector 42-43') ||
        stationName.contains('Sector 53-54') ||
        stationName.contains('Sector 54 Chowk') ||
        stationName.contains('Sector 55-56')) {
      return 'Rapid Metro';
    }
    
    return 'Unknown Line';
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
