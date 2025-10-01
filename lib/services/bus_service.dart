import 'dart:math';
import '../models/bus_station.dart';
import '../models/bus_route.dart';

class BusService {
  // Sample bus stations data for Delhi
  static final List<BusStation> _stations = [
    BusStation(
      id: '1',
      name: 'ISBT Kashmere Gate',
      code: 'ISBT-KG',
      latitude: 28.6474,
      longitude: 77.1608,
      busNumbers: ['101', '102', '103', '104', '105'],
      facilities: ['Parking', 'ATM', 'Food Court', 'Waiting Room'],
      isTerminal: true,
    ),
    BusStation(
      id: '2',
      name: 'Connaught Place',
      code: 'CP',
      latitude: 28.6315,
      longitude: 77.2167,
      busNumbers: ['201', '202', '203', '204', '205'],
      facilities: ['ATM', 'Food Court'],
    ),
    BusStation(
      id: '3',
      name: 'India Gate',
      code: 'IG',
      latitude: 28.6129,
      longitude: 77.2295,
      busNumbers: ['301', '302', '303'],
      facilities: ['Parking'],
    ),
    BusStation(
      id: '4',
      name: 'Red Fort',
      code: 'RF',
      latitude: 28.6562,
      longitude: 77.2410,
      busNumbers: ['401', '402', '403'],
      facilities: ['Parking', 'ATM'],
    ),
    BusStation(
      id: '5',
      name: 'Jama Masjid',
      code: 'JM',
      latitude: 28.6508,
      longitude: 77.2334,
      busNumbers: ['501', '502'],
      facilities: ['Parking'],
    ),
    BusStation(
      id: '6',
      name: 'Lal Qila',
      code: 'LQ',
      latitude: 28.6562,
      longitude: 77.2410,
      busNumbers: ['601', '602', '603'],
      facilities: ['Parking', 'ATM'],
    ),
    BusStation(
      id: '7',
      name: 'Chandni Chowk',
      code: 'CC',
      latitude: 28.6508,
      longitude: 77.2334,
      busNumbers: ['701', '702', '703', '704'],
      facilities: ['ATM', 'Food Court'],
    ),
    BusStation(
      id: '8',
      name: 'Rajiv Chowk',
      code: 'RC',
      latitude: 28.6315,
      longitude: 77.2167,
      busNumbers: ['801', '802', '803'],
      facilities: ['ATM', 'Food Court'],
    ),
    BusStation(
      id: '9',
      name: 'Karol Bagh',
      code: 'KB',
      latitude: 28.6515,
      longitude: 77.1908,
      busNumbers: ['901', '902', '903'],
      facilities: ['Parking', 'ATM'],
    ),
    BusStation(
      id: '10',
      name: 'Lajpat Nagar',
      code: 'LN',
      latitude: 28.5675,
      longitude: 77.2431,
      busNumbers: ['1001', '1002', '1003'],
      facilities: ['Parking', 'ATM', 'Food Court'],
    ),
    BusStation(
      id: '11',
      name: 'Hauz Khas',
      code: 'HK',
      latitude: 28.5486,
      longitude: 77.2362,
      busNumbers: ['1101', '1102', '1103'],
      facilities: ['Parking', 'ATM'],
    ),
    BusStation(
      id: '12',
      name: 'Saket',
      code: 'SK',
      latitude: 28.5334,
      longitude: 77.2478,
      busNumbers: ['1201', '1202', '1203'],
      facilities: ['Parking', 'ATM', 'Food Court'],
    ),
    BusStation(
      id: '13',
      name: 'Dwarka Sector 21',
      code: 'DW21',
      latitude: 28.5921,
      longitude: 77.0465,
      busNumbers: ['1301', '1302', '1303'],
      facilities: ['Parking', 'ATM'],
    ),
    BusStation(
      id: '14',
      name: 'Rohini Sector 18',
      code: 'RS18',
      latitude: 28.7158,
      longitude: 77.1086,
      busNumbers: ['1401', '1402', '1403'],
      facilities: ['Parking', 'ATM'],
    ),
    BusStation(
      id: '15',
      name: 'Noida Sector 18',
      code: 'NS18',
      latitude: 28.5700,
      longitude: 77.3200,
      busNumbers: ['1501', '1502', '1503'],
      facilities: ['Parking', 'ATM', 'Food Court'],
    ),
  ];

