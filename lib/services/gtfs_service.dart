import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart' as pbrt;
import '../models/gtfs_models.dart';
import '../utils/app_constants.dart';

class GTFSService {
  static const String _apiKey = AppConstants.otdApiKey;
  static const String _otdRealtimeUrl = AppConstants.otdRealtimeUrl;
  
  // Cache for static data
  static List<GTFSAgency>? _agencies;
  static List<GTFSStop>? _stops;
  static List<GTFSRoute>? _routes;
  static List<GTFSTrip>? _trips;
  static List<GTFSStopTime>? _stopTimes;
  
  // Cache for real-time data
  static List<GTFSVehiclePosition>? _vehiclePositions;
  static DateTime? _lastRealTimeUpdate;

  static DateTime? get lastRealTimeUpdate => _lastRealTimeUpdate;
  static int get totalActiveBuses => _vehiclePositions?.length ?? 0;

  /// Fetch real-time vehicle positions from Delhi Government OTD
  static Future<List<GTFSVehiclePosition>> getRealTimeVehiclePositions() async {
    final endpoint = '$_otdRealtimeUrl?key=$_apiKey';

    try {
      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Accept': 'application/octet-stream, application/x-protobuf',
          'User-Agent': 'Metromate/1.0',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final data = _parseProtobufResponse(response.bodyBytes);
        if (data.isNotEmpty) {
          _vehiclePositions = data;
          _lastRealTimeUpdate = DateTime.now();
          return data;
        }
      }
    } catch (e) {
      print('GTFSService: Live OTD fetch error: $e');
    }

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

  /// Get static GTFS agencies (DTC & DIMTS)
  static Future<List<GTFSAgency>> getAgencies() async {
    if (_agencies != null) return _agencies!;
    
    _agencies = [
      GTFSAgency(
        agencyId: 'DTC',
        agencyName: 'Delhi Transport Corporation',
        agencyUrl: 'https://dtc.delhi.gov.in',
        agencyTimezone: 'Asia/Kolkata',
        agencyLang: 'en',
        agencyPhone: '1800118181',
        agencyEmail: 'info@dtc.nic.in',
      ),
      GTFSAgency(
        agencyId: 'DIMTS',
        agencyName: 'Delhi Integrated Multi-Modal Transit System Ltd.',
        agencyUrl: 'https://www.dimts.in',
        agencyTimezone: 'Asia/Kolkata',
        agencyLang: 'en',
        agencyPhone: '011-43090100',
        agencyEmail: 'info@dimts.in',
      ),
    ];
    
    return _agencies!;
  }

  static Future<List<GTFSStop>> getStops() async {
    if (_stops != null) return _stops!;
    
    _stops = [
      GTFSStop(
        stopId: 'stop_kg',
        stopCode: 'ISBT-KG',
        stopName: 'ISBT Kashmere Gate',
        stopLat: 28.6674,
        stopLon: 77.2285,
        wheelchairBoarding: 1,
      ),
      GTFSStop(
        stopId: 'stop_cp',
        stopCode: 'CP-CENTRAL',
        stopName: 'Connaught Place',
        stopLat: 28.6315,
        stopLon: 77.2167,
        wheelchairBoarding: 1,
      ),
      GTFSStop(
        stopId: 'stop_ig',
        stopCode: 'IG-HEXAGON',
        stopName: 'India Gate',
        stopLat: 28.6129,
        stopLon: 77.2295,
        wheelchairBoarding: 1,
      ),
      GTFSStop(
        stopId: 'stop_rf',
        stopCode: 'RED-FORT',
        stopName: 'Red Fort (Lal Qila)',
        stopLat: 28.6562,
        stopLon: 77.2410,
        wheelchairBoarding: 1,
      ),
      GTFSStop(
        stopId: 'stop_aiims',
        stopCode: 'AIIMS-RING',
        stopName: 'AIIMS / Safdarjung Hospital',
        stopLat: 28.5672,
        stopLon: 77.2100,
        wheelchairBoarding: 1,
      ),
      GTFSStop(
        stopId: 'stop_ln',
        stopCode: 'LAJPAT-NAGAR',
        stopName: 'Lajpat Nagar',
        stopLat: 28.5675,
        stopLon: 77.2431,
        wheelchairBoarding: 1,
      ),
      GTFSStop(
        stopId: 'stop_np',
        stopCode: 'NEHRU-PLACE',
        stopName: 'Nehru Place Terminal',
        stopLat: 28.5492,
        stopLon: 77.2530,
        wheelchairBoarding: 1,
      ),
      GTFSStop(
        stopId: 'stop_kb',
        stopCode: 'KAROL-BAGH',
        stopName: 'Karol Bagh',
        stopLat: 28.6515,
        stopLon: 77.1908,
        wheelchairBoarding: 1,
      ),
      GTFSStop(
        stopId: 'stop_dk',
        stopCode: 'DHAULA-KUAN',
        stopName: 'Dhaula Kuan',
        stopLat: 28.5920,
        stopLon: 77.1610,
        wheelchairBoarding: 1,
      ),
    ];
    
    return _stops!;
  }

