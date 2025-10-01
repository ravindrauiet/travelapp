class BusRoute {
  final String id;
  final String number;
  final String name;
  final List<BusStop> stops;
  final String frequency;
  final String operatingHours;
  final String fromLocation;
  final String toLocation;
  final double totalDistance;
  final int totalTime;
  final double fare;
  final String firstBus;
  final String lastBus;

  const BusRoute({
    required this.id,
    required this.number,
    required this.name,
    required this.stops,
    required this.frequency,
    required this.operatingHours,
    required this.fromLocation,
    required this.toLocation,
    required this.totalDistance,
    required this.totalTime,
    required this.fare,
    required this.firstBus,
    required this.lastBus,
  });

  // Getter for backward compatibility
  String get busNumber => number;

  factory BusRoute.fromJson(Map<String, dynamic> json) {
    return BusRoute(
      id: json['id'] as String,
      number: json['number'] as String,
      name: json['name'] as String,
      stops: (json['stops'] as List)
          .map((stopJson) => BusStop.fromJson(stopJson))
          .toList(),
      frequency: json['frequency'] as String,
      operatingHours: json['operating_hours'] as String,
      fromLocation: json['from_location'] as String? ?? 'Unknown',
      toLocation: json['to_location'] as String? ?? 'Unknown',
      totalDistance: (json['total_distance'] as num?)?.toDouble() ?? 0.0,
      totalTime: json['total_time'] as int? ?? 0,
      fare: (json['fare'] as num?)?.toDouble() ?? 0.0,
      firstBus: json['first_bus'] as String? ?? '05:00',
      lastBus: json['last_bus'] as String? ?? '23:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'name': name,
      'stops': stops.map((stop) => stop.toJson()).toList(),
      'frequency': frequency,
      'operating_hours': operatingHours,
      'from_location': fromLocation,
      'to_location': toLocation,
      'total_distance': totalDistance,
      'total_time': totalTime,
      'fare': fare,
      'first_bus': firstBus,
      'last_bus': lastBus,
    };
  }
}

class BusStop {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  const BusStop({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  factory BusStop.fromJson(Map<String, dynamic> json) {
    return BusStop(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lng'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lat': latitude,
      'lng': longitude,
    };
  }
}