  Future<List<BusStation>> getStations() async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));
    return _stations;
  }

  Future<List<BusTiming>> getLiveTimings() async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));
    
    final now = DateTime.now();
    return [
      BusTiming(
        id: '1',
        busNumber: '101',
        stationId: '1',
        stationName: 'ISBT Kashmere Gate',
        expectedArrival: now.add(const Duration(minutes: 5)),
        status: 'on_time',
      ),
      BusTiming(
        id: '2',
        busNumber: '102',
        stationId: '1',
        stationName: 'ISBT Kashmere Gate',
        expectedArrival: now.add(const Duration(minutes: 12)),
        status: 'delayed',
        delayMinutes: 3,
      ),
      BusTiming(
        id: '3',
        busNumber: '201',
        stationId: '2',
        stationName: 'Connaught Place',
        expectedArrival: now.add(const Duration(minutes: 8)),
        status: 'on_time',
      ),
      BusTiming(
        id: '4',
        busNumber: '301',
        stationId: '3',
        stationName: 'India Gate',
        expectedArrival: now.add(const Duration(minutes: 15)),
        status: 'delayed',
        delayMinutes: 5,
      ),
    ];
  }

  Future<List<BusRoute>> findRoute(String fromLocation, String toLocation) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Simple route finding logic
    final from = _stations.firstWhere(
      (s) => s.name.toLowerCase().contains(fromLocation.toLowerCase()) ||
             s.code.toLowerCase().contains(fromLocation.toLowerCase()),
      orElse: () => _stations.first,
    );
    
    final to = _stations.firstWhere(
      (s) => s.name.toLowerCase().contains(toLocation.toLowerCase()) ||
             s.code.toLowerCase().contains(toLocation.toLowerCase()),
      orElse: () => _stations.last,
    );
    
    // Generate sample routes
    return [
      BusRoute(
        id: '1',
        number: '101',
        name: 'Route 101',
        fromLocation: from.name,
        toLocation: to.name,
        stops: _generateStops(from.name, to.name),
        totalTime: 25,
        totalDistance: 8.5,
        frequency: 'Every 10 minutes',
        operatingHours: '05:00-23:00',
        firstBus: '05:00',
        lastBus: '23:00',
        fare: 15.0,
      ),
      BusRoute(
        id: '2',
        number: '102',
        name: 'Route 102',
        fromLocation: from.name,
        toLocation: to.name,
        stops: _generateStops(from.name, to.name),
        totalTime: 30,
        totalDistance: 9.2,
        frequency: 'Every 15 minutes',
        operatingHours: '05:30-22:30',
        firstBus: '05:30',
        lastBus: '22:30',
        fare: 12.0,
      ),
    ];
  }

  List<BusStation> findNearestStations(double latitude, double longitude, {int limit = 5}) {
    final stationsWithDistance = _stations.map((station) {
      final distance = _calculateDistance(latitude, longitude, station.latitude, station.longitude);
      return MapEntry(station, distance);
    }).toList();
    
    stationsWithDistance.sort((a, b) => a.value.compareTo(b.value));
    
    return stationsWithDistance.take(limit).map((entry) => entry.key).toList();
  }

  List<BusStop> _generateStops(String from, String to) {
    final allStops = _stations.map((s) => s.name).toList();
    final fromIndex = allStops.indexOf(from);
    final toIndex = allStops.indexOf(to);
    
    if (fromIndex == -1 || toIndex == -1) {
      return [
        BusStop(id: 'from', name: from, latitude: 28.6139, longitude: 77.2090),
        BusStop(id: 'to', name: to, latitude: 28.6139, longitude: 77.2090),
      ];
    }
    
    final start = min(fromIndex, toIndex);
    final end = max(fromIndex, toIndex);
    
    return _stations.sublist(start, end + 1).map((station) => 
      BusStop(
        id: station.id,
        name: station.name,
        latitude: station.latitude,
        longitude: station.longitude,
      )
    ).toList();
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

