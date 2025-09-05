class BusRoute {
  final String id;
  final String busNumber;
  final String fromLocation;
  final String toLocation;
  final List<String> stops;
  final int totalTime; // in minutes
  final double totalDistance; // in km
  final String frequency; // e.g., "Every 10 minutes"
  final String firstBus;
  final String lastBus;
  final double fare;

  BusRoute({
    required this.id,
    required this.busNumber,
    required this.fromLocation,
    required this.toLocation,
    required this.stops,
    required this.totalTime,
    required this.totalDistance,
    required this.frequency,
    required this.firstBus,
    required this.lastBus,
    required this.fare,
  });

  factory BusRoute.fromJson(Map<String, dynamic> json) {
    return BusRoute(
      id: json['id'] ?? '',
      busNumber: json['busNumber'] ?? '',
      fromLocation: json['fromLocation'] ?? '',
      toLocation: json['toLocation'] ?? '',
      stops: List<String>.from(json['stops'] ?? []),
      totalTime: json['totalTime'] ?? 0,
      totalDistance: (json['totalDistance'] ?? 0.0).toDouble(),
      frequency: json['frequency'] ?? '',
      firstBus: json['firstBus'] ?? '',
      lastBus: json['lastBus'] ?? '',
      fare: (json['fare'] ?? 0.0).toDouble(),
    );
  }
}