  static Future<List<GTFSRoute>> getRoutes() async {
    if (_routes != null) return _routes!;
    
    _routes = [
      GTFSRoute(
        routeId: 'dtc_505',
        agencyId: 'DTC',
        routeShortName: '505',
        routeLongName: 'Mehrauli ↔ New Delhi Railway Station',
        routeType: 3,
        routeColor: '16A34A',
        routeTextColor: 'FFFFFF',
      ),
      GTFSRoute(
        routeId: 'dtc_522',
        agencyId: 'DTC',
        routeShortName: '522',
        routeLongName: 'Inderpuri ↔ Lado Sarai Firni',
        routeType: 3,
        routeColor: '2563EB',
        routeTextColor: 'FFFFFF',
      ),
      GTFSRoute(
        routeId: 'dtc_185',
        agencyId: 'DTC',
        routeShortName: '185',
        routeLongName: 'Nathupura ↔ Kendriya Terminal',
        routeType: 3,
        routeColor: 'DC2626',
        routeTextColor: 'FFFFFF',
      ),
      GTFSRoute(
        routeId: 'dtc_534',
        agencyId: 'DTC',
        routeShortName: '534',
        routeLongName: 'Mehrauli ↔ Anand Vihar ISBT',
        routeType: 3,
        routeColor: '7C3AED',
        routeTextColor: 'FFFFFF',
      ),
      GTFSRoute(
        routeId: 'dtc_544',
        agencyId: 'DTC',
        routeShortName: '544',
        routeLongName: 'Badarpur Border ↔ R.K. Puram',
        routeType: 3,
        routeColor: 'EA580C',
        routeTextColor: 'FFFFFF',
      ),
      GTFSRoute(
        routeId: 'dtc_729',
        agencyId: 'DTC',
        routeShortName: '729',
        routeLongName: 'Kapashera Border ↔ Mori Gate Terminal',
        routeType: 3,
        routeColor: '0284C7',
        routeTextColor: 'FFFFFF',
      ),
      GTFSRoute(
        routeId: 'dtc_tms',
        agencyId: 'DTC',
        routeShortName: 'TMS',
        routeLongName: 'Teevra Mudrika Seva (Ring Road Express)',
        routeType: 3,
        routeColor: '10B981',
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

  /// Parse protobuf response from Delhi Government OTD
  static List<GTFSVehiclePosition> _parseProtobufResponse(List<int> bytes) {
    try {
      final feed = pbrt.FeedMessage.fromBuffer(bytes);
      final List<GTFSVehiclePosition> list = [];

      for (final entity in feed.entity) {
        if (!entity.hasVehicle()) continue;
        final v = entity.vehicle;
        final pos = v.hasPosition() ? v.position : null;
        if (pos == null) continue;

        String status = 'IN_TRANSIT';
        if (v.hasCurrentStatus()) {
          switch (v.currentStatus) {
            case pbrt.VehiclePosition_VehicleStopStatus.INCOMING_AT:
              status = 'INCOMING';
              break;
            case pbrt.VehiclePosition_VehicleStopStatus.STOPPED_AT:
              status = 'STOPPED';
              break;
            case pbrt.VehiclePosition_VehicleStopStatus.IN_TRANSIT_TO:
              status = 'IN_TRANSIT';
              break;
            default:
              status = 'IN_TRANSIT';
          }
        }

        final vehicleId = v.hasVehicle() && v.vehicle.hasId() ? v.vehicle.id : entity.id;
        final routeId = v.hasTrip() && v.trip.hasRouteId() ? v.trip.routeId : '';
        final tripId = v.hasTrip() && v.trip.hasTripId() ? v.trip.tripId : '';
        final directionId = v.hasTrip() && v.trip.hasDirectionId() ? v.trip.directionId : 0;
        final speedKmh = pos.hasSpeed() ? (pos.speed.toDouble() * 3.6) : 0.0;

        list.add(GTFSVehiclePosition(
          vehicleId: vehicleId,
          tripId: tripId,
          routeId: routeId,
          directionId: directionId,
          latitude: pos.latitude.toDouble(),
          longitude: pos.longitude.toDouble(),
          bearing: pos.hasBearing() ? pos.bearing.toDouble() : 0.0,
          speed: speedKmh,
          currentStatus: status,
          timestamp: v.hasTimestamp()
              ? (v.timestamp.toInt() * 1000)
              : DateTime.now().millisecondsSinceEpoch,
        ));
      }

      print('GTFSService: Successfully parsed ${list.length} live vehicles from Delhi OTD');
      return list;
    } catch (e) {
      print('GTFSService: Protobuf decoding error: $e');
      return [];
    }
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
