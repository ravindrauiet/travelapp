class MetroRoute {
  final String id;
  final String fromStation;
  final String toStation;
  final List<RouteSegment> segments;
  final int totalTime; // in minutes
  final double totalFare;
  final int totalStations;
  final List<String> interchangeStations;

  /// Track distance of the journey in km (0 when unknown).
  final double distanceKm;

  /// Fare with a DMRC Smart Card at [travel time] (null when unknown).
  /// [totalFare] is always the token / QR ticket fare.
  final double? smartCardFare;

  /// One entry per ticket needed (Airport Express, Aqua Line and Rapid Metro
  /// are separate fare systems from the DMRC network).
  final List<FareLeg> fareLegs;

  MetroRoute({
    required this.id,
    required this.fromStation,
    required this.toStation,
    required this.segments,
    required this.totalTime,
    required this.totalFare,
    required this.totalStations,
    this.interchangeStations = const [],
    this.distanceKm = 0,
    this.smartCardFare,
    this.fareLegs = const [],
  });

  /// True when the fare includes a system whose tariff is an estimate.
  bool get fareIsApproximate => fareLegs.any((l) => l.system != FareSystem.dmrc);

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
  final List<String> intermediateStations; // List of all station names in this segment

  RouteSegment({
    required this.line,
    required this.lineColor,
    required this.fromStation,
    required this.toStation,
    required this.stationsCount,
    required this.timeMinutes,
    required this.fare,
    this.intermediateStations = const [],
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
      intermediateStations: List<String>.from(json['intermediateStations'] ?? []),
    );
  }
}


/// Separate ticketing systems on the Delhi NCR metro network.
enum FareSystem { dmrc, airportExpress, nmrc, rapidMetro }

extension FareSystemLabel on FareSystem {
  String get label {
    switch (this) {
      case FareSystem.dmrc:
        return 'DMRC';
      case FareSystem.airportExpress:
        return 'Airport Express';
      case FareSystem.nmrc:
        return 'Aqua Line (NMRC)';
      case FareSystem.rapidMetro:
        return 'Rapid Metro';
    }
  }
}

/// One ticket of a journey (consecutive legs on the same fare system).
class FareLeg {
  final FareSystem system;
  final String fromStation;
  final String toStation;
  final double distanceKm;
  final int tokenFare;
  final int smartCardFare;

  const FareLeg({
    required this.system,
    required this.fromStation,
    required this.toStation,
    required this.distanceKm,
    required this.tokenFare,
    required this.smartCardFare,
  });
}
