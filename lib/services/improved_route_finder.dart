import '../models/metro_station.dart';
import '../models/metro_route.dart';
import 'accurate_fare_calculator.dart';

/// Improved Route Finder that handles cross-line journeys properly
class ImprovedRouteFinder {
  // Known interchange stations in Delhi Metro
  static const Map<String, List<String>> interchangeStations = {
    'Rajiv Chowk': ['Blue Line', 'Yellow Line'],
    'Kashmere Gate': ['Red Line', 'Yellow Line'],
    'Central Secretariat': ['Yellow Line', 'Violet Line'],
    'Mandi House': ['Blue Line', 'Violet Line'],
    'Inderlok': ['Red Line', 'Green Line'],
    'Ashok Park Main': ['Green Line', 'Green Line Branch'],
    'Kirti Nagar': ['Blue Line', 'Green Line'],
    'Janakpuri West': ['Blue Line', 'Magenta Line'],
    'Botanical Garden': ['Blue Line', 'Magenta Line'],
    'Kalkaji Mandir': ['Violet Line', 'Magenta Line'],
    'Lajpat Nagar': ['Violet Line', 'Pink Line'],
    'Mayur Vihar Phase-1': ['Blue Line', 'Pink Line'],
    'Anand Vihar': ['Blue Line', 'Pink Line'],
    'Welcome': ['Red Line', 'Pink Line'],
    'Shiv Vihar': ['Pink Line', 'Red Line'],
    'Azadpur': ['Yellow Line', 'Pink Line'],
    'Netaji Subhash Place': ['Red Line', 'Pink Line'],
    'Rajouri Garden': ['Blue Line', 'Pink Line'],
    'Dhaula Kuan': ['Airport Express', 'Pink Line'],
    'Aerocity': ['Airport Express', 'Magenta Line'],
    'Gurgaon': ['Yellow Line', 'Rapid Metro'],
    'Sikanderpur': ['Yellow Line', 'Rapid Metro'],
    'Phase 1': ['Yellow Line', 'Rapid Metro'],
    'Phase 2': ['Yellow Line', 'Rapid Metro'],
    'Phase 3': ['Yellow Line', 'Rapid Metro'],
    'Vaishali': ['Blue Line', 'Aqua Line'],
    'Noida Sector 18': ['Blue Line', 'Aqua Line'],
    'Noida Sector 16': ['Blue Line', 'Aqua Line'],
    'Noida Sector 15': ['Blue Line', 'Aqua Line'],
    'Noida Sector 62': ['Blue Line', 'Aqua Line'],
    'Noida Sector 59': ['Blue Line', 'Aqua Line'],
    'Noida Sector 61': ['Blue Line', 'Aqua Line'],
    'Noida Sector 52': ['Blue Line', 'Aqua Line'],
    'Noida Sector 34': ['Blue Line', 'Aqua Line'],
    'Noida City Centre': ['Blue Line', 'Aqua Line'],
    'Noida Golf Course': ['Blue Line', 'Aqua Line'],
  };

  /// Find route between two stations
  static Future<List<MetroRoute>> findRoute({
    required String fromStationName,
    required String toStationName,
    required List<MetroStation> stations,
    required DateTime travelTime,
    required bool isSmartCard,
  }) async {
    print('ImprovedRouteFinder: Finding route from $fromStationName to $toStationName');
    
    // Find source and destination stations
    final fromStation = stations.firstWhere(
      (s) => s.name.toLowerCase().contains(fromStationName.toLowerCase()),
      orElse: () => throw Exception('From station not found: $fromStationName'),
    );
    
    final toStation = stations.firstWhere(
      (s) => s.name.toLowerCase().contains(toStationName.toLowerCase()),
      orElse: () => throw Exception('To station not found: $toStationName'),
    );
    
    print('ImprovedRouteFinder: From ${fromStation.name} (${fromStation.line}) to ${toStation.name} (${toStation.line})');
    
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
    print('ImprovedRouteFinder: Finding direct route on ${from.line}');
    
    // Get all stations on the same line
    final lineStations = allStations.where((s) => s.line == from.line).toList();
    
    // Find positions of from and to stations
    final fromIndex = lineStations.indexWhere((s) => s.id == from.id);
    final toIndex = lineStations.indexWhere((s) => s.id == to.id);
    
    if (fromIndex == -1 || toIndex == -1) {
      print('ImprovedRouteFinder: Station positions not found, using fallback');
      return _createFallbackRoute(from, to, travelTime, isSmartCard);
    }
    
    // Get stations between from and to
    final startIndex = fromIndex < toIndex ? fromIndex : toIndex;
    final endIndex = fromIndex < toIndex ? toIndex : fromIndex;
    final routeStations = lineStations.sublist(startIndex, endIndex + 1);
    
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
      totalTime += _getLineTravelTime(from.line, distance);
    }
    
