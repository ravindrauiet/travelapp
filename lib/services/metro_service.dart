import 'dart:math';
import '../models/metro_station.dart';
import '../models/metro_route.dart';

class MetroService {
  // Sample metro stations data for Delhi Metro
  static final List<MetroStation> _stations = [
    // Blue Line
    MetroStation(
      id: '1',
      name: 'Dwarka Sector 21',
      line: 'Blue Line',
      lineColor: '#1976D2',
      latitude: 28.5921,
      longitude: 77.0465,
      facilities: ['Parking', 'ATM', 'Food Court'],
    ),
    MetroStation(
      id: '2',
      name: 'Dwarka Sector 8',
      line: 'Blue Line',
      lineColor: '#1976D2',
      latitude: 28.5845,
      longitude: 77.0523,
      facilities: ['Parking', 'ATM'],
    ),
    MetroStation(
      id: '3',
      name: 'Dwarka Sector 9',
      line: 'Blue Line',
      lineColor: '#1976D2',
      latitude: 28.5769,
      longitude: 77.0581,
      facilities: ['Parking'],
    ),
    MetroStation(
      id: '4',
      name: 'Dwarka Sector 10',
      line: 'Blue Line',
      lineColor: '#1976D2',
      latitude: 28.5693,
      longitude: 77.0639,
      facilities: ['Parking', 'ATM'],
    ),
    MetroStation(
      id: '5',
      name: 'Dwarka Sector 11',
      line: 'Blue Line',
      lineColor: '#1976D2',
      latitude: 28.5617,
      longitude: 77.0697,
      facilities: ['Parking'],
    ),
    MetroStation(
      id: '6',
      name: 'Dwarka Sector 12',
      line: 'Blue Line',
      lineColor: '#1976D2',
      latitude: 28.5541,
      longitude: 77.0755,
      facilities: ['Parking', 'ATM', 'Food Court'],
    ),
    MetroStation(
      id: '7',
      name: 'Dwarka Sector 13',
      line: 'Blue Line',
      lineColor: '#1976D2',
      latitude: 28.5465,
      longitude: 77.0813,
      facilities: ['Parking'],
    ),
    MetroStation(
      id: '8',
      name: 'Dwarka Sector 14',
      line: 'Blue Line',
      lineColor: '#1976D2',
      latitude: 28.5389,
      longitude: 77.0871,
      facilities: ['Parking', 'ATM'],
    ),
    MetroStation(
      id: '9',
      name: 'Dwarka Sector 15',
      line: 'Blue Line',
      lineColor: '#1976D2',
      latitude: 28.5313,
      longitude: 77.0929,
      facilities: ['Parking'],
    ),
    MetroStation(
      id: '10',
      name: 'Dwarka Sector 16',
      line: 'Blue Line',
      lineColor: '#1976D2',
      latitude: 28.5237,
      longitude: 77.0987,
      facilities: ['Parking', 'ATM', 'Food Court'],
    ),
    MetroStation(
      id: '11',
      name: 'Dwarka Sector 17',
      line: 'Blue Line',
      lineColor: '#1976D2',
      latitude: 28.5161,
      longitude: 77.1045,
      facilities: ['Parking'],
    ),
    MetroStation(
      id: '12',
      name: 'Dwarka Sector 18',
      line: 'Blue Line',
      lineColor: '#1976D2',
      latitude: 28.5085,
      longitude: 77.1103,
      facilities: ['Parking', 'ATM'],
    ),
    MetroStation(
      id: '13',
      name: 'Dwarka Sector 19',
      line: 'Blue Line',
      lineColor: '#1976D2',
      latitude: 28.5009,
      longitude: 77.1161,
      facilities: ['Parking'],
    ),
    MetroStation(
      id: '14',
      name: 'Dwarka Sector 20',
      line: 'Blue Line',
      lineColor: '#1976D2',
      latitude: 28.4933,
      longitude: 77.1219,
      facilities: ['Parking', 'ATM', 'Food Court'],
    ),
    MetroStation(
      id: '15',
      name: 'Dwarka Sector 21',
      line: 'Blue Line',
      lineColor: '#1976D2',
      latitude: 28.4857,
      longitude: 77.1277,
      facilities: ['Parking'],
    ),
    MetroStation(
      id: '16',
      name: 'Dwarka Sector 22',
      line: 'Blue Line',
      lineColor: '#1976D2',
      latitude: 28.4781,
      longitude: 77.1335,
      facilities: ['Parking', 'ATM'],
    ),
    MetroStation(
      id: '17',
      name: 'Dwarka Sector 23',
      line: 'Blue Line',
      lineColor: '#1976D2',
      latitude: 28.4705,
      longitude: 77.1393,
      facilities: ['Parking'],
    ),
    MetroStation(
      id: '18',
      name: 'Dwarka Sector 24',
      line: 'Blue Line',
      lineColor: '#1976D2',
      latitude: 28.4629,
      longitude: 77.1451,
      facilities: ['Parking', 'ATM', 'Food Court'],
    ),
    MetroStation(
      id: '19',
      name: 'Dwarka Sector 25',
      line: 'Blue Line',
      lineColor: '#1976D2',
      latitude: 28.4553,
      longitude: 77.1509,
      facilities: ['Parking'],
    ),
    MetroStation(
      id: '20',
      name: 'Dwarka Sector 26',
      line: 'Blue Line',
      lineColor: '#1976D2',
      latitude: 28.4477,
      longitude: 77.1567,
      facilities: ['Parking', 'ATM'],
    ),
    // Red Line
    MetroStation(
      id: '21',
      name: 'Rithala',
      line: 'Red Line',
      lineColor: '#D32F2F',
      latitude: 28.7234,
      longitude: 77.1028,
      facilities: ['Parking', 'ATM'],
    ),
    MetroStation(
      id: '22',
      name: 'Rohini West',
      line: 'Red Line',
      lineColor: '#D32F2F',
      latitude: 28.7158,
      longitude: 77.1086,
      facilities: ['Parking'],
    ),
    MetroStation(
      id: '23',
      name: 'Rohini East',
      line: 'Red Line',
      lineColor: '#D32F2F',
      latitude: 28.7082,
      longitude: 77.1144,
      facilities: ['Parking', 'ATM'],
    ),
    MetroStation(
      id: '24',
      name: 'Pitampura',
      line: 'Red Line',
      lineColor: '#D32F2F',
      latitude: 28.7006,
      longitude: 77.1202,
      facilities: ['Parking'],
    ),
    MetroStation(
      id: '25',
      name: 'Kohat Enclave',
      line: 'Red Line',
      lineColor: '#D32F2F',
      latitude: 28.6930,
      longitude: 77.1260,
      facilities: ['Parking', 'ATM'],
    ),
    MetroStation(
      id: '26',
      name: 'Netaji Subhash Place',
      line: 'Red Line',
      lineColor: '#D32F2F',
      latitude: 28.6854,
      longitude: 77.1318,
      facilities: ['Parking', 'ATM', 'Food Court'],
    ),
    MetroStation(
      id: '27',
      name: 'Shastri Nagar',
      line: 'Red Line',
      lineColor: '#D32F2F',
      latitude: 28.6778,
      longitude: 77.1376,
      facilities: ['Parking'],
    ),
    MetroStation(
      id: '28',
      name: 'Pratap Nagar',
      line: 'Red Line',
      lineColor: '#D32F2F',
      latitude: 28.6702,
      longitude: 77.1434,
      facilities: ['Parking', 'ATM'],
    ),
    MetroStation(
      id: '29',
      name: 'Pulbangash',
      line: 'Red Line',
      lineColor: '#D32F2F',
      latitude: 28.6626,
      longitude: 77.1492,
      facilities: ['Parking'],
    ),
    MetroStation(
      id: '30',
      name: 'Tis Hazari',
      line: 'Red Line',
      lineColor: '#D32F2F',
      latitude: 28.6550,
      longitude: 77.1550,
      facilities: ['Parking', 'ATM'],
    ),
    MetroStation(
      id: '31',
      name: 'Kashmere Gate',
      line: 'Red Line',
      lineColor: '#D32F2F',
      latitude: 28.6474,
      longitude: 77.1608,
      facilities: ['Parking', 'ATM', 'Food Court'],
      isInterchange: true,
      interchangeLines: ['Yellow Line', 'Violet Line'],
    ),
    MetroStation(
      id: '32',
      name: 'Shastri Park',
      line: 'Red Line',
      lineColor: '#D32F2F',
      latitude: 28.6398,
      longitude: 77.1666,
      facilities: ['Parking'],
    ),
    MetroStation(
      id: '33',
      name: 'Seelampur',
      line: 'Red Line',
      lineColor: '#D32F2F',
      latitude: 28.6322,
      longitude: 77.1724,
      facilities: ['Parking', 'ATM'],
    ),
    MetroStation(
      id: '34',
      name: 'Welcome',
      line: 'Red Line',
      lineColor: '#D32F2F',
      latitude: 28.6246,
      longitude: 77.1782,
      facilities: ['Parking'],
    ),
    MetroStation(
      id: '35',
      name: 'Shahdara',
      line: 'Red Line',
      lineColor: '#D32F2F',
      latitude: 28.6170,
      longitude: 77.1840,
      facilities: ['Parking', 'ATM', 'Food Court'],
    ),
    MetroStation(
      id: '36',
      name: 'Dilshad Garden',
      line: 'Red Line',
      lineColor: '#D32F2F',
      latitude: 28.6094,
      longitude: 77.1898,
      facilities: ['Parking'],
    ),
    MetroStation(
      id: '37',
      name: 'Jhilmil',
      line: 'Red Line',
      lineColor: '#D32F2F',
      latitude: 28.6018,
      longitude: 77.1956,
      facilities: ['Parking', 'ATM'],
    ),
    MetroStation(
      id: '38',
      name: 'Mansarovar Park',
      line: 'Red Line',
      lineColor: '#D32F2F',
      latitude: 28.5942,
      longitude: 77.2014,
      facilities: ['Parking'],
    ),
    MetroStation(
      id: '39',
      name: 'Shiv Vihar',
      line: 'Red Line',
      lineColor: '#D32F2F',
      latitude: 28.5866,
      longitude: 77.2072,
      facilities: ['Parking', 'ATM'],
    ),
    // Yellow Line
    MetroStation(
      id: '40',
      name: 'Samaypur Badli',
      line: 'Yellow Line',
      lineColor: '#FFC107',
      latitude: 28.7234,
      longitude: 77.1028,
      facilities: ['Parking', 'ATM'],
    ),
    MetroStation(
      id: '41',
      name: 'Rohini Sector 18, 19',
      line: 'Yellow Line',
      lineColor: '#FFC107',
      latitude: 28.7158,
      longitude: 77.1086,
      facilities: ['Parking'],
    ),
    MetroStation(
      id: '42',
      name: 'Haiderpur Badli Mor',
      line: 'Yellow Line',
      lineColor: '#FFC107',
      latitude: 28.7082,
      longitude: 77.1144,
      facilities: ['Parking', 'ATM'],
    ),
    MetroStation(
      id: '43',
      name: 'Jahangirpuri',
      line: 'Yellow Line',
      lineColor: '#FFC107',
      latitude: 28.7006,
      longitude: 77.1202,
      facilities: ['Parking'],
    ),
    MetroStation(
      id: '44',
      name: 'Adarsh Nagar',
      line: 'Yellow Line',
      lineColor: '#FFC107',
      latitude: 28.6930,
      longitude: 77.1260,
      facilities: ['Parking', 'ATM'],
    ),
    MetroStation(
      id: '45',
      name: 'Azadpur',
      line: 'Yellow Line',
      lineColor: '#FFC107',
      latitude: 28.6854,
      longitude: 77.1318,
      facilities: ['Parking', 'ATM', 'Food Court'],
    ),
    MetroStation(
      id: '46',
      name: 'Model Town',
      line: 'Yellow Line',
      lineColor: '#FFC107',
      latitude: 28.6778,
      longitude: 77.1376,
      facilities: ['Parking'],
    ),
    MetroStation(
      id: '47',
      name: 'Guru Tegh Bahadur Nagar',
      line: 'Yellow Line',
      lineColor: '#FFC107',
      latitude: 28.6702,
      longitude: 77.1434,
      facilities: ['Parking', 'ATM'],
    ),
    MetroStation(
      id: '48',
      name: 'Vishwavidyalaya',
      line: 'Yellow Line',
      lineColor: '#FFC107',
      latitude: 28.6626,
      longitude: 77.1492,
      facilities: ['Parking'],
    ),
    MetroStation(
      id: '49',
      name: 'Vidhan Sabha',
      line: 'Yellow Line',
      lineColor: '#FFC107',
      latitude: 28.6550,
      longitude: 77.1550,
      facilities: ['Parking', 'ATM'],
    ),
    MetroStation(
      id: '50',
      name: 'Civil Lines',
      line: 'Yellow Line',
      lineColor: '#FFC107',
      latitude: 28.6474,
      longitude: 77.1608,
      facilities: ['Parking', 'ATM', 'Food Court'],
    ),
    MetroStation(
      id: '51',
      name: 'Kashmere Gate',
      line: 'Yellow Line',
      lineColor: '#FFC107',
      latitude: 28.6474,
      longitude: 77.1608,
      facilities: ['Parking', 'ATM', 'Food Court'],
      isInterchange: true,
      interchangeLines: ['Red Line', 'Violet Line'],
    ),
    MetroStation(
      id: '52',
      name: 'Chandni Chowk',
      line: 'Yellow Line',
      lineColor: '#FFC107',
      latitude: 28.6398,
      longitude: 77.1666,
      facilities: ['Parking'],
    ),
    MetroStation(
      id: '53',
      name: 'Chawri Bazar',
      line: 'Yellow Line',
      lineColor: '#FFC107',
      latitude: 28.6322,
      longitude: 77.1724,
      facilities: ['Parking', 'ATM'],
    ),
    MetroStation(
      id: '54',
      name: 'New Delhi',
      line: 'Yellow Line',
      lineColor: '#FFC107',
      latitude: 28.6246,
      longitude: 77.1782,
      facilities: ['Parking'],
    ),
    MetroStation(
      id: '55',
      name: 'Rajiv Chowk',
      line: 'Yellow Line',
      lineColor: '#FFC107',
      latitude: 28.6170,
      longitude: 77.1840,
      facilities: ['Parking', 'ATM', 'Food Court'],
      isInterchange: true,
      interchangeLines: ['Blue Line'],
    ),
    MetroStation(
      id: '56',
      name: 'Patel Chowk',
      line: 'Yellow Line',
      lineColor: '#FFC107',
      latitude: 28.6094,
      longitude: 77.1898,
      facilities: ['Parking'],
    ),
    MetroStation(
      id: '57',
      name: 'Central Secretariat',
      line: 'Yellow Line',
      lineColor: '#FFC107',
      latitude: 28.6018,
      longitude: 77.1956,
      facilities: ['Parking', 'ATM'],
    ),
    MetroStation(
      id: '58',
      name: 'Udyog Bhawan',
      line: 'Yellow Line',
      lineColor: '#FFC107',
      latitude: 28.5942,
      longitude: 77.2014,
      facilities: ['Parking'],
    ),
    MetroStation(
      id: '59',
      name: 'Lok Kalyan Marg',
      line: 'Yellow Line',
      lineColor: '#FFC107',
      latitude: 28.5866,
      longitude: 77.2072,
      facilities: ['Parking', 'ATM'],
    ),
    MetroStation(
      id: '60',
      name: 'Jor Bagh',
      line: 'Yellow Line',
      lineColor: '#FFC107',
      latitude: 28.5790,
      longitude: 77.2130,
      facilities: ['Parking'],
    ),
    MetroStation(
      id: '61',
      name: 'INA',
      line: 'Yellow Line',
      lineColor: '#FFC107',
      latitude: 28.5714,
      longitude: 77.2188,
      facilities: ['Parking', 'ATM', 'Food Court'],
    ),
    MetroStation(
      id: '62',
      name: 'AIIMS',
      line: 'Yellow Line',
      lineColor: '#FFC107',
      latitude: 28.5638,
      longitude: 77.2246,
      facilities: ['Parking'],
    ),
    MetroStation(
      id: '63',
      name: 'Green Park',
      line: 'Yellow Line',
      lineColor: '#FFC107',
      latitude: 28.5562,
      longitude: 77.2304,
      facilities: ['Parking', 'ATM'],
    ),
    MetroStation(
      id: '64',
      name: 'Hauz Khas',
      line: 'Yellow Line',
      lineColor: '#FFC107',
      latitude: 28.5486,
      longitude: 77.2362,
      facilities: ['Parking'],
    ),
    MetroStation(
      id: '65',
      name: 'Malviya Nagar',
      line: 'Yellow Line',
      lineColor: '#FFC107',
      latitude: 28.5410,
      longitude: 77.2420,
      facilities: ['Parking', 'ATM'],
    ),
    MetroStation(
      id: '66',
      name: 'Saket',
      line: 'Yellow Line',
      lineColor: '#FFC107',
      latitude: 28.5334,
      longitude: 77.2478,
      facilities: ['Parking'],
    ),
    MetroStation(
      id: '67',
      name: 'Qutab Minar',
      line: 'Yellow Line',
      lineColor: '#FFC107',
      latitude: 28.5258,
      longitude: 77.2536,
      facilities: ['Parking', 'ATM', 'Food Court'],
    ),
    MetroStation(
      id: '68',
      name: 'Chhatarpur',
      line: 'Yellow Line',
      lineColor: '#FFC107',
      latitude: 28.5182,
      longitude: 77.2594,
      facilities: ['Parking'],
    ),
    MetroStation(
      id: '69',
      name: 'Sultanpur',
      line: 'Yellow Line',
      lineColor: '#FFC107',
      latitude: 28.5106,
      longitude: 77.2652,
      facilities: ['Parking', 'ATM'],
    ),
    MetroStation(
      id: '70',
      name: 'Ghitorni',
      line: 'Yellow Line',
      lineColor: '#FFC107',
      latitude: 28.5030,
      longitude: 77.2710,
      facilities: ['Parking'],
    ),
    MetroStation(
      id: '71',
      name: 'Arjan Garh',
      line: 'Yellow Line',
      lineColor: '#FFC107',
      latitude: 28.4954,
      longitude: 77.2768,
      facilities: ['Parking', 'ATM'],
    ),
    MetroStation(
      id: '72',
      name: 'Gurgaon',
      line: 'Yellow Line',
      lineColor: '#FFC107',
      latitude: 28.4878,
      longitude: 77.2826,
      facilities: ['Parking'],
    ),
    MetroStation(
      id: '73',
      name: 'Sikanderpur',
      line: 'Yellow Line',
      lineColor: '#FFC107',
      latitude: 28.4802,
      longitude: 77.2884,
      facilities: ['Parking', 'ATM', 'Food Court'],
    ),
    MetroStation(
      id: '74',
      name: 'MG Road',
      line: 'Yellow Line',
      lineColor: '#FFC107',
      latitude: 28.4726,
      longitude: 77.2942,
      facilities: ['Parking'],
    ),
    MetroStation(
      id: '75',
      name: 'IFFCO Chowk',
      line: 'Yellow Line',
      lineColor: '#FFC107',
      latitude: 28.4650,
      longitude: 77.3000,
      facilities: ['Parking', 'ATM'],
    ),
    MetroStation(
      id: '76',
      name: 'Huda City Centre',
      line: 'Yellow Line',
      lineColor: '#FFC107',
      latitude: 28.4574,
      longitude: 77.3058,
      facilities: ['Parking'],
    ),
  ];

