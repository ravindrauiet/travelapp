class MetroRoute {
  final String id;
  final String fromStation;
  final String toStation;
  final List<RouteSegment> segments;
  final int totalTime; // in minutes
  final double totalFare;
  final int totalStations;
  final List<String> interchangeStations;

  MetroRoute({
    required this.id,
    required this.fromStation,
    required this.toStation,
    required this.segments,
    required this.totalTime,
    required this.totalFare,
    required this.totalStations,
    this.interchangeStations = const [],
  });

  factory MetroRoute.fromJson(Map<String, dynamic> json) {
    return MetroRoute(
      id: json['id'] ?? '',
      fromStation: json['fromStation'] ?? '',
      toStation: json['toStation'] ?? '',
      segments: (json['segments'] as List<dynamic>?)
          ?.map((segment) => RouteSegment.fromJson(segment))
          .toList() ?? [],
      totalTime: json['totalTime'] ?? 0,
      totalFare: (json['totalFare'] ?? 0.0).toDouble(),
      totalStations: json['totalStations'] ?? 0,
      interchangeStations: List<String>.from(json['interchangeStations'] ?? []),
    );
  }
}

class RouteSegment {
  final String line;
  final String lineColor;
  final String fromStation;
  final String toStation;
  final int stationsCount;
  final int timeMinutes;
  final double fare;

  RouteSegment({
    required this.line,
    required this.lineColor,
    required this.fromStation,
    required this.toStation,
    required this.stationsCount,
    required this.timeMinutes,
    required this.fare,
  });

  factory RouteSegment.fromJson(Map<String, dynamic> json) {
    return RouteSegment(
      line: json['line'] ?? '',
      lineColor: json['lineColor'] ?? '#1976D2',
      fromStation: json['fromStation'] ?? '',
      toStation: json['toStation'] ?? '',
      stationsCount: json['stationsCount'] ?? 0,
      timeMinutes: json['timeMinutes'] ?? 0,
      fare: (json['fare'] ?? 0.0).toDouble(),
    );
  }
}

