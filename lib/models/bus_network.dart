/// Data types for the Delhi bus network built from the OTD static GTFS feed
/// (see tool/build_bus_network.mjs and assets/data/bus_network.json).
library;

class BusStopInfo {
  final int id;
  final String code;
  final String name;
  final double lat;
  final double lon;

  const BusStopInfo({
    required this.id,
    required this.code,
    required this.name,
    required this.lat,
    required this.lon,
  });
}

/// One direction of one bus route, with its full ordered stop pattern.
class BusLine {
  final int id;

  /// Passenger-facing route number, e.g. "764M", "CBD3(+)".
  final String number;

  /// Raw GTFS name, e.g. "764MSTLDOWN".
  final String longName;

  /// "UP", "DOWN" (sometimes with a variant digit) or empty.
  final String direction;

  /// "DTC" or "DIMTS" (cluster buses).
  final String agency;

  final List<int> stopIds;

  /// Minutes from the first stop to each stop (same length as [stopIds]).
  final List<int> offsets;

  /// First and last departure from the origin, in minutes after midnight.
  final int? firstDeparture;
  final int? lastDeparture;

  /// Number of scheduled trips per day.
  final int tripCount;

  const BusLine({
    required this.id,
    required this.number,
    required this.longName,
    required this.direction,
    required this.agency,
    required this.stopIds,
    required this.offsets,
    required this.firstDeparture,
    required this.lastDeparture,
    required this.tripCount,
  });

  bool get isDtc => agency == 'DTC';
  String get operatorName => isDtc ? 'DTC' : 'Cluster (DIMTS)';
  int get durationMinutes => offsets.isEmpty ? 0 : offsets.last;

  /// Average minutes between buses, or null if only one trip a day.
  int? get headwayMinutes {
    if (tripCount < 2 || firstDeparture == null || lastDeparture == null) return null;
    final span = lastDeparture! - firstDeparture!;
    if (span <= 0) return null;
    return (span / (tripCount - 1)).round().clamp(1, 240);
  }
}

/// A stop name (both sides of the road / all bays share one name) used for search.
class BusPlace {
  final String name;
  final List<BusStopInfo> stops;

  const BusPlace({required this.name, required this.stops});

  double get lat => stops.map((s) => s.lat).reduce((a, b) => a + b) / stops.length;
  double get lon => stops.map((s) => s.lon).reduce((a, b) => a + b) / stops.length;
}

/// A ride on one [BusLine] from stop index [fromIndex] to [toIndex].
class BusLeg {
  final BusLine line;
  final int fromIndex;
  final int toIndex;
  final List<BusStopInfo> stops; // inclusive of board & alight stops
  final double distanceKm;

  const BusLeg({
    required this.line,
    required this.fromIndex,
    required this.toIndex,
    required this.stops,
    required this.distanceKm,
  });

  BusStopInfo get boardStop => stops.first;
  BusStopInfo get alightStop => stops.last;
  int get rideMinutes => line.offsets[toIndex] - line.offsets[fromIndex];
  int get stopCount => toIndex - fromIndex;
}

class BusJourney {
  final List<BusLeg> legs;

  /// Estimated door-to-door minutes on the bus(es), including transfer & waiting.
  final int totalMinutes;

  /// Walk between legs at the transfer, in metres (0 if same stop).
  final int transferWalkMeters;

  const BusJourney({
    required this.legs,
    required this.totalMinutes,
    this.transferWalkMeters = 0,
  });

  bool get isDirect => legs.length == 1;
  int get transfers => legs.length - 1;
  double get distanceKm => legs.fold(0.0, (a, l) => a + l.distanceKm);
  int get totalStops => legs.fold(0, (a, l) => a + l.stopCount);

  /// Delhi DTC / cluster fare per ticket, by distance (2024 fare table).
  /// Non-AC: ₹5 up to 4 km, ₹10 up to 10 km, ₹15 beyond.
  /// AC: ₹10 up to 4 km, ₹15 up to 8 km, ₹20 up to 12 km, ₹25 beyond.
  /// Women travel free on DTC & cluster buses with a pink ticket.
  int get fareNonAc => legs.fold(0, (a, l) => a + BusFare.nonAc(l.distanceKm));
  int get fareAc => legs.fold(0, (a, l) => a + BusFare.ac(l.distanceKm));
}

class BusFare {
  static int nonAc(double km) => km <= 4 ? 5 : (km <= 10 ? 10 : 15);
  static int ac(double km) => km <= 4 ? 10 : (km <= 8 ? 15 : (km <= 12 ? 20 : 25));
}

/// Estimated arrival of a scheduled bus at a stop.
class BusArrival {
  final BusLine line;
  final int stopIndex;
  final DateTime time;

  const BusArrival({required this.line, required this.stopIndex, required this.time});

  int minutesFrom(DateTime now) => time.difference(now).inMinutes;
}