    // Calculate fare
    final fareResult = AccurateFareCalculator.calculateFareComparison(
      distance: totalDistance,
      travelTime: travelTime,
      isAirportExpress: from.line == 'Airport Express',
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
        isAirportExpress: from.line == 'Airport Express',
      );
      
      segments.add(RouteSegment(
        line: from.line,
        lineColor: _getLineColor(from.line),
        fromStation: current.name,
        toStation: next.name,
        stationsCount: 1,
        timeMinutes: _getLineTravelTime(from.line, distance),
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
    
    print('ImprovedRouteFinder: Direct route found - ${routeStations.length} stations, ${totalDistance.toStringAsFixed(2)} km, $totalTime minutes');
    
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
    print('ImprovedRouteFinder: Finding route with interchanges from ${from.line} to ${to.line}');
    
    // Find interchange stations using the predefined list
    final possibleInterchanges = <MetroStation>[];
    
    for (final station in allStations) {
      if (station.isInterchange && station.interchangeLines.isNotEmpty) {
        // Check if this station connects the two lines we need
        final hasFromLine = station.interchangeLines.contains(from.line);
        final hasToLine = station.interchangeLines.contains(to.line);
        
        if (hasFromLine && hasToLine) {
          possibleInterchanges.add(station);
          print('ImprovedRouteFinder: Found interchange station: ${station.name} (${station.interchangeLines.join(', ')})');
        }
      }
    }
    
    // If no direct interchange found, try to find a multi-hop route
    if (possibleInterchanges.isEmpty) {
      print('ImprovedRouteFinder: No direct interchange found, trying multi-hop route');
      return _findMultiHopRoute(from, to, allStations, travelTime, isSmartCard);
    }
    
    // Use the first interchange station
    final interchange = possibleInterchanges.first;
    print('ImprovedRouteFinder: Using interchange station: ${interchange.name}');
    
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
    
    print('ImprovedRouteFinder: Interchange route found - $totalTime minutes, ₹${totalFare.toStringAsFixed(0)}');
    
    return [route];
  }

  /// Find multi-hop route when no direct interchange exists
  static List<MetroRoute> _findMultiHopRoute(
    MetroStation from,
    MetroStation to,
    List<MetroStation> allStations,
    DateTime travelTime,
    bool isSmartCard,
  ) {
    print('ImprovedRouteFinder: Finding multi-hop route from ${from.line} to ${to.line}');
    
    // For Red Line to Blue Line, we can use Kashmere Gate (Red->Yellow) then Rajiv Chowk (Yellow->Blue)
    if (from.line == 'Red Line' && to.line == 'Blue Line') {
      return _createMultiHopRoute(from, to, 'Kashmere Gate', 'Rajiv Chowk', allStations, travelTime, isSmartCard);
    }
    
    // For Blue Line to Red Line, reverse the route
    if (from.line == 'Blue Line' && to.line == 'Red Line') {
      return _createMultiHopRoute(from, to, 'Rajiv Chowk', 'Kashmere Gate', allStations, travelTime, isSmartCard);
    }
    
    // For other combinations, create a simple fallback route
    print('ImprovedRouteFinder: No multi-hop route found, creating fallback route');
    return _createFallbackRoute(from, to, travelTime, isSmartCard);
  }

  /// Create multi-hop route with two interchanges
  static List<MetroRoute> _createMultiHopRoute(
    MetroStation from,
    MetroStation to,
    String firstInterchange,
    String secondInterchange,
    List<MetroStation> allStations,
    DateTime travelTime,
    bool isSmartCard,
  ) {
    print('ImprovedRouteFinder: Creating multi-hop route via $firstInterchange and $secondInterchange');
    
    // Find the interchange stations
    final firstInterchangeStation = allStations.firstWhere(
      (s) => s.name.toLowerCase().contains(firstInterchange.toLowerCase()),
      orElse: () => throw Exception('First interchange station not found: $firstInterchange'),
    );
    
    final secondInterchangeStation = allStations.firstWhere(
      (s) => s.name.toLowerCase().contains(secondInterchange.toLowerCase()),
      orElse: () => throw Exception('Second interchange station not found: $secondInterchange'),
    );
    
    final segments = <RouteSegment>[];
    
    // First segment: from station to first interchange
    final firstDistance = AccurateFareCalculator.calculateDistance(
      from.latitude, from.longitude,
      firstInterchangeStation.latitude, firstInterchangeStation.longitude,
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
      toStation: firstInterchangeStation.name,
      stationsCount: 1,
      timeMinutes: _getLineTravelTime(from.line, firstDistance),
      fare: (isSmartCard ? firstFare.smartCardFare : firstFare.ticketFare).toDouble(),
    ));
    
    // Second segment: first interchange to second interchange
    final secondDistance = AccurateFareCalculator.calculateDistance(
      firstInterchangeStation.latitude, firstInterchangeStation.longitude,
      secondInterchangeStation.latitude, secondInterchangeStation.longitude,
    );
    
    final secondFare = AccurateFareCalculator.calculateFareComparison(
      distance: secondDistance,
      travelTime: travelTime,
      isAirportExpress: false, // Assuming not Airport Express for intermediate segments
    );
    
    // Find the line between the two interchanges (usually Yellow Line)
    final intermediateLine = firstInterchangeStation.interchangeLines
        .where((line) => secondInterchangeStation.interchangeLines.contains(line))
        .firstOrNull ?? 'Yellow Line';
    
    segments.add(RouteSegment(
      line: intermediateLine,
      lineColor: _getLineColor(intermediateLine),
      fromStation: firstInterchangeStation.name,
      toStation: secondInterchangeStation.name,
      stationsCount: 1,
      timeMinutes: _getLineTravelTime(intermediateLine, secondDistance),
      fare: (isSmartCard ? secondFare.smartCardFare : secondFare.ticketFare).toDouble(),
    ));
    
    // Third segment: second interchange to destination
    final thirdDistance = AccurateFareCalculator.calculateDistance(
      secondInterchangeStation.latitude, secondInterchangeStation.longitude,
      to.latitude, to.longitude,
    );
    
    final thirdFare = AccurateFareCalculator.calculateFareComparison(
      distance: thirdDistance,
      travelTime: travelTime,
      isAirportExpress: to.line == 'Airport Express',
    );
    
    segments.add(RouteSegment(
      line: to.line,
      lineColor: _getLineColor(to.line),
      fromStation: secondInterchangeStation.name,
      toStation: to.name,
      stationsCount: 1,
      timeMinutes: _getLineTravelTime(to.line, thirdDistance),
      fare: (isSmartCard ? thirdFare.smartCardFare : thirdFare.ticketFare).toDouble(),
    ));
    
    final totalTime = segments.fold(0, (sum, segment) => sum + segment.timeMinutes) + 10; // Add 10 minutes for two interchanges
    final totalFare = segments.fold(0.0, (sum, segment) => sum + segment.fare);
    
    final route = MetroRoute(
      id: 'multihop_${from.id}_${to.id}',
      fromStation: from.name,
      toStation: to.name,
      segments: segments,
      totalTime: totalTime,
      totalFare: totalFare,
      totalStations: 4,
      interchangeStations: [firstInterchangeStation.name, secondInterchangeStation.name],
    );
    
    print('ImprovedRouteFinder: Multi-hop route created - $totalTime minutes, ₹${totalFare.toStringAsFixed(0)}');
    
    return [route];
  }