  Future<List<MetroStation>> getStations() async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));
    return _stations;
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

  Future<List<MetroRoute>> findRoute(String fromStation, String toStation) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Simple route finding logic
    final from = _stations.firstWhere((s) => s.name.toLowerCase().contains(fromStation.toLowerCase()));
    final to = _stations.firstWhere((s) => s.name.toLowerCase().contains(toStation.toLowerCase()));
    
    if (from.line == to.line) {
      // Same line
      return [
        MetroRoute(
          id: '1',
          fromStation: from.name,
          toStation: to.name,
          segments: [
            RouteSegment(
              line: from.line,
              lineColor: from.lineColor,
              fromStation: from.name,
              toStation: to.name,
              stationsCount: 5,
              timeMinutes: 15,
              fare: calculateFare(from.name, to.name) ?? 0.0,
            ),
          ],
          totalTime: 15,
          totalFare: calculateFare(from.name, to.name) ?? 0.0,
          totalStations: 5,
        ),
      ];
    } else {
      // Different lines - need interchange
      return [
        MetroRoute(
          id: '1',
          fromStation: from.name,
          toStation: to.name,
          segments: [
            RouteSegment(
              line: from.line,
              lineColor: from.lineColor,
              fromStation: from.name,
              toStation: 'Kashmere Gate',
              stationsCount: 3,
              timeMinutes: 10,
              fare: calculateFare(from.name, 'Kashmere Gate') ?? 0.0,
            ),
            RouteSegment(
              line: to.line,
              lineColor: to.lineColor,
              fromStation: 'Kashmere Gate',
              toStation: to.name,
              stationsCount: 4,
              timeMinutes: 12,
              fare: calculateFare('Kashmere Gate', to.name) ?? 0.0,
            ),
          ],
          totalTime: 25,
          totalFare: (calculateFare(from.name, 'Kashmere Gate') ?? 0.0) + (calculateFare('Kashmere Gate', to.name) ?? 0.0),
          totalStations: 7,
          interchangeStations: ['Kashmere Gate'],
        ),
      ];
    }
  }

  double? calculateFare(String fromStation, String toStation) {
    // Simple fare calculation based on distance
    final from = _stations.firstWhere((s) => s.name.toLowerCase().contains(fromStation.toLowerCase()));
    final to = _stations.firstWhere((s) => s.name.toLowerCase().contains(toStation.toLowerCase()));
    
    final distance = _calculateDistance(from.latitude, from.longitude, to.latitude, to.longitude);
    
    if (distance <= 2) return 10.0;
    if (distance <= 5) return 20.0;
    if (distance <= 12) return 30.0;
    if (distance <= 21) return 40.0;
    if (distance <= 32) return 50.0;
    return 60.0;
  }

  List<MetroStation> findNearestStations(double latitude, double longitude, {int limit = 5}) {
    final stationsWithDistance = _stations.map((station) {
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

