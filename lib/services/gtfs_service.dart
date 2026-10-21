import 'package:flutter/foundation.dart';

import '../models/gtfs_models.dart';
import 'bus_network_service.dart';
import 'live_bus_service.dart';

/// Legacy GTFS facade. Live positions are delegated to [LiveBusService], which
/// owns fetching, caching, isolate parsing and enrichment; use it directly for
/// route numbers, nearest/next stops and typed errors.
class GTFSService {
  // Cache for static data
  static List<GTFSAgency>? _agencies;
  static List<GTFSStop>? _stops;
  static List<GTFSRoute>? _routes;
  static List<GTFSTrip>? _trips;
  static List<GTFSStopTime>? _stopTimes;

  static DateTime? get lastRealTimeUpdate => LiveBusService.instance.lastSnapshot?.fetchedAt;
  static int get totalActiveBuses => LiveBusService.instance.lastSnapshot?.count ?? 0;

  /// Live vehicle positions from Delhi OTD (cached ~20 s, shared across screens).
  /// Never throws: on failure returns the last good positions, or an empty list.
  static Future<List<GTFSVehiclePosition>> getRealTimeVehiclePositions() async {
    try {
      final snap = await LiveBusService.instance.snapshot();
      return snap.vehicles;
    } on LiveBusException catch (e) {
      debugPrint('GTFSService: live feed error: $e');
      return LiveBusService.instance.lastSnapshot?.vehicles ?? [];
    }
  }

  /// Get vehicles near a specific location
  static Future<List<GTFSVehiclePosition>> getVehiclesNearLocation(
    double latitude,
    double longitude, {
    double radiusKm = 2.0,
  }) async {
    final vehicles = await getRealTimeVehiclePositions();
    return vehicles
        .where((v) => BusNetworkService.distanceKm(latitude, longitude, v.latitude, v.longitude) <= radiusKm)
        .toList();
  }

  /// Live vehicles on one route direction. [routeId] is the feed's `route_id`,
  /// which equals `BusLine.id` in the offline bus network.
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

  /// Whether live data was downloaded in the last 5 minutes.
  static bool isRealTimeDataFresh() {
    final last = lastRealTimeUpdate;
    if (last == null) return false;
    return DateTime.now().difference(last).inMinutes < 5;
  }

  /// Clear cache
  static void clearCache() {
    _agencies = null;
    _stops = null;
    _routes = null;
    _trips = null;
    _stopTimes = null;
  }
}
