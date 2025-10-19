import 'package:flutter/services.dart';
import '../models/metro_station.dart';
import '../models/metro_route.dart';
import 'accurate_fare_calculator.dart';

/// GTFS-based Route Finder that uses stop_times.txt for accurate station sequences
class GTFSRouteFinder {
  static Map<String, List<StationSequence>>? _lineSequences;
  static List<MetroStation>? _stations;

  /// Load station sequences from GTFS data
  static Future<void> _loadSequences() async {
    if (_lineSequences != null) return;

    try {
      print('GTFSRouteFinder: Loading station sequences from GTFS data...');
      
      // Load stops data
      final stopsData = await rootBundle.loadString('assets/gtfs_data/stops.txt');
      final stopsLines = stopsData.split('\n').where((line) => line.trim().isNotEmpty).toList();
      
      // Load routes data
      final routesData = await rootBundle.loadString('assets/gtfs_data/routes.txt');
      final routesLines = routesData.split('\n').where((line) => line.trim().isNotEmpty).toList();
      
      // Load stop_times data
      final stopTimesData = await rootBundle.loadString('assets/gtfs_data/stop_times.txt');
      final stopTimesLines = stopTimesData.split('\n').where((line) => line.trim().isNotEmpty).toList();
      
      // Load trips data to get route information
      final tripsData = await rootBundle.loadString('assets/gtfs_data/trips.txt');
      final tripsLines = tripsData.split('\n').where((line) => line.trim().isNotEmpty).toList();
      
      print('GTFSRouteFinder: Loaded ${stopsLines.length} stops, ${routesLines.length} routes, ${stopTimesLines.length} stop_times, ${tripsLines.length} trips');
      
      // Parse stops into a map
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
          };
        }
      }
      
      // Parse trips to get route information
      final tripMap = <String, String>{}; // trip_id -> route_id
      for (int i = 1; i < tripsLines.length; i++) {
        final tripParts = _parseCsvLine(tripsLines[i]);
        if (tripParts.length >= 3) {
          tripMap[tripParts[2]] = tripParts[0]; // trip_id -> route_id
        }
      }
      
      // Parse stop_times to get station sequences
      final lineSequences = <String, List<StationSequence>>{};
      final processedTrips = <String>{};
      
      for (int i = 1; i < stopTimesLines.length; i++) {
        final stopTimeParts = _parseCsvLine(stopTimesLines[i]);
        if (stopTimeParts.length >= 5) {
          final tripId = stopTimeParts[0];
          final stopId = stopTimeParts[3];
          final sequence = int.tryParse(stopTimeParts[4]) ?? 0;
          
          // Skip if we've already processed this trip
          if (processedTrips.contains(tripId)) continue;
          
          final routeId = tripMap[tripId];
          if (routeId == null || !routeMap.containsKey(routeId)) continue;
          
          final routeName = routeMap[routeId]!['name']!;
          final stopInfo = stopsMap[stopId];
          if (stopInfo == null) continue;
          
          // Get line name from route name
          final lineName = _getLineNameFromRoute(routeName);
          
          if (!lineSequences.containsKey(lineName)) {
            lineSequences[lineName] = [];
          }
          
          lineSequences[lineName]!.add(StationSequence(
            stationId: stopId,
            stationName: stopInfo['name']!,
            latitude: double.tryParse(stopInfo['lat']!) ?? 0.0,
            longitude: double.tryParse(stopInfo['lon']!) ?? 0.0,
            sequence: sequence,
            lineName: lineName,
          ));
          
          processedTrips.add(tripId);
        }
      }
      
      // Sort stations by sequence for each line
      for (final lineName in lineSequences.keys) {
        lineSequences[lineName]!.sort((a, b) => a.sequence.compareTo(b.sequence));
        print('GTFSRouteFinder: Line $lineName has ${lineSequences[lineName]!.length} stations');
      }
      
      _lineSequences = lineSequences;
      print('GTFSRouteFinder: Successfully loaded sequences for ${lineSequences.length} lines');
      
    } catch (e) {
      print('GTFSRouteFinder: Error loading sequences: $e');
      _lineSequences = {};
    }
  }

  /// Get line name from route name
  static String _getLineNameFromRoute(String routeName) {
    final routeLower = routeName.toLowerCase();
    
    if (routeLower.contains('blue')) return 'Blue Line';
    if (routeLower.contains('red')) return 'Red Line';
    if (routeLower.contains('yellow')) return 'Yellow Line';
    if (routeLower.contains('green')) return 'Green Line';
    if (routeLower.contains('violet')) return 'Violet Line';
    if (routeLower.contains('pink')) return 'Pink Line';
    if (routeLower.contains('magenta')) return 'Magenta Line';
    if (routeLower.contains('gray') || routeLower.contains('grey')) return 'Gray Line';
    if (routeLower.contains('aqua')) return 'Aqua Line';
    if (routeLower.contains('airport')) return 'Airport Express';
    if (routeLower.contains('rapid')) return 'Rapid Metro';
    
    return routeName; // Return original if no match
  }

  /// Parse CSV line handling quoted fields
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

  /// Find route between two stations using GTFS data
  static Future<List<MetroRoute>> findRoute({
    required String fromStationName,
    required String toStationName,
    required List<MetroStation> stations,
    required DateTime travelTime,
    required bool isSmartCard,
  }) async {
    await _loadSequences();
    
    if (_lineSequences == null || _lineSequences!.isEmpty) {
      print('GTFSRouteFinder: No sequences loaded, falling back to simple route finder');
      return _findSimpleRoute(fromStationName, toStationName, stations, travelTime, isSmartCard);
    }
    
    // Find source and destination stations
    final fromStation = stations.firstWhere(
      (s) => s.name.toLowerCase().contains(fromStationName.toLowerCase()),
      orElse: () => throw Exception('From station not found: $fromStationName'),
    );
    
    final toStation = stations.firstWhere(
      (s) => s.name.toLowerCase().contains(toStationName.toLowerCase()),
      orElse: () => throw Exception('To station not found: $toStationName'),
    );
    
    print('GTFSRouteFinder: Finding route from ${fromStation.name} (${fromStation.line}) to ${toStation.name} (${toStation.line})');
    
    // If same line, find direct route
    if (fromStation.line == toStation.line) {
      return _findDirectRoute(fromStation, toStation, stations, travelTime, isSmartCard);
    }
    
    // If different lines, find route with interchanges
    return _findRouteWithInterchanges(fromStation, toStation, stations, travelTime, isSmartCard);
  }

  /// Find direct route on the same line
  static List<MetroRoute> _findDirectRoute(
    MetroStation from,
    MetroStation to,
    List<MetroStation> allStations,
    DateTime travelTime,
    bool isSmartCard,
  ) {
    final lineName = from.line;
    final sequences = _lineSequences![lineName];
    
    if (sequences == null || sequences.isEmpty) {
      print('GTFSRouteFinder: No sequences for line $lineName, using fallback');
      return _findSimpleRoute(from.name, to.name, allStations, travelTime, isSmartCard);
    }
    
    // Find stations in sequence with better matching
    StationSequence? fromSeq;
    StationSequence? toSeq;
    
    // Try exact match first
    fromSeq = sequences.firstWhere(
      (s) => s.stationName.toLowerCase() == from.name.toLowerCase(),
      orElse: () => StationSequence(stationId: '', stationName: '', latitude: 0, longitude: 0, sequence: 0, lineName: ''),
    );
    
    toSeq = sequences.firstWhere(
      (s) => s.stationName.toLowerCase() == to.name.toLowerCase(),
      orElse: () => StationSequence(stationId: '', stationName: '', latitude: 0, longitude: 0, sequence: 0, lineName: ''),
    );
    
    // If exact match failed, try partial match
    if (fromSeq.stationName.isEmpty) {
      fromSeq = sequences.firstWhere(
        (s) => s.stationName.toLowerCase().contains(from.name.toLowerCase()) || 
               from.name.toLowerCase().contains(s.stationName.toLowerCase()),
        orElse: () => throw Exception('From station not found in sequence: ${from.name}'),
      );
    }
    
    if (toSeq.stationName.isEmpty) {
      toSeq = sequences.firstWhere(
        (s) => s.stationName.toLowerCase().contains(to.name.toLowerCase()) || 
               to.name.toLowerCase().contains(s.stationName.toLowerCase()),
        orElse: () => throw Exception('To station not found in sequence: ${to.name}'),
      );
    }
    
    // Get stations between from and to
    final startIndex = fromSeq.sequence;
    final endIndex = toSeq.sequence;
    final isReverse = startIndex > endIndex;
    
    final routeStations = <StationSequence>[];
    if (isReverse) {
      for (int i = startIndex; i >= endIndex; i--) {
        final station = sequences.firstWhere((s) => s.sequence == i, orElse: () => throw Exception('Station not found at sequence $i'));
        routeStations.add(station);
      }
    } else {
      for (int i = startIndex; i <= endIndex; i++) {
        final station = sequences.firstWhere((s) => s.sequence == i, orElse: () => throw Exception('Station not found at sequence $i'));
        routeStations.add(station);
      }
    }
    
    // Calculate total distance and time
    double totalDistance = 0.0;
    int totalTime = 0;
    
    for (int i = 0; i < routeStations.length - 1; i++) {
      final current = routeStations[i];
      final next = routeStations[i + 1];
      
      final distance = AccurateFareCalculator.calculateDistance(
        current.latitude, current.longitude,
        next.latitude, next.longitude,
      );
      totalDistance += distance;
      totalTime += _getLineTravelTime(lineName, distance);
    }
    
    // Calculate fare
    final fareResult = AccurateFareCalculator.calculateFareComparison(
      distance: totalDistance,
      travelTime: travelTime,
      isAirportExpress: lineName == 'Airport Express',
    );
    
    // Create route segments
    final segments = <RouteSegment>[];
    for (int i = 0; i < routeStations.length - 1; i++) {
      final current = routeStations[i];
      final next = routeStations[i + 1];
      
      final distance = AccurateFareCalculator.calculateDistance(
        current.latitude, current.longitude,
        next.latitude, next.longitude,
      );
      
      final segmentFare = AccurateFareCalculator.calculateFareComparison(
        distance: distance,
        travelTime: travelTime,
        isAirportExpress: lineName == 'Airport Express',
      );
      
      segments.add(RouteSegment(
        line: lineName,
        lineColor: _getLineColor(lineName),
        fromStation: current.stationName,
        toStation: next.stationName,
        stationsCount: 1,
        timeMinutes: _getLineTravelTime(lineName, distance),
        fare: (isSmartCard ? segmentFare.smartCardFare : segmentFare.ticketFare).toDouble(),
      ));
    }
    
    final route = MetroRoute(
      id: 'direct_${from.id}_${to.id}',
      fromStation: from.name,
      toStation: to.name,
      segments: segments,
      totalTime: totalTime,
      totalFare: (isSmartCard ? fareResult.smartCardFare : fareResult.ticketFare).toDouble(),
      totalStations: routeStations.length,
      interchangeStations: [],
    );
    
    print('GTFSRouteFinder: Direct route found - ${routeStations.length} stations, ${totalDistance.toStringAsFixed(2)} km, $totalTime minutes');
    
    return [route];
  }

  /// Find route with interchanges
  static List<MetroRoute> _findRouteWithInterchanges(
    MetroStation from,
    MetroStation to,
    List<MetroStation> allStations,
    DateTime travelTime,
    bool isSmartCard,
  ) {
    // For now, return a simple route with one interchange
    // This can be enhanced with proper interchange detection
    print('GTFSRouteFinder: Finding route with interchanges from ${from.line} to ${to.line}');
    
    // Find common interchange stations
    final fromLineStations = allStations.where((s) => s.line == from.line).toList();
    final toLineStations = allStations.where((s) => s.line == to.line).toList();
    
    // Look for interchange stations (stations that appear on both lines)
    final interchangeStations = <MetroStation>[];
    for (final fromStation in fromLineStations) {
      for (final toStation in toLineStations) {
        if (fromStation.name.toLowerCase() == toStation.name.toLowerCase()) {
          interchangeStations.add(fromStation);
          break;
        }
      }
    }
    
    if (interchangeStations.isEmpty) {
      print('GTFSRouteFinder: No interchange stations found');
      return [];
    }
    
    // Use the first interchange station
    final interchange = interchangeStations.first;
    print('GTFSRouteFinder: Using interchange station: ${interchange.name}');
    
    // Create route with interchange
    final segments = <RouteSegment>[];
    
    // First segment: from station to interchange
    final firstDistance = AccurateFareCalculator.calculateDistance(
      from.latitude, from.longitude,
      interchange.latitude, interchange.longitude,
    );
    
    final firstFare = AccurateFareCalculator.calculateFareComparison(
      distance: firstDistance,
      travelTime: travelTime,
      isAirportExpress: from.line == 'Airport Express',
    );
    
    segments.add(RouteSegment(
      line: from.line,
      lineColor: _getLineColor(from.line),
      fromStation: from.name,
      toStation: interchange.name,
      stationsCount: 1,
      timeMinutes: _getLineTravelTime(from.line, firstDistance),
      fare: (isSmartCard ? firstFare.smartCardFare : firstFare.ticketFare).toDouble(),
    ));
    
    // Second segment: interchange to destination
    final secondDistance = AccurateFareCalculator.calculateDistance(
      interchange.latitude, interchange.longitude,
      to.latitude, to.longitude,
    );
    
    final secondFare = AccurateFareCalculator.calculateFareComparison(
      distance: secondDistance,
      travelTime: travelTime,
      isAirportExpress: to.line == 'Airport Express',
    );
    
    segments.add(RouteSegment(
      line: to.line,
      lineColor: _getLineColor(to.line),
      fromStation: interchange.name,
      toStation: to.name,
      stationsCount: 1,
      timeMinutes: _getLineTravelTime(to.line, secondDistance),
      fare: (isSmartCard ? secondFare.smartCardFare : secondFare.ticketFare).toDouble(),
    ));
    
    final totalTime = segments.fold(0, (sum, segment) => sum + segment.timeMinutes) + 5; // Add 5 minutes for interchange
    final totalFare = segments.fold(0.0, (sum, segment) => sum + segment.fare);
    
    final route = MetroRoute(
      id: 'interchange_${from.id}_${to.id}',
      fromStation: from.name,
      toStation: to.name,
      segments: segments,
      totalTime: totalTime,
      totalFare: totalFare,
      totalStations: 3,
      interchangeStations: [interchange.name],
    );
    
    return [route];
  }

  /// Fallback simple route finder
  static List<MetroRoute> _findSimpleRoute(
    String fromStationName,
    String toStationName,
    List<MetroStation> stations,
    DateTime travelTime,
    bool isSmartCard,
  ) {
    // Simple fallback implementation
    final fromStation = stations.firstWhere(
      (s) => s.name.toLowerCase().contains(fromStationName.toLowerCase()),
      orElse: () => throw Exception('From station not found: $fromStationName'),
    );
    
    final toStation = stations.firstWhere(
      (s) => s.name.toLowerCase().contains(toStationName.toLowerCase()),
      orElse: () => throw Exception('To station not found: $toStationName'),
    );
    
    final distance = AccurateFareCalculator.calculateDistance(
      fromStation.latitude, fromStation.longitude,
      toStation.latitude, toStation.longitude,
    );
    
    final fareResult = AccurateFareCalculator.calculateFareComparison(
      distance: distance,
      travelTime: travelTime,
      isAirportExpress: fromStation.line == 'Airport Express' || toStation.line == 'Airport Express',
    );
    
    final segments = <RouteSegment>[];
    
    if (fromStation.line == toStation.line) {
      // Direct route on same line
      segments.add(RouteSegment(
        line: fromStation.line,
        lineColor: _getLineColor(fromStation.line),
        fromStation: fromStation.name,
        toStation: toStation.name,
        stationsCount: 1,
        timeMinutes: (distance * 2).round(),
        fare: (isSmartCard ? fareResult.smartCardFare : fareResult.ticketFare).toDouble(),
      ));
    } else {
      // Multi-line route (simplified)
      segments.add(RouteSegment(
        line: fromStation.line,
        lineColor: _getLineColor(fromStation.line),
        fromStation: fromStation.name,
        toStation: 'Interchange',
        stationsCount: 1,
        timeMinutes: (distance * 1).round(),
        fare: (isSmartCard ? fareResult.smartCardFare : fareResult.ticketFare) / 2,
      ));
      
      segments.add(RouteSegment(
        line: toStation.line,
        lineColor: _getLineColor(toStation.line),
        fromStation: 'Interchange',
        toStation: toStation.name,
        stationsCount: 1,
        timeMinutes: (distance * 1).round(),
        fare: (isSmartCard ? fareResult.smartCardFare : fareResult.ticketFare) / 2,
      ));
    }
    
    final totalTime = segments.fold(0, (sum, segment) => sum + segment.timeMinutes);
    final totalFare = segments.fold(0.0, (sum, segment) => sum + segment.fare);
    
    final route = MetroRoute(
      id: 'simple_${fromStation.id}_${toStation.id}',
      fromStation: fromStation.name,
      toStation: toStation.name,
      segments: segments,
      totalTime: totalTime,
      totalFare: totalFare,
      totalStations: fromStation.line == toStation.line ? 2 : 3,
      interchangeStations: fromStation.line == toStation.line ? [] : ['Interchange'],
    );
    
    return [route];
  }

  /// Get travel time for a line segment
  static int _getLineTravelTime(String lineName, double distance) {
    const lineTravelTimes = {
      'Blue Line': 2.0,
      'Blue Line Branch': 1.875,
      'Red Line': 2.0,
      'Yellow Line': 2.22,
      'Green Line': 2.0,
      'Violet Line': 2.0,
      'Pink Line': 2.69,
      'Magenta Line': 2.0,
      'Gray Line': 2.0,
      'Aqua Line': 2.0,
      'Airport Express': 5.2,
      'Rapid Metro': 2.0,
    };
    
    final timePerKm = lineTravelTimes[lineName] ?? 2.0;
    return (distance * timePerKm).round();
  }

  /// Get line color for a metro line
  static String _getLineColor(String lineName) {
    const lineColors = {
      'Blue Line': '#1976D2',
      'Blue Line Branch': '#1976D2',
      'Red Line': '#D32F2F',
      'Yellow Line': '#FBC02D',
      'Green Line': '#388E3C',
      'Violet Line': '#7B1FA2',
      'Pink Line': '#E91E63',
      'Magenta Line': '#C2185B',
      'Gray Line': '#616161',
      'Aqua Line': '#00BCD4',
      'Airport Express': '#FF5722',
      'Rapid Metro': '#795548',
    };
    
    return lineColors[lineName] ?? '#1976D2';
  }
}

/// Station sequence information from GTFS
class StationSequence {
  final String stationId;
  final String stationName;
  final double latitude;
  final double longitude;
  final int sequence;
  final String lineName;

  StationSequence({
    required this.stationId,
    required this.stationName,
    required this.latitude,
    required this.longitude,
    required this.sequence,
    required this.lineName,
  });
}
