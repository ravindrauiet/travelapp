import 'dart:math';
import '../models/metro_station.dart';
import '../models/metro_route.dart';
import 'metro_data_parser.dart';
import 'complete_gtfs_parser.dart';
import 'accurate_fare_calculator.dart';
import 'accurate_route_finder.dart';
import 'gtfs_route_finder.dart';
import 'improved_route_finder.dart';
import 'gtfs_graph_service.dart';

class MetroService {
  // Use GTFS data instead of hardcoded stations
  static List<MetroStation>? _stations;

  Future<List<MetroStation>> getStations() async {
    if (_stations != null) return _stations!;

    print('MetroService: Loading stations via GTFSGraphService…');
    try {
      _stations = await GTFSGraphService.getStations();
      if (_stations != null && _stations!.isNotEmpty) {
        print('MetroService: ${_stations!.length} stations loaded from GTFSGraphService');
        return _stations!;
      }
    } catch (e) {
      print('MetroService: GTFSGraphService station load failed: $e');
    }

    // Fallback 1: CompleteGTFSParser
    try {
      _stations = await CompleteGTFSParser.getAllStations();
      if (_stations != null && _stations!.isNotEmpty) {
        print('MetroService: ${_stations!.length} stations loaded from CompleteGTFSParser');
        return _stations!;
      }
    } catch (e) {
      print('MetroService: CompleteGTFSParser failed: $e');
    }

    // Fallback 2: JSON data
    try {
      _stations = await MetroDataParser.getAllStations();
      if (_stations != null && _stations!.isNotEmpty) {
        print('MetroService: ${_stations!.length} stations loaded from MetroDataParser');
        return _stations!;
      }
    } catch (e) {
      print('MetroService: MetroDataParser failed: $e');
    }

    print('MetroService: No station data available');
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

  /// Find optimal route between two stations.
  /// Primary: GTFSGraphService (correct graph + Dijkstra, total-distance fare).
  /// Fallback: ImprovedRouteFinder → GTFSRouteFinder → AccurateRouteFinder.
  Future<List<MetroRoute>> findRoute(String fromStation, String toStation) async {
    print('MetroService: finding route $fromStation → $toStation');

    // ── Primary: new correct graph-based finder ─────────────────────────────
    try {
      final routes = await GTFSGraphService.findRoute(
        fromName:   fromStation,
        toName:     toStation,
        travelTime: DateTime.now(),
        isSmartCard: true,
      );
      if (routes.isNotEmpty) {
        print('MetroService: GTFSGraphService returned ${routes.length} route(s)');
        return routes;
      }
    } catch (e) {
      print('MetroService: GTFSGraphService failed: $e');
    }

    // ── Fallback chain (legacy finders) ─────────────────────────────────────
    final stations = await getStations();

    try {
      final routes = await ImprovedRouteFinder.findRoute(
        fromStationName: fromStation,
        toStationName:   toStation,
        stations:        stations,
        travelTime:      DateTime.now(),
        isSmartCard:     true,
      );
      if (routes.isNotEmpty) return routes;
    } catch (e) {
      print('MetroService: ImprovedRouteFinder failed: $e');
    }

    try {
      final routes = await GTFSRouteFinder.findRoute(
        fromStationName: fromStation,
        toStationName:   toStation,
        stations:        stations,
        travelTime:      DateTime.now(),
        isSmartCard:     true,
      );
      if (routes.isNotEmpty) return routes;
    } catch (e) {
      print('MetroService: GTFSRouteFinder failed: $e');
    }

    return AccurateRouteFinder.findOptimalRoute(
      fromStationName: fromStation,
      toStationName:   toStation,
      stations:        stations,
      travelTime:      DateTime.now(),
      isSmartCard:     true,
    );
  }
  

  /// Calculate accurate fare between two stations using official DMRC rates
  Future<Map<String, dynamic>?> calculateFare(String fromStation, String toStation) async {
    if (_stations == null) {
      await getStations(); // This will load stations with fallback
    }
    
    if (_stations == null || _stations!.isEmpty) {
      print('No stations available for fare calculation');
      return null;
    }
    
    try {
      // More precise station matching - exact match first, then contains
      final from = _stations!.firstWhere(
        (s) => s.name.toLowerCase() == fromStation.toLowerCase() || 
               s.name.toLowerCase().contains(fromStation.toLowerCase()),
        orElse: () => throw Exception('From station not found: $fromStation')
      );
      final to = _stations!.firstWhere(
        (s) => s.name.toLowerCase() == toStation.toLowerCase() || 
               s.name.toLowerCase().contains(toStation.toLowerCase()),
        orElse: () => throw Exception('To station not found: $toStation')
      );
    
      // Calculate distance using accurate method
      final distance = AccurateFareCalculator.calculateDistance(
        from.latitude, from.longitude, 
        to.latitude, to.longitude
      );
      
      print('Fare Calculation Debug:');
      print('From: ${from.name} (${from.line}) - Lat: ${from.latitude}, Lon: ${from.longitude}');
      print('To: ${to.name} (${to.line}) - Lat: ${to.latitude}, Lon: ${to.longitude}');
      print('Distance: ${distance.toStringAsFixed(2)} km');
      
      // Use accurate fare calculator with official DMRC rates
      final fareResult = AccurateFareCalculator.calculateFareComparison(
        distance: distance,
        travelTime: DateTime.now(),
        isAirportExpress: from.line == 'Airport Express' || to.line == 'Airport Express',
      );
      
      print('Base Fare: ₹${fareResult.baseFare}');
      print('Ticket Fare: ₹${fareResult.ticketFare}');
      print('Smart Card Fare: ₹${fareResult.smartCardFare}');
      print('Smart Card Discount: ₹${fareResult.smartCardSavings.toStringAsFixed(2)}');
      print('Off-peak Discount: ₹${fareResult.offPeakSavings.toStringAsFixed(2)}');
      print('Total Savings: ₹${fareResult.totalSavings.toStringAsFixed(2)}');
      print('MPT: ${fareResult.mpt} minutes');
      print('Is Off-peak: ${fareResult.isOffPeak}');
      print('Is Holiday: ${fareResult.isHoliday}');
      
      return {
        'baseFare': fareResult.baseFare,
        'smartCardFare': fareResult.smartCardFare,
        'ticketFare': fareResult.ticketFare,
        'smartCardSavings': fareResult.smartCardSavings,
        'offPeakSavings': fareResult.offPeakSavings,
        'totalSavings': fareResult.totalSavings,
        'mpt': fareResult.mpt,
        'isOffPeak': fareResult.isOffPeak,
        'isHoliday': fareResult.isHoliday,
      };
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