  /// Create fallback route when proper route finding fails
  static List<MetroRoute> _createFallbackRoute(
    MetroStation from,
    MetroStation to,
    DateTime travelTime,
    bool isSmartCard,
  ) {
    final distance = AccurateFareCalculator.calculateDistance(
      from.latitude, from.longitude,
      to.latitude, to.longitude,
    );
    
    final fareResult = AccurateFareCalculator.calculateFareComparison(
      distance: distance,
      travelTime: travelTime,
      isAirportExpress: from.line == 'Airport Express' || to.line == 'Airport Express',
    );
    
    final segments = <RouteSegment>[];
    
    if (from.line == to.line) {
      // Direct route on same line
      segments.add(RouteSegment(
        line: from.line,
        lineColor: _getLineColor(from.line),
        fromStation: from.name,
        toStation: to.name,
        stationsCount: 1,
        timeMinutes: (distance * 2).round(),
        fare: (isSmartCard ? fareResult.smartCardFare : fareResult.ticketFare).toDouble(),
      ));
    } else {
      // Multi-line route (simplified)
      segments.add(RouteSegment(
        line: from.line,
        lineColor: _getLineColor(from.line),
        fromStation: from.name,
        toStation: 'Interchange',
        stationsCount: 1,
        timeMinutes: (distance * 1).round(),
        fare: (isSmartCard ? fareResult.smartCardFare : fareResult.ticketFare).toDouble() / 2,
      ));
      
      segments.add(RouteSegment(
        line: to.line,
        lineColor: _getLineColor(to.line),
        fromStation: 'Interchange',
        toStation: to.name,
        stationsCount: 1,
        timeMinutes: (distance * 1).round(),
        fare: (isSmartCard ? fareResult.smartCardFare : fareResult.ticketFare).toDouble() / 2,
      ));
    }
    
    final totalTime = segments.fold(0, (sum, segment) => sum + segment.timeMinutes);
    final totalFare = segments.fold(0.0, (sum, segment) => sum + segment.fare);
    
    final route = MetroRoute(
      id: 'fallback_${from.id}_${to.id}',
      fromStation: from.name,
      toStation: to.name,
      segments: segments,
      totalTime: totalTime,
      totalFare: totalFare,
      totalStations: from.line == to.line ? 2 : 3,
      interchangeStations: from.line == to.line ? [] : ['Interchange'],
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
