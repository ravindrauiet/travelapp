class BusStation {
  final String id;
  final String name;
  final String code;
  final double latitude;
  final double longitude;
  final List<String> busNumbers;
  final List<String> facilities;
  final bool isTerminal;

  BusStation({
    required this.id,
    required this.name,
    required this.code,
    required this.latitude,
    required this.longitude,
    this.busNumbers = const [],
    this.facilities = const [],
    this.isTerminal = false,
  });

  factory BusStation.fromJson(Map<String, dynamic> json) {
    return BusStation(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      busNumbers: List<String>.from(json['busNumbers'] ?? []),
      facilities: List<String>.from(json['facilities'] ?? []),
      isTerminal: json['isTerminal'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'latitude': latitude,
      'longitude': longitude,
      'busNumbers': busNumbers,
      'facilities': facilities,
      'isTerminal': isTerminal,
    };
  }
}


class BusTiming {
  final String id;
  final String busNumber;
  final String stationId;
  final String stationName;
  final DateTime expectedArrival;
  final String status; // 'on_time', 'delayed', 'arrived'
  final int delayMinutes;

  BusTiming({
    required this.id,
    required this.busNumber,
    required this.stationId,
    required this.stationName,
    required this.expectedArrival,
    required this.status,
    this.delayMinutes = 0,
  });

  factory BusTiming.fromJson(Map<String, dynamic> json) {
    return BusTiming(
      id: json['id'] ?? '',
      busNumber: json['busNumber'] ?? '',
      stationId: json['stationId'] ?? '',
      stationName: json['stationName'] ?? '',
      expectedArrival: DateTime.parse(json['expectedArrival'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'on_time',
      delayMinutes: json['delayMinutes'] ?? 0,
    );
  }
}
