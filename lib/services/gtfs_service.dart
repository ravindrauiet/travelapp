import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import '../models/gtfs_models.dart';

class GTFSService {
  static const String _apiKey = '7brhWCYIy6TT0nCAXxWIvXoPCU56Lzox';
  static const String _baseUrl = 'https://api.delhi.gov.in';
  static const String _realtimeUrl = '$_baseUrl/api/realtime/VehiclePositions.pb';
  
  // Alternative endpoints for testing
  static const String _localBaseUrl = 'http://localhost:55161';
  static const String _localRealtimeUrl = '$_localBaseUrl/api/realtime/VehiclePositions.pb';
  
  // Cache for static data
  static List<GTFSAgency>? _agencies;
  static List<GTFSStop>? _stops;
  static List<GTFSRoute>? _routes;
  static List<GTFSTrip>? _trips;
  static List<GTFSStopTime>? _stopTimes;
  
  // Cache for real-time data
  static List<GTFSVehiclePosition>? _vehiclePositions;
  static DateTime? _lastRealTimeUpdate;

  /// Fetch real-time vehicle positions
  static Future<List<GTFSVehiclePosition>> getRealTimeVehiclePositions() async {
    // Try local endpoint first, then fallback to production
    final endpoints = [
      '$_localRealtimeUrl?key=$_apiKey',
      '$_realtimeUrl?key=$_apiKey',
    ];

    for (final endpoint in endpoints) {
      try {
        print('Trying endpoint: $endpoint');
        final response = await http.get(
          Uri.parse(endpoint),
          headers: {
            'Accept': 'application/x-protobuf, application/json',
            'User-Agent': 'DelhiTravelGuide/1.0',
          },
        ).timeout(const Duration(seconds: 10));

        print('Response status: ${response.statusCode}');
        print('Response headers: ${response.headers}');

        if (response.statusCode == 200) {
          // Try to parse as JSON first (in case it's not protobuf)
          try {
            final jsonData = json.decode(response.body);
            final data = _parseJsonResponse(jsonData);
            _vehiclePositions = data;
            _lastRealTimeUpdate = DateTime.now();
            print('Successfully parsed JSON response with ${data.length} vehicles');
            return data;
          } catch (jsonError) {
            print('JSON parsing failed, trying protobuf: $jsonError');
            // Parse protobuf response
            final data = _parseProtobufResponse(response.bodyBytes);
            _vehiclePositions = data;
            _lastRealTimeUpdate = DateTime.now();
            print('Successfully parsed protobuf response with ${data.length} vehicles');
            return data;
          }
        } else {
          print('HTTP error: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        print('Error with endpoint $endpoint: $e');
        continue;
      }
    }

    print('All endpoints failed, returning cached data or empty list');
    return _vehiclePositions ?? [];
  }

  /// Get vehicles near a specific location
  static Future<List<GTFSVehiclePosition>> getVehiclesNearLocation(
    double latitude,
    double longitude, {
    double radiusKm = 2.0,
  }) async {
    final vehicles = await getRealTimeVehiclePositions();
    
    return vehicles.where((vehicle) {
      final distance = _calculateDistance(
        latitude,
        longitude,
        vehicle.latitude,
        vehicle.longitude,
      );
      return distance <= radiusKm;
    }).toList();
  }

  /// Get vehicles for a specific route
  static Future<List<GTFSVehiclePosition>> getVehiclesForRoute(String routeId) async {
    final vehicles = await getRealTimeVehiclePositions();
    return vehicles.where((vehicle) => vehicle.routeId == routeId).toList();
  }

  /// Get next buses for a specific stop
  static Future<List<GTFSVehiclePosition>> getNextBusesForStop(String stopId) async {
    final vehicles = await getRealTimeVehiclePositions();
    final stopTimes = await getStopTimes();
    
    // Find trips that serve this stop
    final relevantTrips = stopTimes
        .where((st) => st.stopId == stopId)
        .map((st) => st.tripId)
        .toSet();
    
    return vehicles.where((vehicle) => relevantTrips.contains(vehicle.tripId)).toList();
  }

  /// Get static GTFS data from API
  static Future<List<GTFSAgency>> getAgencies() async {
    if (_agencies != null) return _agencies!;
    
    try {
      // Try to fetch from API first
      final response = await http.get(
        Uri.parse('$_localBaseUrl/gtfs/agency.txt'),
        headers: {
          'Accept': 'text/csv, text/plain',
          'User-Agent': 'DelhiTravelGuide/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final csvData = const CsvToListConverter().convert(response.body);
        if (csvData.isNotEmpty) {
          final headers = csvData[0].map((e) => e.toString()).toList();
          _agencies = csvData.skip(1).map((row) {
            final rowMap = <String, String>{};
            for (int i = 0; i < headers.length && i < row.length; i++) {
              rowMap[headers[i]] = row[i].toString();
            }
            return GTFSAgency.fromCsv(rowMap);
          }).toList();
          print('Successfully loaded ${_agencies!.length} agencies from API');
          return _agencies!;
        }
      }
    } catch (e) {
      print('Error fetching agencies from API: $e');
    }
    
    // Fallback to simulated data
    _agencies = [
      GTFSAgency(
        agencyId: 'DTC',
        agencyName: 'Delhi Transport Corporation',
        agencyUrl: 'https://dtc.nic.in',
        agencyTimezone: 'Asia/Kolkata',
        agencyLang: 'en',
        agencyPhone: '+91-11-2389-0000',
        agencyEmail: 'info@dtc.nic.in',
      ),
    ];
    
    return _agencies!;
  }

  static Future<List<GTFSStop>> getStops() async {
    if (_stops != null) return _stops!;
    
    try {
      // Try to fetch from API first
      final response = await http.get(
        Uri.parse('$_localBaseUrl/gtfs/stops.txt'),
        headers: {
          'Accept': 'text/csv, text/plain',
          'User-Agent': 'DelhiTravelGuide/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final csvData = const CsvToListConverter().convert(response.body);
        if (csvData.isNotEmpty) {
          final headers = csvData[0].map((e) => e.toString()).toList();
          _stops = csvData.skip(1).map((row) {
            final rowMap = <String, String>{};
            for (int i = 0; i < headers.length && i < row.length; i++) {
              rowMap[headers[i]] = row[i].toString();
            }
            return GTFSStop.fromCsv(rowMap);
          }).toList();
          print('Successfully loaded ${_stops!.length} stops from API');
          return _stops!;
        }
      }
    } catch (e) {
      print('Error fetching stops from API: $e');
    }
    
    // Fallback to simulated data
    _stops = [
      GTFSStop(
        stopId: 'stop_001',
        stopCode: '001',
        stopName: 'Connaught Place',
        stopLat: 28.6315,
        stopLon: 77.2167,
        wheelchairBoarding: 1,
      ),
      GTFSStop(
        stopId: 'stop_002',
        stopCode: '002',
        stopName: 'India Gate',
        stopLat: 28.6129,
        stopLon: 77.2295,
        wheelchairBoarding: 1,
      ),
      GTFSStop(
        stopId: 'stop_003',
        stopCode: '003',
        stopName: 'Red Fort',
        stopLat: 28.6562,
        stopLon: 77.2410,
        wheelchairBoarding: 0,
      ),
      GTFSStop(
        stopId: 'stop_004',
        stopCode: '004',
        stopName: 'Rajiv Chowk',
        stopLat: 28.6315,
        stopLon: 77.2167,
        wheelchairBoarding: 1,
      ),
      GTFSStop(
        stopId: 'stop_005',
        stopCode: '005',
        stopName: 'Dwarka Sector 21',
        stopLat: 28.5921,
        stopLon: 77.0465,
        wheelchairBoarding: 1,
      ),
    ];
    
    return _stops!;
  }

  static Future<List<GTFSRoute>> getRoutes() async {
    if (_routes != null) return _routes!;
    
    try {
      // Try to fetch from API first
      final response = await http.get(
        Uri.parse('$_localBaseUrl/gtfs/routes.txt'),
        headers: {
          'Accept': 'text/csv, text/plain',
          'User-Agent': 'DelhiTravelGuide/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final csvData = const CsvToListConverter().convert(response.body);
        if (csvData.isNotEmpty) {
          final headers = csvData[0].map((e) => e.toString()).toList();
          _routes = csvData.skip(1).map((row) {
            final rowMap = <String, String>{};
            for (int i = 0; i < headers.length && i < row.length; i++) {
              rowMap[headers[i]] = row[i].toString();
            }
            return GTFSRoute.fromCsv(rowMap);
          }).toList();
          print('Successfully loaded ${_routes!.length} routes from API');
          return _routes!;
        }
      }
    } catch (e) {
      print('Error fetching routes from API: $e');
    }
    
    // Fallback to simulated data
    _routes = [
      GTFSRoute(
        routeId: 'route_001',
        agencyId: 'DTC',
        routeShortName: '1',
        routeLongName: 'Red Fort - Connaught Place',
        routeType: 3, // Bus
        routeColor: 'FF0000',
        routeTextColor: 'FFFFFF',
      ),
      GTFSRoute(
        routeId: 'route_002',
        agencyId: 'DTC',
        routeShortName: '2',
        routeLongName: 'India Gate - CP',
        routeType: 3, // Bus
        routeColor: '00FF00',
        routeTextColor: '000000',
      ),
      GTFSRoute(
        routeId: 'route_003',
        agencyId: 'DTC',
        routeShortName: '3',
        routeLongName: 'Dwarka - CP',
        routeType: 3, // Bus
        routeColor: '0000FF',
        routeTextColor: 'FFFFFF',
      ),
    ];
    
    return _routes!;
  }

  static Future<List<GTFSTrip>> getTrips() async {
    if (_trips != null) return _trips!;
    
    // Simulated data - in real implementation, fetch from trips.txt
    _trips = [
      GTFSTrip(
        routeId: 'route_001',
        serviceId: 'weekday',
        tripId: 'trip_001_1',
        tripHeadsign: 'Connaught Place',
        directionId: 0,
      ),
      GTFSTrip(
        routeId: 'route_001',
        serviceId: 'weekday',
        tripId: 'trip_001_2',
        tripHeadsign: 'Red Fort',
        directionId: 1,
      ),
    ];
    
    return _trips!;
  }

  static Future<List<GTFSStopTime>> getStopTimes() async {
    if (_stopTimes != null) return _stopTimes!;
    
    // Simulated data - in real implementation, fetch from stop_times.txt
    _stopTimes = [
      GTFSStopTime(
        tripId: 'trip_001_1',
        arrivalTime: '08:00:00',
        departureTime: '08:00:00',
        stopId: 'stop_003',
        stopSequence: 1,
      ),
      GTFSStopTime(
        tripId: 'trip_001_1',
        arrivalTime: '08:15:00',
        departureTime: '08:15:00',
        stopId: 'stop_004',
        stopSequence: 2,
      ),
    ];
    
    return _stopTimes!;
  }

  /// Parse JSON response from API
  static List<GTFSVehiclePosition> _parseJsonResponse(Map<String, dynamic> jsonData) {
    final entities = jsonData['entity'] as List<dynamic>? ?? [];
    final vehicles = <GTFSVehiclePosition>[];
    
    for (final entity in entities) {
      try {
        final vehicleData = entity['vehicle'];
        if (vehicleData != null) {
          final position = vehicleData['position'];
          final trip = vehicleData['trip'];
          
          if (position != null && trip != null) {
            vehicles.add(GTFSVehiclePosition(
              vehicleId: vehicleData['vehicle']['id'] ?? 'unknown',
              tripId: trip['trip_id'] ?? 'unknown',
              routeId: trip['route_id'] ?? 'unknown',
              directionId: trip['direction_id'],
              latitude: (position['latitude'] as num?)?.toDouble() ?? 0.0,
              longitude: (position['longitude'] as num?)?.toDouble() ?? 0.0,
              bearing: (position['bearing'] as num?)?.toDouble(),
              odometer: (position['odometer'] as num?)?.toDouble(),
              speed: (position['speed'] as num?)?.toDouble(),
              currentStatus: vehicleData['current_status'],
              congestionLevel: vehicleData['congestion_level'],
              occupancyStatus: vehicleData['occupancy_status'],
              timestamp: (vehicleData['timestamp'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
            ));
          }
        }
      } catch (e) {
        print('Error parsing vehicle entity: $e');
        continue;
      }
    }
    
    return vehicles;
  }

  /// Parse protobuf response (simplified implementation)
  static List<GTFSVehiclePosition> _parseProtobufResponse(List<int> bytes) {
    // This is a simplified implementation
    // In a real app, you'd use the protobuf library to parse the actual protobuf format
    
    // For demo purposes, return some simulated real-time data
    final now = DateTime.now();
    return [
      GTFSVehiclePosition(
        vehicleId: 'bus_001',
        tripId: 'trip_001_1',
        routeId: 'route_001',
        directionId: 0,
        latitude: 28.6315 + (0.001 * (now.second % 10)),
        longitude: 77.2167 + (0.001 * (now.second % 10)),
        bearing: 45.0,
        speed: 25.0,
        currentStatus: 'IN_TRANSIT', // In transit
        timestamp: now.millisecondsSinceEpoch,
      ),
      GTFSVehiclePosition(
        vehicleId: 'bus_002',
        tripId: 'trip_002_1',
        routeId: 'route_002',
        directionId: 0,
        latitude: 28.6129 + (0.001 * (now.second % 10)),
        longitude: 77.2295 + (0.001 * (now.second % 10)),
        bearing: 90.0,
        speed: 30.0,
        currentStatus: 'IN_TRANSIT', // In transit
        timestamp: now.millisecondsSinceEpoch,
      ),
    ];
  }

  /// Calculate distance between two coordinates
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

  /// Get real-time data freshness
  static bool isRealTimeDataFresh() {
    if (_lastRealTimeUpdate == null) return false;
    return DateTime.now().difference(_lastRealTimeUpdate!).inMinutes < 5;
  }

  /// Clear cache
  static void clearCache() {
    _agencies = null;
    _stops = null;
    _routes = null;
    _trips = null;
    _stopTimes = null;
    _vehiclePositions = null;
    _lastRealTimeUpdate = null;
  }
}
